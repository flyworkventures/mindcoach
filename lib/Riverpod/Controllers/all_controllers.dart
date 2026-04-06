import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Enums/page_state.dart';
import 'package:mindcoach/Riverpod/Controllers/HomeController/home_controller.dart';
import 'package:mindcoach/Riverpod/Controllers/ProfileSettingsController/profile_settings_controller.dart';
import 'package:mindcoach/Riverpod/Controllers/ProfileSetupController/profile_setup_controller.dart';
import 'package:mindcoach/Riverpod/Controllers/SplashController/splash_controller.dart';
import 'package:mindcoach/Riverpod/Controllers/VideoController/video_controller.dart';
import 'package:mindcoach/Riverpod/controllers/OnboardController/onboarding_controller.dart';

class AllControllers {
  static final onboardController = StateNotifierProvider((ref)=> OnboardingController(ref));
  static final splashController = StateNotifierProvider((ref)=> SplashController(ref));
  static final profileSetupProvider = StateNotifierProvider<ProfileSetupController, ProfileSetupState>((ref)=> ProfileSetupController(ref));
  static final pageSettingsController = StateNotifierProvider<ProfileSettingsController, PageState>((ref)=> ProfileSettingsController(ref));
  static final videoCallController = StateNotifierProvider((ref)=> VideoController(ref));
  static final homeController = StateNotifierProvider((ref)=> HomeController(ref));

}