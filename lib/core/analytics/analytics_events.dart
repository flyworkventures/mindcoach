/// PostHog event adları — `[object]_[verb]` formatı.
abstract final class AnalyticsEvents {
  // App lifecycle
  static const String appOpened = 'app_opened';
  static const String splashViewed = 'splash_viewed';
  static const String sessionRestored = 'session_restored';

  // Onboarding carousel (HTML funnel stage 02)
  static const String onboardingSlideViewed = 'onboarding_slide_viewed';
  static const String onboardingSwiped = 'onboarding_swiped';
  static const String onboardingCompleted = 'onboarding_completed';

  // Auth
  static const String loginStarted = 'login_started';
  static const String loginCompleted = 'login_completed';
  static const String loginFailed = 'login_failed';
  static const String logoutCompleted = 'logout_completed';
  static const String accountDeleted = 'account_deleted';

  // Navigation
  static const String tabSelected = 'tab_selected';

  // Premium
  static const String premiumTrialActivated = 'trial_activated';
  static const String premiumPurchased = 'premium_purchased';
  static const String premiumDeactivated = 'premium_deactivated';
  static const String paywallPresented = 'paywall_viewed';
  static const String paywallDismissed = 'paywall_dismissed';
  static const String subscriptionFailed = 'subscription_failed';

  // Coaches & appointments
  static const String coachDetailViewed = 'coach_profile_viewed';
  static const String appointmentSlotSelected = 'appointment_slot_selected';
  static const String appointmentCreated = 'appointment_created';
  static const String appointmentCreateFailed = 'appointment_create_failed';
  static const String appointmentCallStarted = 'appointment_call_started';

  // Calls
  static const String videoCallStarted = 'video_call_started';
  static const String videoCallEnded = 'video_call_ended';
  static const String voiceCallStarted = 'voice_call_started';
  static const String voiceCallEnded = 'voice_call_ended';

  // Chat
  static const String messageSent = 'message_sent';
  static const String conversationOpened = 'conversation_opened';

  // Tests & content
  static const String mentalTestStarted = 'mental_test_started';
  static const String mentalTestCompleted = 'mental_test_completed';
  static const String relaxingSoundPlayed = 'relaxing_sound_played';

  // Profile
  static const String profileSetupCompleted = 'profile_setup_completed';
  static const String languageChanged = 'language_changed';
}
