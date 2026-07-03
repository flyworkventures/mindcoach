import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mindcoach/core/utils/app_constants.dart';

/// Premium satın alma onayı ve backend senkronizasyonu
class PremiumApiService {
  static const String _endpoint = '/api/v1/premium/confirm-purchase';

  /// Backend'e device + (varsa) user ile premium initialize/sync isteği at.
  /// Backend account-aware: userId verilirse user-scoped, yoksa device-scoped çalışır.
  Future<Map<String, dynamic>> initialize({
    required String deviceId,
    int? userId,
  }) async {
    final url = Uri.parse(
      '${AppConstants.baseURL}/api/v1/premium/initialize',
    );
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceId': deviceId,
            if (userId != null) 'userId': userId,
          }),
        )
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Premium initialize timeout');
          },
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Premium initialize failed: ${response.statusCode} - ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// RevenueCat'ten satın almanın onayını backend'e ilet
  ///
  /// Parametreler:
  /// - [deviceId]: Cihaza özgü UUID (premium provider'dan gelir)
  /// - [receiptData]: RevenueCat originalAppUserId (ticket)
  /// - [packageIdentifier]: Satın alınan paket ID (ör. 'pro_monthly')
  ///
  /// Backend döndürür:
  /// ```json
  /// {
  ///   "success": true,
  ///   "membership": {
  ///     "planId": "pro",
  ///     "startDate": "2024-01-01T00:00:00Z",
  ///     "endDate": "2025-01-01T00:00:00Z",
  ///     "isActive": true
  ///   }
  /// }
  /// ```
  ///
  /// Hatalar:
  /// - [HttpException] - Network hatası
  /// - [FormatException] - JSON parse hatası
  /// - Exception - 200 dışı status code
  Future<Map<String, dynamic>> confirmPurchase({
    required String deviceId,
    int? userId,
    required String receiptData,
    required String packageIdentifier,
    DateTime? expiryDate,
    bool isTrial = false,
  }) async {
    try {
      final url = Uri.parse('${AppConstants.baseURL}$_endpoint');

      final payload = {
        'deviceId': deviceId,
        if (userId != null) 'userId': userId,
        'receiptData': receiptData,
        'packageIdentifier': packageIdentifier,
        // RevenueCat'ten gelen GERÇEK bitiş tarihi (3 gün deneme dahil).
        // Backend bunu kullanır; sabit +1 yıl varsaymaz.
        if (expiryDate != null) 'expiryDate': expiryDate.toUtc().toIso8601String(),
        'isTrial': isTrial,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Premium confirmation timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          'Premium confirmation failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Device'in premium statusunu backend'den kontrol et (güvenlik amaçlı)
  /// Opsiyonel: Offline mod için sadece local cache kullanılabilir.
  ///
  /// Döner:
  /// ```json
  /// {
  ///   "isPremium": true,
  ///   "planId": "pro",
  ///   "startDate": "2024-01-01T00:00:00Z",
  ///   "endDate": "2025-01-01T00:00:00Z",
  ///   "daysRemaining": 365
  /// }
  /// ```
  Future<Map<String, dynamic>> getDevicePremiumStatus({
    required String deviceId,
    int? userId,
  }) async {
    try {
      final qs = userId != null ? '?userId=$userId' : '';
      final url = Uri.parse(
        '${AppConstants.baseURL}/api/v1/premium/device-status/$deviceId$qs',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Premium status check timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          'Status check failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Güncellenmiş entitlement kontrolü (RevenueCat entitlement'ı backend'de
  /// doğrulanır)
  Future<bool> verifyEntitlementActive({
    required String deviceId,
    required String entitlementName,
  }) async {
    try {
      final data = await getDevicePremiumStatus(deviceId: deviceId);
      return data['isPremium'] == true && data['endDate'] != null;
    } catch (e) {
      return false;
    }
  }
}
