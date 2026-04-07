import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/auth/domain/social_login_provider.dart'
    show SocialLoginProvider;
import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/models/user_model.dart';

final onboardingController = StateNotifierProvider(
  (ref) => OnboardingController(ref),
);

class OnboardingController extends StateNotifier {
  Ref? ref;
  OnboardingController(this.ref) : super(0);

  List<String> pages = [
    'assets/chars/char0.jpg',
    'assets/chars/char1.jpg',
    'assets/chars/char2.jpg',
  ];

  Future<void> login(SocialLoginProvider provider, BuildContext context) async {
    try {
      debugPrint('🚀 [AUTH-CONTROLLER] Login başlatılıyor: ${provider.name}');
      if (provider == SocialLoginProvider.facebook) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook Login is not active now")),
        );
      } else {
        UserModel? userModel = await ref
            ?.read(AllProviders.authProvider.notifier)
            .login(provider);
        if (userModel != null) {
          debugPrint('UserProvider\'dan alındı: ${userModel.id}');
          ref?.read(AllProviders.userProvider.notifier).setUserModel(userModel);
          final hasCompletedProfile = userModel.answerData != null;
          if (userModel.credential == "guest") {
            await navigatorKey.currentState?.pushNamedAndRemoveUntil(
              PageRoutes.navbar,
              (a) => false,
            );
          } else {
            if (hasCompletedProfile) {
              await navigatorKey.currentState?.pushNamedAndRemoveUntil(
                PageRoutes.navbar,
                (a) => false,
              );
            } else {
              await navigatorKey.currentState?.pushNamedAndRemoveUntil(
                PageRoutes.profileSetup,
                (a) => false,
              );
            }
          }
        } else {
          debugPrint('User null');
        }
      }
    } catch (e, st) {
      debugPrint('❌ [AUTH-CONTROLLER] Login hatası: $e');
      debugPrint('❌ [AUTH-CONTROLLER] Stack trace: $st');

      state = AsyncError(e, st);
    }
  }
}
