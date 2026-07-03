import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/ApiService/premium_api_service.dart';
import 'package:mindcoach/core/utils/device_utils.dart';
import 'package:mindcoach/models/premium_state.dart';

/// Premium durumunu backend (source-of-truth) ile yeniden senkronize eder.
///
/// Uygulama ön plana geldiğinde (resume) çağrılır: kullanıcı uygulamayı açık
/// tutarken abonelik süresi dolduysa / iptal edildiyse (ör. deneme bitip ödeme
/// alınamadı) premium durumu burada güncellenir. Ayrıca RevenueCat'ten mevcut
/// entitlement'ları tazeler; yeni bir satın alma varsa app-wide listener yakalar.
///
/// Best-effort: ağ hatasında sessizce çıkar, mevcut state korunur.
Future<void> syncPremiumFromBackend(WidgetRef ref) async {
  try {
    final deviceId = await DeviceUtils.getDeviceId();
    final userId = ref.read(AllProviders.userProvider)?.id;

    // RevenueCat cache'ini tazele. Değişiklik varsa app-wide CustomerInfo
    // listener otomatik tetiklenir (yeni satın alma / restore burada yakalanır).
    try {
      await Purchases.getCustomerInfo();
    } catch (_) {
      // RevenueCat yapılandırılmamışsa / offline ise yut.
    }

    final data = await PremiumApiService().getDevicePremiumStatus(
      deviceId: deviceId,
      userId: userId,
    );

    if (data['success'] != true) return;

    final notifier = ref.read(AllProviders.premiumProvider.notifier);

    if (data['isPremium'] == true && data['expiryDate'] != null) {
      final expiryDate = DateTime.tryParse(data['expiryDate'] as String);
      if (expiryDate == null) return;
      notifier.setPremiumState(
        PremiumState(
          isPremium: true,
          expiryDate: expiryDate,
          deviceId: deviceId,
          isPurchased: data['planId'] != 'trial',
          daysRemaining: (data['daysRemaining'] as num?)?.toInt() ?? 0,
        ),
      );
      debugPrint('🔄 Resume sync: premium aktif (days=${data['daysRemaining']}).');
    } else if (data['isPremium'] == false) {
      // Backend "premium yok" diyor. Sadece local'de premium görünüyorsa temizle.
      final current = ref.read(AllProviders.premiumProvider);
      if (current.isPremium) {
        await notifier.deactivatePremium();
        debugPrint('🔄 Resume sync: premium süresi dolmuş, local temizlendi.');
      }
    }
  } catch (e) {
    debugPrint('⚠️ Resume premium sync başarısız (non-blocking): $e');
  }
}
