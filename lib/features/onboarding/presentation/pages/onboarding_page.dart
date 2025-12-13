import 'dart:async';

import 'package:cross_fade/cross_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_status_notifier.dart';
import '../../../../core/utils/locale_font_scaler.dart';
import '../../../../core/utils/screen_size_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/social_login_provider.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../profile_setup/presentation/pages/profile_setup_page.dart';
import '../../onboarding_data.dart';
import '../../onboarding_localizations.dart';
import '../widgets/onboarding_page_indicator.dart';
import '../widgets/onboarding_social_buttons.dart';
import '../widgets/onboarding_terms_text.dart';

/// OnboardingScreen
/// ------------------------------------------------------------
/// Pazarlama/onboarding ekranı:
/// - Görsel + metin döngüsü (auto-advance)
/// - Sosyal login tetikleyici
/// - Terms / Privacy / Cookies linkleri
///
/// ⚠️ ÖNEMLİ:
/// - UI katmanı Fake DB / DataSource bilmez.
/// - Login sadece AuthController üzerinden yapılır.
/// - Backend (N8N) gelince burada tek satır değişmez.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentIndex = 0;
  Timer? _autoTimer;

  final List<Alignment> _imageAlignments = const [
    Alignment.topCenter,
    Alignment.topCenter,
    Alignment(0, -2.6),
  ];

  final List<String> _pages = OnboardingData.pages;

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _currentIndex = (_currentIndex + 1) % _pages.length);
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSocialLogin(SocialLoginProvider provider) async {
    // UI -> Controller (data layer'a dokunma yok)
    await ref.read(authControllerProvider.notifier).login(provider);

    if (!mounted) return;

    // login oldu -> sıradaki ekran profile setup
    ref.read(appStatusProvider.notifier).goToProfileSetup();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;
    final isAndroid = platform == TargetPlatform.android;

    final titles = l.onboardingTitles;
    final descriptions = l.onboardingDescriptions;

    final descSize = LocaleFontScaler.scale(context, 14);
    final termsSize = LocaleFontScaler.scale(context, 10);
    final isGerman = Localizations.localeOf(context).languageCode == 'de';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: -45,
            right: -25,
            width: MediaQuery.of(context).size.width + 25,
            child: SizedBox(
              height: 877.h,
              child: CrossFade<int>(
                value: _currentIndex,
                duration: const Duration(milliseconds: 800),
                builder: (context, index) {
                  return Align(
                    alignment: _imageAlignments[index],
                    child: Image.asset(
                      _pages[index],
                      width: MediaQuery.of(context).size.width + 25,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 380.h,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      OnboardingPageIndicator(
                        itemCount: _pages.length,
                        currentIndex: _currentIndex,
                      ),

                      Expanded(
                        child: Align(
                          alignment: const Alignment(0.0, -0.5),
                          child: CrossFade<int>(
                            value: _currentIndex,
                            duration: const Duration(milliseconds: 800),
                            builder: (context, index) {
                              return Column(
                                key: ValueKey(index),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 8,
                                      bottom: 12,
                                      top: 10,
                                    ),
                                    child: Text(
                                      titles[index],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.quicksand(
                                        fontSize: isGerman ? 22 : 24,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1D1D1D),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12,
                                      left: 8,
                                      right: 8,
                                    ),
                                    child: Text(
                                      descriptions[index],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w400,
                                        fontSize: descSize,
                                        height: 1.4,
                                        color: const Color(0xFF1D1D1D),
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      OnboardingSocialButtons(
                        isIOS: isIOS,
                        isAndroid: isAndroid,
                        onLogin: _handleSocialLogin,
                      ),

                      SizedBox(height: 28.h),

                      OnboardingTermsText(
                        fontSize: termsSize,
                        isGerman: isGerman,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
