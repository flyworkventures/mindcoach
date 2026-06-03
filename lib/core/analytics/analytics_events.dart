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

  // Auth (legacy — prefer auth* funnel events below)
  static const String loginStarted = 'login_started';
  static const String loginCompleted = 'login_completed';
  static const String loginFailed = 'login_failed';

  // Auth funnel (HTML stage 09)
  static const String authScreenViewed = 'auth_screen_viewed';
  static const String authMethodTapped = 'auth_method_tapped';
  static const String authCompleted = 'auth_completed';
  static const String authFailed = 'auth_failed';

  // Profile setup funnel (HTML stage 03)
  static const String profileStepViewed = 'profile_step_viewed';
  static const String profileStepCompleted = 'profile_step_completed';
  static const String profileBackTapped = 'profile_back_tapped';
  static const String profileCompleted = 'profile_completed';

  // Coach matching (HTML stage 04)
  static const String coachMatchesViewed = 'coach_matches_viewed';
  static const String coachCardSwiped = 'coach_card_swiped';
  static const String coachSkipped = 'coach_skipped';
  static const String coachBookTapped = 'coach_book_tapped';

  // Demo + premium offer (HTML stage 06–07)
  static const String demoSessionCompleted = 'demo_session_completed';
  static const String premiumOfferViewed = 'premium_offer_viewed';
  static const String premiumPurchaseTapped = 'premium_purchase_tapped';
  static const String continueFreeTapped = 'continue_free_tapped';
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
