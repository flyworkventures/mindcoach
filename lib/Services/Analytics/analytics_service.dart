import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Merkezi PostHog analytics servisi.
/// API anahtarı boşsa tüm çağrılar no-op (prod'a key eklenene kadar güvenli).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  bool _initialized = false;
  bool _optedOut = false;
  bool get isEnabled => _initialized && !_optedOut;
  bool get isOptedOut => _optedOut;

  Future<void> initialize() async {
    final apiKey = AppConstants.postHogApiKey.trim();
    if (apiKey.isEmpty) {
      debugPrint(
        'ℹ️ PostHog devre dışı: AppConstants.postHogApiKey boş. '
        'PostHog dashboard → Project Settings → Project API Key değerini ekleyin.',
      );
      return;
    }

    try {
      // Kullanıcının önceden opt-out yapıp yapmadığını oku.
      _optedOut = await LocalDbService().getBool(
            key: LocalDbKeys.analyticsOptedOut,
          ) ??
          false;

      final config = PostHogConfig(apiKey);
      config.host = AppConstants.postHogHost;
      config.debug = kDebugMode;
      config.captureApplicationLifecycleEvents = true;
      await Posthog().setup(config);
      _initialized = true;

      // Disk'teki opt-out durumunu SDK'ya da yansıt.
      if (_optedOut) {
        await Posthog().disable();
        debugPrint('ℹ️ PostHog kullanıcı tarafından devre dışı bırakılmış.');
      }

      await _registerAppSuperProperties();
      await registerSuperProperties({'app_version': AppConstants.appVersion});
      debugPrint('✅ PostHog initialized (${AppConstants.postHogHost})');
    } catch (e, st) {
      debugPrint('⚠️ PostHog init failed: $e\n$st');
    }
  }

  Future<void> _registerAppSuperProperties() async {
    await registerSuperProperties({
      'app_name': 'mindcoach',
      'platform': Platform.operatingSystem,
      'build_mode': kReleaseMode ? 'release' : 'debug',
      'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
    });
  }

  /// GDPR/KVKK opt-out. Kullanıcı analytics'i kapatabilir; karar disk'te
  /// kalıcı olur, sonraki açılışlarda da uygulanır.
  Future<void> optOut() async {
    _optedOut = true;
    await LocalDbService().setBool(
      key: LocalDbKeys.analyticsOptedOut,
      value: true,
    );
    if (_initialized) {
      try {
        await Posthog().disable();
      } catch (e) {
        debugPrint('⚠️ PostHog optOut: $e');
      }
    }
  }

  Future<void> optIn() async {
    _optedOut = false;
    await LocalDbService().setBool(
      key: LocalDbKeys.analyticsOptedOut,
      value: false,
    );
    if (_initialized) {
      try {
        await Posthog().enable();
      } catch (e) {
        debugPrint('⚠️ PostHog optIn: $e');
      }
    }
  }

  Future<void> registerSuperProperties(Map<String, Object?> properties) async {
    if (!_initialized) return;
    try {
      for (final entry in properties.entries) {
        final v = entry.value;
        if (v != null) {
          await Posthog().register(entry.key, v);
        }
      }
    } catch (e) {
      debugPrint('⚠️ PostHog register: $e');
    }
  }

  /// Cihaz bazlı anonim kimlik (login öncesi).
  Future<void> identifyDevice(String deviceId) async {
    if (!_initialized || deviceId.isEmpty) return;
    try {
      await Posthog().identify(
        userId: 'device_$deviceId',
        userProperties: {'is_authenticated': false},
      );
    } catch (e) {
      debugPrint('⚠️ PostHog identifyDevice: $e');
    }
  }

  /// Giriş yapan kullanıcıyı tanımla.
  Future<void> identifyUser({
    required int userId,
    String? credential,
    bool? hasCompletedProfile,
    bool? isPremium,
    int? daysRemaining,
  }) async {
    if (!_initialized) return;
    try {
      await Posthog().identify(
        userId: userId.toString(),
        userProperties: {
          if (credential != null) 'credential': credential,
          if (hasCompletedProfile != null)
            'has_completed_profile': hasCompletedProfile,
          if (isPremium != null) 'is_premium': isPremium,
          if (daysRemaining != null) 'premium_days_remaining': daysRemaining,
        },
      );
    } catch (e) {
      debugPrint('⚠️ PostHog identifyUser: $e');
    }
  }

  Future<void> updatePersonProperties(
    String userId,
    Map<String, Object?> properties,
  ) async {
    if (!_initialized || userId.isEmpty) return;
    try {
      final props = <String, Object>{};
      for (final e in properties.entries) {
        if (e.value != null) props[e.key] = e.value!;
      }
      await Posthog().identify(userId: userId, userProperties: props);
    } catch (e) {
      debugPrint('⚠️ PostHog updatePersonProperties: $e');
    }
  }

  Future<void> reset() async {
    if (!_initialized) return;
    try {
      await Posthog().reset();
    } catch (e) {
      debugPrint('⚠️ PostHog reset: $e');
    }
  }

  /// Anonim funnel sırasında person property güncelle (login öncesi).
  Future<void> setPersonProperties(Map<String, Object?> properties) async {
    if (!isEnabled) return;
    try {
      final props = <String, Object>{};
      for (final e in properties.entries) {
        if (e.value != null) props[e.key] = e.value!;
      }
      if (props.isEmpty) return;
      await Posthog().setPersonProperties(userPropertiesToSet: props);
    } catch (e) {
      debugPrint('⚠️ PostHog setPersonProperties: $e');
    }
  }

  /// Auth tamamlandığında anonim oturumu gerçek kullanıcıya birleştir.
  Future<void> aliasAndIdentifyUser({
    required int userId,
    String? credential,
    bool? hasCompletedProfile,
    bool? isPremium,
    int? daysRemaining,
    Map<String, Object?>? personProperties,
  }) async {
    if (!_initialized) return;
    final id = userId.toString();
    try {
      await Posthog().alias(alias: id);
      await Posthog().identify(
        userId: id,
        userProperties: {
          if (credential != null) 'credential': credential,
          if (hasCompletedProfile != null)
            'has_completed_profile': hasCompletedProfile,
          if (isPremium != null) 'is_premium': isPremium,
          if (daysRemaining != null) 'premium_days_remaining': daysRemaining,
        },
      );
      if (personProperties != null && personProperties.isNotEmpty) {
        await setPersonProperties(personProperties);
      }
    } catch (e) {
      debugPrint('⚠️ PostHog aliasAndIdentifyUser: $e');
    }
  }

  Future<void> capture(
    String eventName, {
    Map<String, Object?>? properties,
  }) async {
    if (!isEnabled) return;
    try {
      final props = <String, Object>{};
      if (properties != null) {
        for (final e in properties.entries) {
          if (e.value != null) props[e.key] = e.value!;
        }
      }
      await Posthog().capture(
        eventName: eventName,
        properties: props.isEmpty ? null : props,
      );
    } catch (e) {
      debugPrint('⚠️ PostHog capture($eventName): $e');
    }
  }

  // ——— Convenience helpers ———

  Future<void> trackAuthMethodTapped(String method) => capture(
        AnalyticsEvents.authMethodTapped,
        properties: {'method': method},
      );

  Future<void> trackAuthCompleted({
    required String method,
    required int userId,
    String? credential,
    bool hasCompletedProfile = false,
    bool? isNewUser,
  }) async {
    await capture(
      AnalyticsEvents.authCompleted,
      properties: {
        'method': method,
        if (isNewUser != null) 'is_new_user': isNewUser,
      },
    );
    await aliasAndIdentifyUser(
      userId: userId,
      credential: credential,
      hasCompletedProfile: hasCompletedProfile,
      personProperties: {'auth_method': method},
    );
  }

  Future<void> trackAuthFailed({
    required String method,
    required String reason,
  }) =>
      capture(
        AnalyticsEvents.authFailed,
        properties: {
          'method': method,
          'reason': reason,
        },
      );

  Future<void> trackLoginStarted(String provider) => capture(
        AnalyticsEvents.loginStarted,
        properties: {'provider': provider},
      );

  Future<void> trackLoginCompleted({
    required String provider,
    required int userId,
    bool hasCompletedProfile = false,
  }) =>
      capture(
        AnalyticsEvents.loginCompleted,
        properties: {
          'provider': provider,
          'user_id': userId,
          'has_completed_profile': hasCompletedProfile,
        },
      );

  Future<void> trackLoginFailed(String provider, {String? reason}) =>
      capture(
        AnalyticsEvents.loginFailed,
        properties: {
          'provider': provider,
          if (reason != null) 'reason': reason,
        },
      );

  Future<void> trackPremiumTransition({
    required String userDistinctId,
    required bool wasPremium,
    required bool wasPurchased,
    required bool isPremium,
    required bool isPurchased,
    int? daysRemaining,
    String? source,
  }) async {
    await updatePersonProperties(userDistinctId, {
      'is_premium': isPremium,
      'is_purchased_premium': isPurchased,
      if (daysRemaining != null) 'premium_days_remaining': daysRemaining,
    });

    if (!wasPremium && isPremium && !isPurchased) {
      await capture(
        AnalyticsEvents.premiumTrialActivated,
        properties: {if (source != null) 'source': source},
      );
    } else if ((!wasPremium && isPremium && isPurchased) ||
        (wasPremium && isPremium && !wasPurchased && isPurchased)) {
      await capture(
        AnalyticsEvents.premiumPurchased,
        properties: {
          if (daysRemaining != null) 'days_remaining': daysRemaining,
          if (source != null) 'source': source,
        },
      );
    } else if (wasPremium && !isPremium) {
      await capture(
        AnalyticsEvents.premiumDeactivated,
        properties: {if (source != null) 'source': source},
      );
    }
  }
}
