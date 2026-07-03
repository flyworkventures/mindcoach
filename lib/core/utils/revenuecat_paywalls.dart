import 'package:flutter/material.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat dashboard offering ID'leri (Paywall ↔ Offering eşlemesi).
abstract final class RevenueCatOfferings {
  static const String proOffers = 'pro_offers';
  static const String discount = 'discount';
}

/// Premium satın alma akışının tek giriş noktası.
///
/// Guest kullanıcı premium satın almaya çalışırsa: önce bir dialog gösterip
/// Google/Apple ile giriş yapması istenir. Kullanıcı kabul ederse
/// [LocalDbKeys.pendingPaywallAfterLogin] işaretlenir ve Login ekranına
/// yönlendirilir. Giriş başarıyla tamamlandığında (LoginView), paywall otomatik
/// olarak açılır. Guest değilse paywall doğrudan gösterilir.
Future<void> presentPaywallForUser(
  BuildContext context, {
  required bool isGuest,
  Future<void> Function() paywall = presentProOffersPaywall,
}) async {
  if (!isGuest) {
    await paywall();
    return;
  }

  final l10n = context.l10n;
  final proceed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.guestPremiumRequiredTitle,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        content: Text(
          l10n.guestPremiumRequiredMessage,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF3B3D40),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                color: Color(0xFF96989C),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21BC87),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.guestPremiumSignInAction,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (proceed != true) return;

  await LocalDbService().setBool(
    key: LocalDbKeys.pendingPaywallAfterLogin,
    value: true,
  );

  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
    PageRoutes.login,
    (route) => false,
  );
}

/// Hesap silme akışı ve benzeri yerlerden belirli paywall'ları açmak için.
Future<void> presentProOffersPaywall() async {
  await AnalyticsService.instance.capture(
    AnalyticsEvents.paywallPresented,
    properties: {'offering_id': RevenueCatOfferings.proOffers},
  );
  try {
    final offerings = await Purchases.getOfferings();
    final offering =
        offerings.getOffering(RevenueCatOfferings.proOffers) ??
        offerings.current;
    await RevenueCatUI.presentPaywall(offering: offering);
  } catch (e, st) {
    debugPrint('presentProOffersPaywall: $e\n$st');
    await AnalyticsService.instance.capture(
      AnalyticsEvents.subscriptionFailed,
      properties: {
        'offering_id': RevenueCatOfferings.proOffers,
        'error': e.toString(),
      },
    );
    await RevenueCatUI.presentPaywall();
  } finally {
    await AnalyticsService.instance.capture(
      AnalyticsEvents.paywallDismissed,
      properties: {'offering_id': RevenueCatOfferings.proOffers},
    );
  }
}

Future<void> presentDiscountPaywall() async {
  await AnalyticsService.instance.capture(
    AnalyticsEvents.paywallPresented,
    properties: {'offering_id': RevenueCatOfferings.discount},
  );
  try {
    final offerings = await Purchases.getOfferings();
    final offering = offerings.getOffering(RevenueCatOfferings.discount);
    if (offering != null) {
      await RevenueCatUI.presentPaywall(offering: offering);
    } else {
      await RevenueCatUI.presentPaywall();
    }
  } catch (e, st) {
    debugPrint('presentDiscountPaywall: $e\n$st');
    await AnalyticsService.instance.capture(
      AnalyticsEvents.subscriptionFailed,
      properties: {
        'offering_id': RevenueCatOfferings.discount,
        'error': e.toString(),
      },
    );
    await RevenueCatUI.presentPaywall();
  } finally {
    await AnalyticsService.instance.capture(
      AnalyticsEvents.paywallDismissed,
      properties: {'offering_id': RevenueCatOfferings.discount},
    );
  }
}
