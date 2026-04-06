import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'dart:developer' as developer;

class NotificationSettingsState {
  final bool enabled;
  const NotificationSettingsState({required this.enabled});

  NotificationSettingsState copyWith({bool? enabled}) =>
      NotificationSettingsState(enabled: enabled ?? this.enabled);
}

class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  final LocalDbService _localDbService = LocalDbService();

  @override
  NotificationSettingsState build() {
    // Başlangıçta local storage'dan yükle
    Future.microtask(() => _loadSavedSettings());
    // Varsayılan olarak true (eğer kayıtlı değer yoksa)
    return const NotificationSettingsState(enabled: true);
  }

  /// Local storage'dan kaydedilmiş bildirim ayarını yükle
  Future<void> _loadSavedSettings() async {
    try {
      final savedValue = await _localDbService.getBool(
        key: LocalDbKeys.notificationsEnabled,
      );
      
      if (savedValue != null) {
        state = NotificationSettingsState(enabled: savedValue);
        developer.log('✅ Bildirim ayarı yüklendi: $savedValue');
        
        // OneSignal'de de ayarla
        await _updateOneSignalSettings(savedValue);
      } else {
        // Kayıtlı değer yoksa varsayılan olarak true ve kaydet
        state = const NotificationSettingsState(enabled: true);
        await _localDbService.setBool(
          key: LocalDbKeys.notificationsEnabled,
          value: true,
        );
        await _updateOneSignalSettings(true);
        developer.log('ℹ️ Bildirim ayarı kayıtlı değil, varsayılan olarak true ayarlandı');
      }
    } catch (e) {
      developer.log('❌ Bildirim ayarı yüklenirken hata: $e');
      // Hata durumunda varsayılan değer
      state = const NotificationSettingsState(enabled: true);
    }
  }

  /// Bildirim ayarını güncelle (local storage + OneSignal)
  Future<void> setEnabled(bool val) async {
    try {
      // State'i güncelle
      state = state.copyWith(enabled: val);
      
      // Local storage'a kaydet
      await _localDbService.setBool(
        key: LocalDbKeys.notificationsEnabled,
        value: val,
      );
      
      developer.log('✅ Bildirim ayarı güncellendi: $val');
      
      // OneSignal'de de ayarla
      await _updateOneSignalSettings(val);
    } catch (e) {
      developer.log('❌ Bildirim ayarı güncellenirken hata: $e');
    }
  }

  /// OneSignal'de bildirim ayarlarını güncelle
  Future<void> _updateOneSignalSettings(bool enabled) async {
    try {
      if (enabled) {
        // Bildirimleri aç
        await OneSignal.Notifications.requestPermission(true);
        developer.log('✅ OneSignal bildirimleri açıldı');
      } else {
        // Bildirimleri kapat (opt out)
        await OneSignal.User.pushSubscription.optOut();
        developer.log('✅ OneSignal bildirimleri kapatıldı');
      }
    } catch (e) {
      developer.log('❌ OneSignal ayarları güncellenirken hata: $e');
    }
  }

  void toggle() {
    setEnabled(!state.enabled);
  }
}

final notificationSettingsProvider =
NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  NotificationSettingsNotifier.new,
);
