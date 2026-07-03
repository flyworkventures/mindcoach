import 'package:flutter/material.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/services/current_route_observer.dart';
import 'package:mindcoach/core/services/deep_link_handler.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  Map<String, dynamic> _normalizeAdditionalData(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final metadata = raw['metadata'];
    if (metadata is Map) {
      return {...raw, ...Map<String, dynamic>.from(metadata)};
    }
    return Map<String, dynamic>.from(raw);
  }

  /// additionalData içinden deep-link'i güvenli çeker (üst seviye veya metadata).
  String? _extractDeepLink(Map<String, dynamic> normalized) {
    final dl = normalized['deepLink'] ?? normalized['deep_link'];
    if (dl is String && dl.trim().isNotEmpty) return dl.trim();
    return null;
  }

  /// Kullanıcı ilgili ekranda aktifken foreground push banner'ını bastır.
  bool _shouldSuppressForeground(Map<String, dynamic> normalized) {
    final type = normalized['type'] as String?;
    // Randevu bildirimleri zaten navbar in-app banner ile gösteriliyor → duplicate önle.
    if (type == 'appointment') return true;

    final deepLink = _extractDeepLink(normalized);
    final currentRoute = CurrentRouteObserver.currentRouteName;
    // Kullanıcı bir sohbet ekranındayken gelen sohbet mesajı push'unu bastır.
    if (deepLink != null &&
        deepLink.startsWith('chat') &&
        currentRoute == PageRoutes.conversationScreen) {
      return true;
    }
    return false;
  }

  Future initiializeOnesignal() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      OneSignal.initialize(AppConstants.onesignalId);
      debugPrint(
        '[ONESIGNAL] ✅ OneSignal initialized with App ID: ${AppConstants.onesignalId}',
      );

      final permissionGranted = await OneSignal.Notifications.requestPermission(
        true,
      );
      debugPrint('[ONESIGNAL] Permission granted: $permissionGranted');

      // İzin verildiyse cihazı push aboneliğine opt-in et. Bu yapılmazsa
      // backend "All included players are not subscribed" hatası alır ve
      // bildirim telefona düşmez.
      try {
        if (permissionGranted) {
          OneSignal.User.pushSubscription.optIn();
        }
      } catch (e) {
        debugPrint('[ONESIGNAL] optIn hatası: $e');
      }

      // Foreground notification listener - bildirim geldiğinde yakala
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final normalizedData =
            _normalizeAdditionalData(event.notification.additionalData);
        debugPrint(
          '[ONESIGNAL] 📬 Foreground: ${event.notification.title} | data=$normalizedData',
        );

        // Foreground suppression: kullanıcı ilgili ekranda aktifse gösterme.
        if (_shouldSuppressForeground(normalizedData)) {
          debugPrint('[ONESIGNAL] 🔕 Foreground suppression uygulandı');
          event.preventDefault();
          return;
        }
        // Aksi halde bildirimi göster.
        event.notification.display();
      });

      // Notification click listener → deep-link ile ilgili ekrana yönlendir
      OneSignal.Notifications.addClickListener((event) {
        final normalizedData =
            _normalizeAdditionalData(event.notification.additionalData);
        final deepLink = _extractDeepLink(normalizedData);
        debugPrint('[ONESIGNAL] 📱 Clicked → deepLink=$deepLink');
        if (deepLink != null) {
          DeepLinkHandler.handle(deepLink);
        }
      });

      debugPrint('[ONESIGNAL] ✅ OneSignal setup completed');
    } catch (e) {
      debugPrint('[ONESIGNAL] ❌ Initialization error: $e');
      rethrow;
    }
  }

  Future registerUser(String userId) async {
    try {
      await OneSignal.login(userId);
      debugPrint('[ONESIGNAL] User registered with External User ID: $userId');

      // login sonrası aboneliğin aktif olduğundan emin ol (opt-in). Kullanıcı
      // daha önce izin verdiyse bu, backend'in cihazı bulmasını garantiler.
      try {
        OneSignal.User.pushSubscription.optIn();
      } catch (e) {
        debugPrint('[ONESIGNAL] optIn (registerUser) hatası: $e');
      }

      try {
        final pushSubscriptionId = OneSignal.User.pushSubscription.id;
        final optedIn = OneSignal.User.pushSubscription.optedIn;
        debugPrint(
          '[ONESIGNAL] Push Subscription ID: $pushSubscriptionId | optedIn: $optedIn',
        );
      } catch (e) {
        debugPrint('[ONESIGNAL] Could not get push subscription ID: $e');
      }
    } catch (e) {
      debugPrint("[ONESIGNAL]  Error registering user: $e");
      rethrow;
    }
  }
}
