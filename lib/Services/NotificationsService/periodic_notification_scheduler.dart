import 'package:flutter/material.dart';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_content.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_preferences.dart';

class PeriodicNotificationScheduler {
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  final NotificationPreferences _preferences = NotificationPreferences();

  Future<void> initializeAndSchedule() async {
    try {
      debugPrint('[PERIODIC_NOTIF]  Initializing periodic notifications...');

      await _localNotificationService.initialize();
      await _localNotificationService.requestPermissions();

      final notificationsEnabled = await _preferences.areNotificationsEnabled();
      if (!notificationsEnabled) {
        debugPrint('[PERIODIC_NOTIF]  Notifications are disabled');
        await cancelAllNotifications();
        return;
      }

      // Get or set start time
      var startTime = await _preferences.getStartTime();
      if (startTime == null) {
        startTime = DateTime.now();
        await _preferences.setStartTime(startTime);
      }

      // Schedule each interval notification
      await _scheduleInterval(2, startTime);
      await _scheduleInterval(4, startTime);
      await _scheduleInterval(8, startTime);
      await _scheduleInterval(24, startTime);

      debugPrint('[PERIODIC_NOTIF]  All periodic notifications scheduled');
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF]  Error initializing: $e');
      rethrow;
    }
  }

  /// Schedule notification for specific interval
  Future<void> _scheduleInterval(int hours, DateTime startTime) async {
    try {
      // Check if this interval is enabled
      final isEnabled = await _preferences.isIntervalEnabled(hours);
      if (!isEnabled) {
        debugPrint('[PERIODIC_NOTIF]  ${hours}h interval is disabled');
        await _cancelInterval(hours);
        return;
      }

      final content = NotificationContent.forInterval(hours);
      final notificationId = NotificationPreferences.getIdForInterval(hours);

      if (hours == 24) {
        await _localNotificationService.schedulePeriodicNotification(
          id: notificationId,
          title: content.title,
          body: content.body,
          interval: hours,
          startTime: startTime,
          payload: content.payload,
        );
      } else {

        final nextTime = _calculateNextNotificationTime(startTime, hours);
        
        await _localNotificationService.scheduleSpecificTimeNotification(
          id: notificationId,
          title: content.title,
          body: content.body,
          intervalHours: hours,
          startTime: nextTime,
          payload: content.payload,
        );
      }

      debugPrint('[PERIODIC_NOTIF] ✅ Scheduled ${hours}h notification');
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] ❌ Error scheduling ${hours}h notification: $e');
    }
  }

  DateTime _calculateNextNotificationTime(DateTime startTime, int hours) {
    final now = DateTime.now();
    final difference = now.difference(startTime);
    final hoursPassed = difference.inHours;
    

    final intervalsPassed = hoursPassed ~/ hours;

    final nextInterval = intervalsPassed + 1;
    final nextTime = startTime.add(Duration(hours: nextInterval * hours));
    

    if (nextTime.isBefore(now)) {
      return nextTime.add(Duration(hours: hours));
    }
    
    return nextTime;
  }

  Future<void> _cancelInterval(int hours) async {
    try {
      final notificationId = NotificationPreferences.getIdForInterval(hours);
      await _localNotificationService.cancelNotification(notificationId);
      debugPrint('[PERIODIC_NOTIF] ✅ Cancelled ${hours}h notification');
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] ❌ Error cancelling ${hours}h notification: $e');
    }
  }

  /// Cancel all periodic notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotificationService.cancelNotification(NotificationPreferences.id2Hours);
      await _localNotificationService.cancelNotification(NotificationPreferences.id4Hours);
      await _localNotificationService.cancelNotification(NotificationPreferences.id8Hours);
      await _localNotificationService.cancelNotification(NotificationPreferences.id24Hours);
      debugPrint('[PERIODIC_NOTIF] ✅ Cancelled all periodic notifications');
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] ❌ Error cancelling all notifications: $e');
    }
  }

  /// Update notification schedule (when preferences change)
  Future<void> updateSchedule() async {
    await initializeAndSchedule();
  }

  /// Enable/disable specific interval
  Future<void> setIntervalEnabled(int hours, bool enabled) async {
    await _preferences.setIntervalEnabled(hours, enabled);
    await updateSchedule();
  }

  /// Enable/disable all notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _preferences.setNotificationsEnabled(enabled);
    if (enabled) {
      await initializeAndSchedule();
    } else {
      await cancelAllNotifications();
    }
  }
}

