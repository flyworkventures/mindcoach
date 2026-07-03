import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/app/navbar_provider.dart';
import 'package:mindcoach/core/routes/page_routes.dart';

/// Bildirim deep-link'lerini uygulama içi navigasyona çevirir.
///
/// Backend'in gönderdiği deep-link formatları (notificationCatalog):
///   home, appointments, session/{id}, chat/{id}, call/incoming/{id},
///   videocall/incoming/{id}, therapists/browse, therapists/category/{id},
///   analysis-test/intro, analysis-test/start, analysis-test/results/{id},
///   notifications, settings/subscription, settings/payment, settings/plans,
///   settings/security, settings/privacy, verify
class DeepLinkHandler {
  /// Bildirime tıklandığında çağrılır.
  static void handle(String? link, {int retry = 0}) {
    if (link == null || link.trim().isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      // Navigator/Splash henüz hazır değilse kısa bir gecikmeyle tekrar dene.
      if (retry >= 10) return;
      Future.delayed(const Duration(milliseconds: 400), () {
        handle(link, retry: retry + 1);
      });
      return;
    }

    final path = link.replaceAll(RegExp(r'^/+'), '').trim();
    final segments = path.split('/');
    final root = segments.isNotEmpty ? segments[0].toLowerCase() : '';
    final sub = segments.length > 1 ? segments[1].toLowerCase() : '';

    switch (root) {
      case 'home':
        _goTab(context, 0);
        break;

      case 'therapists': // browse / category/{id}
        _goTab(context, 1);
        break;

      case 'appointments':
      case 'session': // planlanmış seans → takvim
        _goTab(context, 2);
        break;

      case 'chat':
      case 'call': // gelen arama altyapısı henüz yok → sohbet sekmesi
      case 'videocall':
        _goTab(context, 3);
        break;

      case 'notifications':
        _push(context, PageRoutes.notifications);
        break;

      case 'settings':
        // subscription/payment/plans/security/privacy → profil ayarları
        _push(context, PageRoutes.profileSettings);
        break;

      case 'analysis-test':
        if (sub == 'start') {
          _push(context, PageRoutes.testQuestionScreen);
        } else {
          // intro ve results → tanıtım ekranı (results ekranı ayrı argüman ister)
          _push(context, PageRoutes.testIntroScreen);
        }
        break;

      case 'verify':
      default:
        _goTab(context, 0);
        break;
    }
  }

  static void _goTab(BuildContext context, int index) {
    // Üstteki ekranları kapatıp ana kabuğa (navbar) dön.
    Navigator.of(context).popUntil((route) => route.isFirst);
    try {
      ProviderScope.containerOf(context, listen: false)
          .read(bottomNavProvider.notifier)
          .setTab(index);
    } catch (_) {
      // ProviderScope bulunamazsa sessiz geç.
    }
  }

  static void _push(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }
}
