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
}
