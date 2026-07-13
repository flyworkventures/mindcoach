import 'package:flutter_riverpod/legacy.dart';
import '../../models/premium_state.dart';
import '../../Services/LocalServices/local_db_service.dart';

/// Premium sistemi - device-based (account-agnostic)
class PremiumNotifier extends StateNotifier<PremiumState> {
  final LocalDbService _localDb = LocalDbService();

  PremiumNotifier(PremiumState initialState) : super(initialState);

  /// Dış servislerden premium state'i güncellemek için yardımcı metod
  void setPremiumState(PremiumState newState) {
    state = newState;
  }

  /// Premium trial'ı aktivat (3 gün).
  /// Cihaz başına sadece bir kez verilir — daha önce kullanılmışsa no-op.
  Future<void> activateTrialPremium() async {
    final hasUsedTrial = await _localDb.getHasUsedTrial();
    if (hasUsedTrial) {
      // Mevcut state'i değiştirmeden çık — trial yeniden verilmez.
      return;
    }

    final expiryDate = DateTime.now().add(const Duration(days: 3));

    await _localDb.setPremiumStartDate(DateTime.now());
    await _localDb.setPremiumExpiryDate(expiryDate);
    await _localDb.setIsPremiumPurchased(false);
    await _localDb.setHasUsedTrial(true);

    state = state.copyWith(
      isPremium: true,
      expiryDate: expiryDate,
      isPurchased: false,
      daysRemaining: 3,
    );
  }

  /// Store entitlement'ı aktive et (satın alma veya App Store introductory trial).
  /// [isPurchased] false ise store denemesi / intro — upsell kartı görünür kalır.
  Future<void> activateStorePremium({
    DateTime? expiryDate,
    bool isPurchased = true,
  }) async {
    final effectiveExpiry =
        expiryDate ?? DateTime.now().add(const Duration(days: 365));
    final daysRemaining = effectiveExpiry.difference(DateTime.now()).inDays;

    await _localDb.setPremiumStartDate(DateTime.now());
    await _localDb.setPremiumExpiryDate(effectiveExpiry);
    await _localDb.setIsPremiumPurchased(isPurchased);

    state = state.copyWith(
      isPremium: true,
      expiryDate: effectiveExpiry,
      isPurchased: isPurchased,
      daysRemaining: daysRemaining < 0 ? 0 : daysRemaining,
    );
  }

  /// Purchased premium'ı aktivat.
  /// [expiryDate] verilirse onu kullanır (RevenueCat'ten gelen gerçek expiry),
  /// aksi halde 1 yıllık default.
  Future<void> activatePurchasedPremium({DateTime? expiryDate}) async {
    await activateStorePremium(expiryDate: expiryDate, isPurchased: true);
  }

  /// Backend / resume sync sonucunu hem Riverpod hem local DB'ye yazar.
  Future<void> applyBackendStatus({
    required bool isPremium,
    DateTime? expiryDate,
    required bool isPurchased,
    required int daysRemaining,
  }) async {
    if (!isPremium || expiryDate == null) {
      await deactivatePremium();
      return;
    }
    await _localDb.setPremiumExpiryDate(expiryDate);
    await _localDb.setIsPremiumPurchased(isPurchased);
    if (!isPurchased) {
      await _localDb.setHasUsedTrial(true);
    }
    state = state.copyWith(
      isPremium: true,
      expiryDate: expiryDate,
      isPurchased: isPurchased,
      daysRemaining: daysRemaining < 0 ? 0 : daysRemaining,
    );
  }

  /// Premium'ı tamamen kapat (backend "premium yok" derse veya expire olduysa).
  Future<void> deactivatePremium() async {
    await _localDb.clearPremiumStatus();
    state = state.copyWith(
      isPremium: false,
      expiryDate: null,
      isPurchased: false,
      daysRemaining: 0,
    );
  }

  /// Premium statusunu kontrol et (expiry validate)
  Future<void> checkPremiumStatus() async {
    final isActive = await _localDb.isPremiumActive();
    final expiryDate = await _localDb.getPremiumExpiryDate();
    final isPurchased = await _localDb.getIsPremiumPurchased();

    if (isActive && expiryDate != null) {
      final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
      state = state.copyWith(
        isPremium: true,
        expiryDate: expiryDate,
        isPurchased: isPurchased,
        daysRemaining: daysRemaining < 0 ? 0 : daysRemaining,
      );
    } else {
      // Premium expired, revert to free
      await _localDb.clearPremiumStatus();
      state = state.copyWith(
        isPremium: false,
        expiryDate: null,
        isPurchased: false,
        daysRemaining: 0,
      );
    }
  }

  /// Premium günlerini döndür
  int getPremiumDaysRemaining() {
    if (!state.isPremium || state.expiryDate == null) return 0;
    final daysRemaining = state.expiryDate!.difference(DateTime.now()).inDays;
    return daysRemaining < 0 ? 0 : daysRemaining;
  }
}

/// Premium provider - device-based state management
final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  // Initial state will be set by app initialization
  return PremiumNotifier(
    PremiumState.initial(deviceId: 'loading'),
  );
});