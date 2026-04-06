import 'package:flutter/material.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:mindcoach/app/my_app.dart';
import 'in_app_notification_service.dart';

class NotificationService {
  Future initiializeOnesignal() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      OneSignal.initialize(AppConstants.onesignalId);
      debugPrint('[ONESIGNAL] ✅ OneSignal initialized with App ID: ${AppConstants.onesignalId}');

      final permissionGranted = await OneSignal.Notifications.requestPermission(false);
      debugPrint('[ONESIGNAL] Permission granted: $permissionGranted');

      // Foreground notification listener - bildirim geldiğinde yakala
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('[ONESIGNAL] 📬 Foreground notification received: ${event.notification.notificationId}');
        debugPrint('[ONESIGNAL] Title: ${event.notification.title}');
        debugPrint('[ONESIGNAL] Body: ${event.notification.body}');
        debugPrint('[ONESIGNAL] Additional data: ${event.notification.additionalData}');
        
        // Additional data'dan type'ı kontrol et
        final additionalData = event.notification.additionalData;
        final notificationType = additionalData?['type'] as String?;
        
        // Appointment bildirimi ise in-app notification göster
        if (notificationType == 'appointment') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            InAppNotificationService.showAppointmentNotification(
              onTap: () {
                Navigator.pushNamed(context, PageRoutes.notifications);
              },
              context,
              title: event.notification.title ?? 'Yeni Randevu',
              subtitle: event.notification.body ?? '',
              duration: const Duration(seconds: 4),
            );
            debugPrint('[ONESIGNAL] ✅ Appointment in-app notification shown');
          } else {
            debugPrint('[ONESIGNAL] ⚠️ Context is null, cannot show in-app notification');
          }
        }
      });

      // Notification click listener
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('[ONESIGNAL] 📱 Notification clicked: ${event.notification.notificationId}');
        debugPrint('[ONESIGNAL] Notification title: ${event.notification.title}');
        debugPrint('[ONESIGNAL] Notification body: ${event.notification.body}');
        debugPrint('[ONESIGNAL] Additional data: ${event.notification.additionalData}');
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
        debugPrint('[ONESIGNAL] OneSignal Push Subscription ID: $pushSubscriptionId');
      } catch (e) {
        debugPrint('[ONESIGNAL] Could not get push subscription ID: $e');
      }
    } catch (e) {
      debugPrint("[ONESIGNAL]  Error registering user: $e");
      rethrow;
    }
  }
}