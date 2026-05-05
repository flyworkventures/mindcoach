import 'package:dio/dio.dart';
import '../../core/utils/app_constants.dart';

/// Backend'e premium satın alınıp satın alınmadığını bildirmek için API service
class PremiumApiService {
  final Dio _dio;

  PremiumApiService({Dio? dio}) : _dio = dio ?? Dio();

  /// RevenueCat satın alımının ardından backend'i bilgilendir
  /// Backend user'ın membership'ini güncelleyecek
  Future<PremiumConfirmResponse> confirmPurchase({
    required String deviceId,
    required String receiptData,
    required String packageIdentifier,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.baseURL}/api/v1/premium/confirm-purchase',
        data: {
          'deviceId': deviceId,
          'receiptData': receiptData,
          'packageIdentifier': packageIdentifier,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        return PremiumConfirmResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to confirm purchase: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error confirming purchase: ${e.message}');
    } catch (e) {
      throw Exception('Error confirming purchase: $e');
    }
  }
}

/// Backend'den dönen premium confirmation response
class PremiumConfirmResponse {
  final bool success;
  final MembershipData? membership;
  final String? errorMessage;

  PremiumConfirmResponse({
    required this.success,
    this.membership,
    this.errorMessage,
  });

  factory PremiumConfirmResponse.fromJson(Map<String, dynamic> json) {
    return PremiumConfirmResponse(
      success: json['success'] ?? false,
      membership: json['membership'] != null
          ? MembershipData.fromJson(json['membership'])
          : null,
      errorMessage: json['error'],
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'membership': membership?.toJson(),
        'error': errorMessage,
      };
}

/// Backend'den dönen membership verisi
class MembershipData {
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  MembershipData({
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory MembershipData.fromJson(Map<String, dynamic> json) {
    return MembershipData(
      planId: json['planId'] ?? 'pro',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String()),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isActive': isActive,
      };
}
