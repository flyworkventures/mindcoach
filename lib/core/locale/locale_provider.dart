import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import '../utils/local_db_keys.dart';

final localeProvider =
NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  final LocalDbService _localDbService = LocalDbService();

  @override
  Locale? build() {

    Future.microtask(() => _loadSavedLocale());

    return null;
  }

  Future<void> _loadSavedLocale() async {
    try {
      final savedLocaleCode = await _localDbService.getString(
        key: LocalDbKeys.locale,
      );

      if (savedLocaleCode != null && savedLocaleCode.isNotEmpty) {
        // "en", "tr", "de" gibi kodları Locale'e çevir
        final locale = Locale(savedLocaleCode);
        state = locale;
      } else {
        state = null;
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');

      state = null;
    }
  }

  Future<void> setLocale(Locale? newLocale) async {
    final previousCode = getLanguageCode();
    state = newLocale;
    final newCode = newLocale?.languageCode ?? getSystemLocale().languageCode;
    if (previousCode != newCode) {
      unawaited(AnalyticsService.instance.capture(
        AnalyticsEvents.languageChanged,
        properties: {
          'from': previousCode,
          'to': newCode,
          'is_system_default': newLocale == null,
        },
      ));
    }

    try {
      if (newLocale != null) {
        await _localDbService.setString(
          key: LocalDbKeys.locale,
          value: newLocale.languageCode,
        );
      } else {
        await _localDbService.setString(
          key: LocalDbKeys.locale,
          value: '',
        );
      }
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  Future<void> resetToSystemLocale() async {
    await setLocale(null);
  }

  Locale getCurrentLocale() {
    if (state != null) {
      return state!;
    }

    return ui.PlatformDispatcher.instance.locale;
  }

  String getLanguageCode() {
    return getCurrentLocale().languageCode;
  }


  bool isLocaleSupported(Locale locale) {
    const supportedLocales = [
      Locale('en'),
      Locale('tr'),
      Locale('de'),
    ];
    return supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }
  Locale getSystemLocale() {
    return ui.PlatformDispatcher.instance.locale;
  }

  bool get hasCustomLocale => state != null;
}
