import 'package:flutter/material.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  Map<String, dynamic> _normalizeAdditionalData(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final metadata = raw['metadata'];
    if (metadata is Map) {
      return {...raw, ...Map<String, dynamic>.from(metadata)};
    }
    return Map<String, dynamic>.from(raw);
  }

  Future initiializeOnesignal() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      OneSignal.initialize(AppConstants.onesignalId);
      debugPrint(
        '[ONESIGNAL] ✅ OneSignal initialized with App ID: ${AppConstants.onesignalId}',
      );

      final permissionGranted = await OneSignal.Notifications.requestPermission(
        false,
      );
      debugPrint('[ONESIGNAL] Permission granted: $permissionGranted');

      // Foreground notification listener - bildirim geldiğinde yakala
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint(
          '[ONESIGNAL] 📬 Foreground notification received: ${event.notification.notificationId}',
        );
        debugPrint('[ONESIGNAL] Title: ${event.notification.title}');
        debugPrint('[ONESIGNAL] Body: ${event.notification.body}');
        debugPrint(
          '[ONESIGNAL] Additional data: ${event.notification.additionalData}',
        );

        // Additional data'dan type'ı kontrol et
        final additionalData = event.notification.additionalData;
        final normalizedData = _normalizeAdditionalData(additionalData);
        final notificationType = normalizedData['type'] as String?;

        // Appointment bildirimi için burada ikinci kez in-app göstermiyoruz.
        // In-app gösterim, API'den gelen bildirim listesi üzerinden navbar_shell'de merkezi yönetiliyor.
        if (notificationType == 'appointment') {
          debugPrint(
            '[ONESIGNAL] ℹ️ Appointment foreground push alindi; in-app gosterim navbar akisinda yapilacak',
          );
        }
      });

      // Notification click listener
      OneSignal.Notifications.addClickListener((event) {
        debugPrint(
          '[ONESIGNAL] 📱 Notification clicked: ${event.notification.notificationId}',
        );
        debugPrint(
          '[ONESIGNAL] Notification title: ${event.notification.title}',
        );
        debugPrint('[ONESIGNAL] Notification body: ${event.notification.body}');
        debugPrint(
          '[ONESIGNAL] Additional data: ${event.notification.additionalData}',
        );
      });

      debugPrint('[ONESIGNAL] ✅ OneSignal setup completed');
    } catch (e) {
      debugPrint('[ONESIGNAL] ❌ Initialization error: $e');
      rethrow;
    }
  }

  Future registerUser(String userId) async {
    try {
      await OneSignal.login(userId);
      debugPrint('[ONESIGNAL] User registered with External User ID: $userId');

      try {
        final pushSubscriptionId = OneSignal.User.pushSubscription.id;
        debugPrint(
          '[ONESIGNAL] OneSignal Push Subscription ID: $pushSubscriptionId',
        );
      } catch (e) {
        debugPrint('[ONESIGNAL] Could not get push subscription ID: $e');
      }
    } catch (e) {
      debugPrint("[ONESIGNAL]  Error registering user: $e");
      rethrow;
    }
  }
}
