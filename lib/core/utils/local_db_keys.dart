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
  // 20 mesaj + 3 dk (180 sn) sesli arama. Premium kullanıcılar için anlamsız.
  static String trialMessagesUsed = "trialMessagesUsed";
  static String trialVoiceSecondsUsed = "trialVoiceSecondsUsed";
  /// Ücretsiz görüntülü deneme: toplam en fazla 60 sn (cihaz başına, non-premium).
  static String trialVideoSecondsUsed = "trialVideoSecondsUsed";
}
