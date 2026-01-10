import 'package:flutter/material.dart';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_content.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_preferences.dart';

/// Periodic Notification Scheduler
/// Manages scheduling of periodic notifications (2h, 4h, 8h, 24h)
class PeriodicNotificationScheduler {
  final LocalNotificationService _localNotificationService = LocalNotificationService();
  final NotificationPreferences _preferences = NotificationPreferences();

  /// Initialize and schedule all periodic notifications
  Future<void> initializeAndSchedule() async {
    try {
      debugPrint('[PERIODIC_NOTIF] 🚀 Initializing periodic notifications...');

      // Initialize local notification service
      await _localNotificationService.initialize();
      await _localNotificationService.requestPermissions();

      // Check if notifications are enabled
      final notificationsEnabled = await _preferences.areNotificationsEnabled();
      if (!notificationsEnabled) {
        debugPrint('[PERIODIC_NOTIF] ⚠️ Notifications are disabled');
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

      debugPrint('[PERIODIC_NOTIF] ✅ All periodic notifications scheduled');
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] ❌ Error initializing: $e');
      rethrow;
    }
  }

  /// Schedule notification for specific interval
  Future<void> _scheduleInterval(int hours, DateTime startTime) async {
    try {
      // Check if this interval is enabled
      final isEnabled = await _preferences.isIntervalEnabled(hours);
      if (!isEnabled) {
        debugPrint('[PERIODIC_NOTIF] ⚠️ ${hours}h interval is disabled');
        await _cancelInterval(hours);
        return;
      }

      // Get notification content
      final content = NotificationContent.forInterval(hours);
      final notificationId = NotificationPreferences.getIdForInterval(hours);

      // For 24 hours, use daily repeat
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
        // For 2h, 4h, 8h - use specific time scheduling
        // Calculate next notification time based on interval
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

  /// Calculate next notification time based on interval
  DateTime _calculateNextNotificationTime(DateTime startTime, int hours) {
    final now = DateTime.now();
    final difference = now.difference(startTime);
    final hoursPassed = difference.inHours;
    
    // Calculate how many intervals have passed
    final intervalsPassed = hoursPassed ~/ hours;
    
    // Calculate next notification time
    final nextInterval = intervalsPassed + 1;
    final nextTime = startTime.add(Duration(hours: nextInterval * hours));
    
    // If next time is in the past, add one more interval
    if (nextTime.isBefore(now)) {
      return nextTime.add(Duration(hours: hours));
    }
    
    return nextTime;
  }

  /// Cancel notification for specific interval
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

