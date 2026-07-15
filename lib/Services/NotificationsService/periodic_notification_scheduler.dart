import 'package:flutter/material.dart';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_content.dart';
import 'package:mindcoach/Services/NotificationsService/notification_language_resolver.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_preferences.dart';

/// Periyodik (yerel) hatırlatma bildirimlerini yönetir.
///
/// ÖNEMLİ: Eski sürüm 2/4/8/24 saat aralıklarını AYNI ANDA planlıyordu.
/// Ortak katlarda (örn. her 4. saatte hem 2h hem 4h) aynı anda 2+ bildirim
/// geliyordu. Artık yalnızca tek bir aktif cadence planlanır.
class PeriodicNotificationScheduler {
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final NotificationPreferences _preferences = NotificationPreferences();

  /// Eski slotları temizlemek için bilinen aralıklar.
  static const List<int> _legacyIntervals = [2, 4, 8, 24];

  /// Ürün cadence'i: tek aralık → çakışma yok.
  static const int _activeCadenceHours = 4;

  /// Her aralık için ileriye dönük kaç occurrence planlanacağı.
  static const int _occurrencesToSchedule = 6;

  /// Occurrence slot bloğu (eski ID düzeniyle uyumlu iptal için).
  static const int _slotBlock = 100;

  Future<void> initializeAndSchedule() async {
    try {
      debugPrint('[PERIODIC_NOTIF] Initializing periodic notifications...');

      await _localNotificationService.initialize();
      await _localNotificationService.requestPermissions();

      final notificationsEnabled =
          await _preferences.areNotificationsEnabled();
      if (!notificationsEnabled) {
        debugPrint('[PERIODIC_NOTIF] Notifications are disabled');
        await cancelAllNotifications();
        return;
      }

      // Önce TÜM eski (2/4/8/24) planları sil — kalıntı çift bildirim önlemi.
      await cancelAllNotifications();

      var startTime = await _preferences.getStartTime();
      if (startTime == null) {
        startTime = DateTime.now();
        await _preferences.setStartTime(startTime);
      }

      final languageCode = await NotificationLanguageResolver.resolve();
      debugPrint(
        '[PERIODIC_NOTIF] Language: $languageCode, '
        'cadence: ${_activeCadenceHours}h',
      );

      await _scheduleInterval(_activeCadenceHours, startTime, languageCode);

      debugPrint('[PERIODIC_NOTIF] Periodic notifications scheduled (single cadence)');
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] Error initializing: $e');
      rethrow;
    }
  }

  /// Belirli bir aralık için önümüzdeki occurrence'ları farklı metinlerle
  /// planlar.
  Future<void> _scheduleInterval(
    int hours,
    DateTime startTime,
    String languageCode,
  ) async {
    try {
      await _cancelInterval(hours);

      final now = DateTime.now();

      final hoursPassed = now.difference(startTime).inHours;
      final intervalsPassed = hoursPassed < 0 ? 0 : (hoursPassed ~/ hours);
      var nextOccurrence = intervalsPassed + 1;

      var scheduled = 0;
      var slot = 0;
      while (scheduled < _occurrencesToSchedule && slot < _slotBlock) {
        final occurrenceTime =
            startTime.add(Duration(hours: nextOccurrence * hours));

        if (occurrenceTime.isAfter(now)) {
          final content = NotificationContent.forInterval(
            hours,
            occurrence: nextOccurrence,
            languageCode: languageCode,
          );
          final id = _slotId(hours, slot);

          await _localNotificationService.schedulePeriodicReminderAt(
            id: id,
            title: content.title,
            body: content.body,
            scheduledTime: occurrenceTime,
            payload: content.payload,
          );

          scheduled++;
          slot++;
        }

        nextOccurrence++;
      }

      debugPrint(
        '[PERIODIC_NOTIF] ✅ Scheduled $scheduled occurrences for ${hours}h '
        '(pool=${NotificationContent.poolSize(hours)})',
      );
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] ❌ Error scheduling ${hours}h: $e');
    }
  }

  int _slotId(int hours, int slot) {
    return NotificationPreferences.getIdForInterval(hours) * _slotBlock + slot;
  }

  Future<void> _cancelInterval(int hours) async {
    try {
      for (var slot = 0; slot < _slotBlock; slot++) {
        await _localNotificationService
            .cancelNotification(_slotId(hours, slot));
      }
      await _localNotificationService
          .cancelNotification(NotificationPreferences.getIdForInterval(hours));
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] ❌ Error cancelling ${hours}h: $e');
    }
  }

  /// Tüm periyodik bildirimleri iptal eder (legacy aralıklar dahil).
  Future<void> cancelAllNotifications() async {
    for (final hours in _legacyIntervals) {
      await _cancelInterval(hours);
    }
    debugPrint('[PERIODIC_NOTIF] ✅ Cancelled all periodic notifications');
  }

  Future<void> updateSchedule() async {
    await initializeAndSchedule();
  }

  Future<void> setIntervalEnabled(int hours, bool enabled) async {
    await _preferences.setIntervalEnabled(hours, enabled);
    await updateSchedule();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _preferences.setNotificationsEnabled(enabled);
    if (enabled) {
      await initializeAndSchedule();
    } else {
      await cancelAllNotifications();
    }
  }
}
