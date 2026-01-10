import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'app/my_app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize OneSignal
  try {
    final notificationService = NotificationService();
    await notificationService.initiializeOnesignal();
    debugPrint('✅ OneSignal initialized successfully');
  } catch (e) {
    debugPrint('❌ OneSignal initialization error: $e');
  }

  // Initialize Local Notifications (for periodic notifications)
  try {
    final localNotificationService = LocalNotificationService();
    await localNotificationService.initialize();
    debugPrint('✅ Local notifications initialized successfully');
  } catch (e) {
    debugPrint('❌ Local notifications initialization error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

// apple onesignal b3ba2ab4-03a9-45dc-a303-f0a92d7d1410