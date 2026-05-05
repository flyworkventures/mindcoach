import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/RevenueCatService/revenuecat_service.dart';
import 'package:mindcoach/core/utils/device_utils.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:rive/rive.dart';

import 'app/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiveNative.init();

  // Initialize device-based premium system
  await _initializePremiumSystem();

  await RevenuecatService().initializeRevenueCat();
  try {
    final notificationService = NotificationService();
    await notificationService.initiializeOnesignal();
  } catch (e) {}

  try {
    final localNotificationService = LocalNotificationService();
    await localNotificationService.initialize();
  } catch (e) {}

  runApp(ProviderScope(child: MyApp()));
}

/// Device-based premium systemi başlat
/// İlk launch'da 3 günlük trial'ı aktivat ve backend'e kaydet
Future<void> _initializePremiumSystem() async {
  try {
    // Device ID'yi oluştur veya al
    final deviceId = await DeviceUtils.getDeviceId();
    debugPrint('📱 Device ID: $deviceId');

    // Local DB'de premium durumu kontrol et
    final localDb = LocalDbService();
    final isActive = await localDb.isPremiumActive();

    // Eğer active değilse ve premium data yoksa, 3 günlük trial'ı aktivat
    if (!isActive) {
      final expiryDate = DateTime.now().add(const Duration(days: 3));
      await localDb.setPremiumStartDate(DateTime.now());
      await localDb.setPremiumExpiryDate(expiryDate);
      await localDb.setIsPremiumPurchased(false);

      debugPrint('✅ 3-day trial premium activated locally for device: $deviceId');
    }

    // Backend'e device'i register et (non-blocking)
    _registerDeviceWithBackend(deviceId);
  } catch (e) {
    debugPrint('⚠️ Premium initialization error: $e');
  }
}

/// Backend'e device'i register et (3-day trial oluştur)
/// Non-blocking: başarısız olsa bile app çalışmaya devam etsin
Future<void> _registerDeviceWithBackend(String deviceId) async {
  try {
    final response = await http.post(
      Uri.parse('${AppConstants.baseURL}/api/v1/premium/initialize'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'deviceId': deviceId,
      }),
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw Exception('Backend device registration timeout');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        debugPrint('✅ Device registered with backend: $deviceId');
        debugPrint('   → Trial expires in ${data['daysRemaining']} days');
      }
    } else {
      debugPrint('⚠️ Backend registration failed: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('⚠️ Backend device registration failed (non-blocking): $e');
    // Hata bile olsa app çalışmaya devam etsin
  }
}

// apple onesignal b3ba2ab4-03a9-45dc-a303-f0a92d7d1410
