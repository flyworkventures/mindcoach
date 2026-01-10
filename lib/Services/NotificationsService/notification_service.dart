import 'package:flutter/material.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  Future initiializeOnesignal() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      OneSignal.initialize(AppConstants.onesignalId);
      debugPrint('[ONESIGNAL] ✅ OneSignal initialized with App ID: ${AppConstants.onesignalId}');

      final permissionGranted = await OneSignal.Notifications.requestPermission(false);
      debugPrint('[ONESIGNAL] Permission granted: $permissionGranted');

      OneSignal.Notifications.addClickListener((event) {
        debugPrint('[ONESIGNAL] 📱 Notification clicked: ${event.notification.notificationId}');
        debugPrint('[ONESIGNAL] Notification title: ${event.notification.title}');
        debugPrint('[ONESIGNAL] Notification body: ${event.notification.body}');
      });

      debugPrint('[ONESIGNAL]  OneSignal setup completed');
    } catch (e) {
      debugPrint('[ONESIGNAL]  Initialization error: $e');
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