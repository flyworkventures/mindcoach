import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_status_notifier.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/profile_setup/presentation/pages/profile_setup_page.dart';
import 'navbar_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);

    switch (status) {
      case AppStatus.onboarding:
        return const OnboardingScreen();

      case AppStatus.profileSetup:
        return const MindCoachOnboarding();

      case AppStatus.authenticated:
        return const NavbarShell();

      case AppStatus.unauthenticated:
        // TODO: LoginScreen
        return const OnboardingScreen();
    }
  }
}
