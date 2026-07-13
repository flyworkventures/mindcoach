import 'package:flutter/material.dart';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_content.dart';
import 'package:mindcoach/Services/NotificationsService/notification_language_resolver.dart';
import 'package:mindcoach/Services/NotificationsService/models/notification_preferences.dart';

/// Periyodik (yerel) hatırlatma bildirimlerini yönetir.
///
/// Neden bu tasarım: Eski sürümde her aralık tek sabit metinle
/// `periodicallyShow` / `matchDateTimeComponents` ile planlanıyordu; bu da
/// "aynı bildirimin sürekli tekrar etmesine" yol açıyordu (içerik planlama
/// anında sabitlenir, occurrence başına değişemez).
///
/// Yeni tasarım: Her aralık için önümüzdeki birkaç occurrence AYRI birer
/// tek-seferlik bildirim olarak planlanır ve her occurrence havuzdan FARKLI
/// bir mesaj alır. Uygulama her açıldığında bu pencere yeniden doldurulur.
class PeriodicNotificationScheduler {
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();
  final NotificationPreferences _preferences = NotificationPreferences();

  static const List<int> _intervals = [2, 4, 8, 24];

  /// Her aralık için ileriye dönük kaç occurrence planlanacağı.
  static const int _occurrencesToSchedule = 6;

  /// Her aralık için ayrılan ID bloğu genişliği (occurrence slotları).
  /// Örn. 2h → 100100..100105, 4h → 100200..100205 ...
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

      var startTime = await _preferences.getStartTime();
      if (startTime == null) {
        startTime = DateTime.now();
        await _preferences.setStartTime(startTime);
      }

      final languageCode = await NotificationLanguageResolver.resolve();
      debugPrint('[PERIODIC_NOTIF] Language: $languageCode');

      for (final hours in _intervals) {
        await _scheduleInterval(hours, startTime, languageCode);
      }

      debugPrint('[PERIODIC_NOTIF] All periodic notifications scheduled');
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] Error initializing: $e');
      rethrow;
    }
  }

  /// Belirli bir aralık için önümüzdeki occurrence'ları farklı metinlerle
  /// planlar. Önce eski slotları temizler (yeniden planlama / tekrar önleme).
  Future<void> _scheduleInterval(
    int hours,
    DateTime startTime,
    String languageCode,
  ) async {
    try {
      await _cancelInterval(hours);

      final isEnabled = await _preferences.isIntervalEnabled(hours);
      if (!isEnabled) {
        debugPrint('[PERIODIC_NOTIF] ${hours}h interval is disabled');
        return;
      }

      final now = DateTime.now();

      // startTime'a göre geçen tam aralık sayısı → bir sonraki occurrence no'su.
      final hoursPassed = now.difference(startTime).inHours;
      final intervalsPassed = hoursPassed < 0 ? 0 : (hoursPassed ~/ hours);
      var nextOccurrence = intervalsPassed + 1;

      var scheduled = 0;
      var slot = 0;
      while (scheduled < _occurrencesToSchedule && slot < _slotBlock) {
        final occurrenceTime =
            startTime.add(Duration(hours: nextOccurrence * hours));

        if (occurrenceTime.isAfter(now)) {
          // Rotasyon: mutlak occurrence numarasına göre farklı metin.
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

  /// Aralığın occurrence slot ID'si. Randevu (700000000+) ve diğer ID'lerle
  /// çakışmaz.
  int _slotId(int hours, int slot) {
    return NotificationPreferences.getIdForInterval(hours) * _slotBlock + slot;
  }

  Future<void> _cancelInterval(int hours) async {
    try {
      for (var slot = 0; slot < _slotBlock; slot++) {
        await _localNotificationService
            .cancelNotification(_slotId(hours, slot));
      }
      // Eski sürümden kalmış olabilecek tek-ID planlamayı da temizle.
      await _localNotificationService
          .cancelNotification(NotificationPreferences.getIdForInterval(hours));
    } catch (e) {
      debugPrint('[PERIODIC_NOTIF] ❌ Error cancelling ${hours}h: $e');
    }
  }

  /// Tüm periyodik bildirimleri iptal eder.
  Future<void> cancelAllNotifications() async {
    for (final hours in _intervals) {
      await _cancelInterval(hours);
    }
    debugPrint('[PERIODIC_NOTIF] ✅ Cancelled all periodic notifications');
  }

  /// Tercih değiştiğinde çağrılır.
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

