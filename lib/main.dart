import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/RevenueCatService/revenuecat_service.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/device_utils.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:rive/rive.dart';

import 'app/my_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await RiveNative.init();

  await AnalyticsService.instance.initialize();

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

/// Device-based premium systemi başlat.
/// 3 günlük trial cihaz başına SADECE BİR KEZ verilir.
/// Source of truth: backend (device_id bazlı, persist eder).
/// Backend ulaşılamazsa: local fallback — hasUsedTrial flag'i ile tek seferlik garantisi.
Future<void> _initializePremiumSystem() async {
  try {
    final deviceId = await DeviceUtils.getDeviceId();
    debugPrint('📱 Device ID: $deviceId');
    await AnalyticsService.instance.identifyDevice(deviceId);

    final localDb = LocalDbService();
    final hasLaunchedBefore =
        await localDb.getBool(key: LocalDbKeys.appHasLaunched) ?? false;
    final isFirstOpen = !hasLaunchedBefore;
    if (isFirstOpen) {
      await localDb.setBool(key: LocalDbKeys.appHasLaunched, value: true);
    }
    await AnalyticsService.instance.capture(
      AnalyticsEvents.appOpened,
      properties: {
        'is_first_open': isFirstOpen,
        'app_version': AppConstants.appVersion,
        'platform': Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? 'android'
                : Platform.operatingSystem,
      },
    );

    // 1) Önce backend'i dene (authoritative). Backend cihaz daha önce trial almışsa
    //    yenisini vermez, mevcut status'unu döner (expired ise isPremium:false).
    final backendSynced = await _syncPremiumWithBackend(deviceId, localDb);
    if (backendSynced) return;

    // 2) Backend ulaşılamadı → local fallback.
    final hasUsedTrial = await localDb.getHasUsedTrial();
    final isActive = await localDb.isPremiumActive();

    if (isActive) {
      debugPrint('ℹ️ Local premium aktif, backend sync ertelendi.');
      return;
    }

    if (hasUsedTrial) {
      // Trial daha önce verilmiş ve bitmiş — bir daha verme.
      debugPrint('🚫 Trial daha önce kullanılmış, yeniden verilmiyor.');
      return;
    }

    // İlk kez: 3 günlük trial ver ve flag'i kalıcı set et.
    final expiryDate = DateTime.now().add(const Duration(days: 3));
    await localDb.setPremiumStartDate(DateTime.now());
    await localDb.setPremiumExpiryDate(expiryDate);
    await localDb.setIsPremiumPurchased(false);
    await localDb.setHasUsedTrial(true);

    debugPrint(
      '✅ 3-day trial premium activated locally for device: $deviceId (backend offline fallback)',
    );
  } catch (e) {
    debugPrint('⚠️ Premium initialization error: $e');
  }
}

/// Backend'i source of truth olarak kullanır:
///  - Yeni cihaz → backend 3 günlük trial verir, local'a yazarız.
///  - Mevcut cihaz, trial aktif → backend mevcut expiry'i döner, local'i sync ederiz.
///  - Mevcut cihaz, trial bitmiş → backend isPremium:false döner, local'i temizleriz
///    ve hasUsedTrial=true set ederiz (bir daha trial verilmesin).
/// Return: true = senkronize edildi, false = backend'e ulaşılamadı (fallback'e geç).
Future<bool> _syncPremiumWithBackend(
  String deviceId,
  LocalDbService localDb,
) async {
  try {
    final response = await http
        .post(
          Uri.parse('${AppConstants.baseURL}/api/v1/premium/initialize'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'deviceId': deviceId}),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      debugPrint('⚠️ Backend status ${response.statusCode}, local fallback.');
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return false;

    final bool isPremium = data['isPremium'] == true;
    final String? expiryStr = data['expiryDate'] as String?;
    final bool isTrial = data['isTrial'] == true || data['planId'] == 'trial';

    if (isPremium && expiryStr != null) {
      final expiryDate = DateTime.tryParse(expiryStr);
      if (expiryDate != null) {
        await localDb.setPremiumExpiryDate(expiryDate);
        await localDb.setIsPremiumPurchased(!isTrial);
        // Backend trial verdiyse / hala trialdaysa flag'i set et.
        if (isTrial) {
          await localDb.setHasUsedTrial(true);
          // Start date yoksa şimdi set et (sadece bilgi amaçlı).
          final existingStart = await localDb.getPremiumStartDate();
          if (existingStart == null) {
            await localDb.setPremiumStartDate(DateTime.now());
          }
        }
        debugPrint(
          '✅ Backend sync: premium aktif (${data['daysRemaining']} gün kaldı, trial=$isTrial).',
        );
        return true;
      }
    }

    // Backend açıkça "premium yok / expired" dedi → local'i temizle, ama
    // hasUsedTrial=true kalsın (trial bu cihazda zaten kullanılmış).
    await localDb.clearPremiumStatus();
    await localDb.setHasUsedTrial(true);
    debugPrint('ℹ️ Backend sync: premium yok / expired, local temizlendi.');
    return true;
  } catch (e) {
    debugPrint('⚠️ Backend sync failed, local fallback: $e');
    return false;
  }
}

// apple onesignal b3ba2ab4-03a9-45dc-a303-f0a92d7d1410
