class LocalDbKeys {
  static String token = "token";
  static String locale = "locale";
  static String appleFullName = "appleFullName"; // Apple'dan gelen fullName (geçici)
  static String onboardingSeen = "onboardingSeen"; // Onboarding bir kere gösterildi mi?
  static String savedUsername = "savedUsername"; // Profile'da kaydedilen username override
  static String profileSetupData = "profileSetupData"; // Onboarding'de toplanan profil verisi (login'e taşımak için)

  // Guest login — cihaza özgü sabit ID (bir kez oluşturulur, silinmez)
  static String guestDeviceId = "guestDeviceId";

  // Notification preferences
  static String notificationsEnabled = "notificationsEnabled";
  static String notificationStartTime = "notificationStartTime";
  static String notification2Hours = "notification2Hours";
  static String notification4Hours = "notification4Hours";
  static String notification8Hours = "notification8Hours";
  static String notification24Hours = "notification24Hours";

  // Premium deneme süresi sayaçları (cihaz başına; non-premium kullanıcı için)
  // 10 mesaj yazılı chat'te (sonra premium gerekli). Sesli/video premium-only.
  static String trialMessagesUsed = "trialMessagesUsed";
  static String trialVoiceSecondsUsed = "trialVoiceSecondsUsed";
  /// Ücretsiz görüntülü deneme: toplam en fazla 60 sn (cihaz başına, non-premium).
  static String trialVideoSecondsUsed = "trialVideoSecondsUsed";

  // Premium sistemi (device-based, account-agnostic)
  /// Cihaza özgü sabit UUID (bir kez oluşturulur, silinmez)
  static String deviceIdPremium = "deviceIdPremium";
  /// Premium son kullanma tarihi (ISO 8601 string, null = premium yok)
  static String premiumExpiryDate = "premiumExpiryDate";
  /// Premium aktivasyon tarihi
  static String premiumStartDate = "premiumStartDate";
  /// Kullanıcı satın alma premium mi (true) yoksa trial (false)
  static String isPremiumPurchased = "isPremiumPurchased";
}
