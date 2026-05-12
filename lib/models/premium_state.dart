/// `copyWith` içinde "argüman verilmedi" ile "null geçildi"yi ayırt etmek için sentinel.
const Object _unsetExpiry = Object();

/// Premium durumunu temsil eden model
class PremiumState {
  /// Kullanıcı premium mi (trial + purchased combined)
  final bool isPremium;

  /// Premium süresi ne zaman bitiyor (null = no premium)
  final DateTime? expiryDate;

  /// Cihaza özgü UUID (account switch'te değişmez)
  final String deviceId;

  /// Kullanıcı satın almış mı (true) yoksa trial (false)
  final bool isPurchased;

  /// Kalan gün sayısı (0 = expired)
  final int daysRemaining;

  const PremiumState({
    required this.isPremium,
    required this.expiryDate,
    required this.deviceId,
    required this.isPurchased,
    required this.daysRemaining,
  });

  /// Factory constructor varsayılan değerler ile (premium yok)
  factory PremiumState.initial({required String deviceId}) {
    return PremiumState(
      isPremium: false,
      expiryDate: null,
      deviceId: deviceId,
      isPurchased: false,
      daysRemaining: 0,
    );
  }

  /// Trial premium state (3 günlük)
  factory PremiumState.trial({required String deviceId}) {
    final expiryDate = DateTime.now().add(const Duration(days: 3));
    return PremiumState(
      isPremium: true,
      expiryDate: expiryDate,
      deviceId: deviceId,
      isPurchased: false,
      daysRemaining: 3,
    );
  }

  /// Purchased premium state (1 yıllık)
  factory PremiumState.purchased({required String deviceId}) {
    final expiryDate = DateTime.now().add(const Duration(days: 365));
    return PremiumState(
      isPremium: true,
      expiryDate: expiryDate,
      deviceId: deviceId,
      isPurchased: true,
      daysRemaining: 365,
    );
  }

  /// Kopyala ve birkaç değeri değiştir.
  /// NOT: `expiryDate` için sentinel default kullanıldı — explicit `null` geçildiğinde
  /// expiry temizlenebilir (default davranış: mevcut değeri koru).
  PremiumState copyWith({
    bool? isPremium,
    Object? expiryDate = _unsetExpiry,
    String? deviceId,
    bool? isPurchased,
    int? daysRemaining,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      expiryDate: identical(expiryDate, _unsetExpiry)
          ? this.expiryDate
          : expiryDate as DateTime?,
      deviceId: deviceId ?? this.deviceId,
      isPurchased: isPurchased ?? this.isPurchased,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }

  @override
  String toString() =>
      'PremiumState(isPremium: $isPremium, days: $daysRemaining, purchased: $isPurchased)';
}
