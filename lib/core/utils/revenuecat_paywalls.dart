import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat dashboard offering ID'leri (Paywall ↔ Offering eşlemesi).
abstract final class RevenueCatOfferings {
  static const String proOffers = 'pro_offers';
  static const String discount = 'discount';
}

/// Hesap silme akışı ve benzeri yerlerden belirli paywall'ları açmak için.
Future<void> presentProOffersPaywall() async {
  try {
    final offerings = await Purchases.getOfferings();
    final offering =
        offerings.getOffering(RevenueCatOfferings.proOffers) ??
        offerings.current;
    await RevenueCatUI.presentPaywall(offering: offering);
  } catch (e, st) {
    debugPrint('presentProOffersPaywall: $e\n$st');
    await RevenueCatUI.presentPaywall();
  }
}

Future<void> presentDiscountPaywall() async {
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
    await RevenueCatUI.presentPaywall();
  }
}
