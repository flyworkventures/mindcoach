import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppStatus {
  onboarding,
  profileSetup,
  authenticated,
  unauthenticated,
}

final appStatusProvider =
NotifierProvider<AppStatusNotifier, AppStatus>(AppStatusNotifier.new);

class AppStatusNotifier extends Notifier<AppStatus> {
  @override
  AppStatus build() {
    // Şimdilik default: onboarding
    // ilerde onboarding tamamlandı mı, profil setupı tamamlandı mı
    // token var mı kontrolleri
    return AppStatus.onboarding;
  }

  void setStatus(AppStatus newStatus) => state = newStatus;

  void goToOnboarding() => state = AppStatus.onboarding;
  void goToProfileSetup() => state = AppStatus.profileSetup;
  void goToAuthenticated() => state = AppStatus.authenticated;
  void goToUnauthenticated() => state = AppStatus.unauthenticated;

/// İLERİDE (n8n/auth geldiğinde):
/// Future<void> bootstrap() async { ... }
}
