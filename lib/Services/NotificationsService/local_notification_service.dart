import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[LOCAL_NOTIF] Already initialized');
      return;
    }

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul')); // Türkiye saati

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');


      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );


      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );


      final initialized = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        debugPrint('[LOCAL_NOTIF] ✅ Local notifications initialized successfully');
      } else {
        debugPrint('[LOCAL_NOTIF] ❌ Failed to initialize local notifications');
      }
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Initialization error: $e');
      rethrow;
    }
  }


  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[LOCAL_NOTIF] 📱 Notification tapped: ${response.id}');
    debugPrint('[LOCAL_NOTIF] Payload: ${response.payload}');
  }


  Future<bool> requestPermissions() async {
    try {
      final android = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      final ios = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      final androidGranted = android ?? false;
      final iosGranted = ios ?? false;
      final granted = androidGranted || iosGranted;
      debugPrint('[LOCAL_NOTIF] Permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Permission request error: $e');
      return false;
    }
  }

  /// Schedule a periodic notification
  /// [id] - Unique notification ID
  /// [title] - Notification title
  /// [body] - Notification body
  /// [interval] - Repeat interval in hours (2, 4, 8, 24)
  /// [startTime] - When to start the first notification (optional, defaults to now)
  Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required int interval,
    DateTime? startTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        'periodic_notifications',
        'Periyodik Bildirimler',
        channelDescription: 'Düzenli aralıklarla gönderilen bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule periodic notification
      await _notificationsPlugin.periodicallyShow(
        id,
        title,
        body,
        _getRepeatInterval(interval),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('[LOCAL_NOTIF] ✅ Scheduled periodic notification: ID=$id, Interval=${interval}h');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Error scheduling notification: $e');
      rethrow;
    }
  }

  RepeatInterval _getRepeatInterval(int hours) {
    switch (hours) {
      case 2:
        return RepeatInterval.hourly; // Her saat 
      case 4:
        return RepeatInterval.hourly; // Her saat
      case 8:
        return RepeatInterval.hourly; // Her saat 
      case 24:
        return RepeatInterval.daily; // Her gün
      default:
        return RepeatInterval.hourly;
    }
  }


  Future<void> scheduleSpecificTimeNotification({
    required int id,
    required String title,
    required String body,
    required int intervalHours,
    DateTime? startTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final firstNotificationTime = startTime ?? DateTime.now();
      final tzFirstTime = tz.TZDateTime.from(firstNotificationTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'periodic_notifications',
        'Periyodik Bildirimler',
        channelDescription: 'Düzenli aralıklarla gönderilen bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );


      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule first notification
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzFirstTime,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Her gün aynı saatte
      );

      debugPrint('[LOCAL_NOTIF] ✅ Scheduled notification: ID=$id, Time=$tzFirstTime, Interval=${intervalHours}h');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Error scheduling notification: $e');
      rethrow;
    }
  }

  /// Schedule a one-time notification at an exact local date-time.
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders',
        'Randevu Hatirlaticilari',
        channelDescription: 'Randevular icin tek seferlik hatirlatmalar',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduled,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
        '[LOCAL_NOTIF] ✅ Scheduled one-time notification: ID=$id, Time=$tzScheduled',
      );
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Error scheduling one-time notification: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('[LOCAL_NOTIF] ✅ Cancelled notification: ID=$id');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[LOCAL_NOTIF] ✅ Cancelled all notifications');
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Error cancelling all notifications: $e');
    }
  }


  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('[LOCAL_NOTIF] ❌ Error getting pending notifications: $e');
      return [];
    }
  }
}

