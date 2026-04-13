import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/OnboardView/presentation/widgets/onboarding_terms_text.dart';
import 'package:mindcoach/View/auth/domain/social_login_provider.dart';
import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/models/user_model.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  // Sadece ilgili butonda yükleme göstermek için null veya ilgili provider'ı tutacağız
  SocialLoginProvider? _loadingProvider;

  Future<void> _handleLogin(SocialLoginProvider provider) async {
    // Farklı bir işlem zaten devam ediyorsa tetiklenmeyi engelle
    if (_loadingProvider != null) return;

    setState(() => _loadingProvider = provider);

    try {
      // 1. Social login
      debugPrint('[LoginView] Login baslatiliyor: ${provider.name}');
      final UserModel? userModel = await ref
          .read(AllProviders.authProvider.notifier)
          .login(provider);

      if (userModel == null || !mounted) {
        debugPrint('[LoginView] Login basarisiz veya widget dispose edildi');
        if (mounted) setState(() => _loadingProvider = null);
        return;
      }

      debugPrint('[LoginView] Login basarili: id=${userModel.id}, '
          'username=${userModel.username}, '
          'answerData=${userModel.answerData != null}');

      // 2. Guest kullanicilari icin profil tamamlamaya gerek yok
      if (provider == SocialLoginProvider.guest) {
        debugPrint('[LoginView] Guest kullanici → navbar');
        _navigateToNavbar();
        return;
      }

      // 3. Profil zaten tamamlanmissa direkt anasayfaya git
      if (userModel.answerData != null) {
        debugPrint('[LoginView] Profil zaten tamamlanmis → navbar');
        _navigateToNavbar();
        return;
      }

      // 4. Onboarding sorularindaki cevaplari backend'e gonder
      debugPrint('[LoginView] Profil tamamlaniyor...');
      final profileState = ref.read(AllControllers.profileSetupProvider);
      debugPrint('[LoginView] ProfileState: '
          'fullName="${profileState.fullName}", '
          'gender=${profileState.gender}, '
          'supportArea=${profileState.supportArea}');

      await _completeProfileWithStoredData();
      debugPrint('[LoginView] Profil tamamlandi → navbar');

      // 5. Anasayfaya yonlendir
      _navigateToNavbar();
    } catch (e, st) {
      debugPrint('[LoginView] Login hatasi: $e');
      debugPrint('[LoginView] Stack trace: $st');
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  Future<void> _completeProfileWithStoredData() async {
    // Profil verileri zaten Riverpod state'inde tutuluyor
    // (onboarding sorularindan), direkt backend'e gonder
    await ref
        .read(AllControllers.profileSetupProvider.notifier)
        .completeProfile();
  }

  void _navigateToNavbar() {
    if (!mounted) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      PageRoutes.navbar,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isIOS = Platform.isIOS;
    final locale = Localizations.localeOf(context);
    final isGerman = locale.languageCode == 'de';

    // Platforma göre butonların hangi provider'a denk geleceğini belirliyoruz
    final topProvider = isIOS
        ? SocialLoginProvider.apple
        : SocialLoginProvider.google;
    final bottomProvider = isIOS
        ? SocialLoginProvider.google
        : SocialLoginProvider.apple;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // -- Ust kisim: SVG illustrasyon --
            Expanded(
              flex: 5,
              child: Center(
                child: SvgPicture.asset('assets/icons/login_icon.svg'),
              ),
            ),

            // -- Alt kisim: Icerik --
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome
                    Text(
                      l.welcome,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      l.loginSubtitle,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF96989C),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Platform'a gore buton sirasi: iOS → Apple ust, Android → Google ust
                    _LoginButton(
                      label: isIOS ? l.continueWithApple : l.continueWithGoogle,
                      icon: isIOS
                          ? SvgPicture.asset('assets/icons/ic_apple.svg')
                          : SvgPicture.asset('assets/icons/ic_google.svg'),
                      backgroundColor: isIOS ? Colors.black : Colors.white,
                      textColor: isIOS ? Colors.white : Colors.black,
                      borderColor: isIOS ? null : const Color(0xFFB8B8B8),
                      isLoading: _loadingProvider == topProvider,
                      isDisabled: _loadingProvider != null,
                      onPressed: () => _handleLogin(topProvider),
                    ),
                    const SizedBox(height: 16),

                    _LoginButton(
                      label: isIOS ? l.continueWithGoogle : l.continueWithApple,
                      icon: isIOS
                          ? SvgPicture.asset('assets/icons/ic_google.svg')
                          : SvgPicture.asset('assets/icons/ic_apple.svg'),
                      backgroundColor: isIOS ? Colors.white : Colors.black,
                      textColor: isIOS ? Colors.black : Colors.white,
                      borderColor: isIOS ? const Color(0xFFB8B8B8) : null,
                      isLoading: _loadingProvider == bottomProvider,
                      isDisabled: _loadingProvider != null,
                      onPressed: () => _handleLogin(bottomProvider),
                    ),
                    const SizedBox(height: 16),

                    // -- Continue as Guest --
                    Center(
                      child: GestureDetector(
                        onTap: _loadingProvider != null
                            ? null
                            : () => _handleLogin(SocialLoginProvider.guest),
                        child: _loadingProvider == SocialLoginProvider.guest
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF96989C),
                                ),
                              )
                            : Text(
                                l.continueAsGuest,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF96989C),
                                  height: 1.0,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // -- Privacy notice --
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("🔒", style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l.dataPrivacyNotice,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF96989C),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // -- Terms text --
                    Center(
                      child: OnboardingTermsText(
                        fontSize: 10,
                        isGerman: isGerman,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Login Button
// ============================================================================

class _LoginButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: OutlinedButton(
        // İşlem sürüyorsa butonu tıklanmaz yap
        onPressed: isDisabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? Colors.transparent, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    MainAxisSize.min, // İkon ve metni yapışık, merkeze hizalar
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        height: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
