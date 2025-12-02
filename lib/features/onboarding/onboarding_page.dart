import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/features/onboarding/profile_setup/profile_setup_page.dart';
import '../../core/routes/page_routes.dart';
import '../../core/utils/policies_utils.dart';
import '../../core/utils/screen_size_extensions.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding_data.dart';
import 'onboarding_localizations.dart';
import 'social_button.dart';
import 'onboarding_persona.dart';
import 'package:cross_fade/cross_fade.dart';
import 'dart:io';
import 'package:mindcoach/data/fake_user_db.dart';
import 'legal_document/legal_doc_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final isIOS = Platform.isIOS;
  final isAndroid = Platform.isAndroid;


  final List<Alignment> _imageAlignments = const [
    Alignment.topCenter,
    Alignment.topCenter,
    Alignment(0, -2.6), // 3. görsel: hafif alta hizalanmış, kişiyi yukarı iter
  ];

  int _currentIndex = 0;
  final _pageController = PageController();
  Timer? _autoPageTimer;

  Future<void> _handleSocialLogin(SocialLoginProvider provider) async {
    await FakeUserDb.saveUser(provider);

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, PageRoutes.profileSetup);
  }

  final List<OnboardingPersona> _pages = OnboardingData.pages
      .map((path) => OnboardingPersona(imagePath: path))
      .toList();

  @override
  void initState() {
    super.initState();

    // Otomatik loop geçiş (4 saniyede bir).
    _autoPageTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _pages.length;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l = AppLocalizations.of(context)!;
    final isGerman = Localizations.localeOf(context).languageCode == 'de';


    // text listeler
    final titles = l.onboardingTitles;
    final descriptions = l.onboardingDescriptions;

    final termsTap = TapGestureRecognizer()
      ..onTap = () {
        final path = localizedMD("terms", context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LegalDocScreen(
              assetPath: path,
              title: l.onboardingTermsOfService,
            ),
          ),
        );
      };

    final privacyTap = TapGestureRecognizer()
      ..onTap = () {
        final path = localizedMD("privacy", context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LegalDocScreen(
              assetPath: path,
              title: l.onboardingPrivacyPolicy,
            ),
          ),
        );
      };

    final cookiesTap = TapGestureRecognizer()
      ..onTap = () {
        final path = localizedMD("cookies", context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LegalDocScreen(
              assetPath: path,
              title: l.onboardingCookiesPolicy,
            ),
          ),
        );
      };

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
              // width: double.infinity,
              child: CrossFade<int>(
                value: _currentIndex,
                duration: const Duration(milliseconds: 800),
                builder: (context, index) {
                  return Align(
                    alignment: _imageAlignments[index],
                    child: Image.asset(
                      _pages[index].imagePath,
                      // İçerideki resim de genişleyen alana uysun
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
                      // INDICATOR
                      PageIndicator(
                        itemCount: _pages.length,
                        currentIndex: _currentIndex,
                      ),

                      // TITLE + DESCRIPTION
                      Expanded(
                        child: Align(
                          alignment: const Alignment(0.0, -0.5),
                          child: CrossFade<int>(
                            value: _currentIndex,
                            duration: const Duration(milliseconds: 800),
                            builder: (context, index) {
                              final title = titles[index];
                              final description = descriptions[index];
                              return Column(
                                key: ValueKey(index),
                                mainAxisSize: MainAxisSize.min,
                                // Sadece içeriği kadar yer kaplasın, Expanded ortalar.
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      right: 8,
                                      bottom: 12,
                                      top: 10,
                                    ),
                                    child: Text(
                                      title,
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
                                      bottom: 12.0,
                                      left: 8,
                                      right: 8,
                                    ),
                                    child: Text(
                                      description,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.quicksand(
                                        fontWeight: FontWeight.w400,
                                        fontSize: isGerman ? 13 : 14,
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

                      // 🔹 SOSYAL LOGIN BUTONLARI (Artık sabit kalacak)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: 278.w,
                          child: isAndroid
                              ? SocialButton.google(
                                  onPressed: () {
                                    // _handleSocialLogin(
                                    //   SocialLoginProvider.google,
                                    // );
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => MindCoachOnboarding()));
                                  },
                                )
                              : SocialButton.apple(
                                  onPressed: () {
                                    // _handleSocialLogin(
                                    //   SocialLoginProvider.apple,
                                    // );
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => MindCoachOnboarding()));
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 136.61.w,
                              child: SocialButton.facebook(
                                onPressed: () {
                                  _handleSocialLogin(
                                    SocialLoginProvider.facebook,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 136.61.w,
                              child: isIOS
                                  ? SocialButton.google(
                                      onPressed: () {
                                        _handleSocialLogin(
                                          SocialLoginProvider.google,
                                        );
                                      },
                                    )
                                  : SocialButton.apple(
                                      onPressed: () {
                                        _handleSocialLogin(
                                          SocialLoginProvider.apple,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 28.h),

                      // 🔹 TERMS METNİ
                      SizedBox(
                        width: 320.w,
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: isGerman ? 9 : 10,
                              color: const Color(0xFF1D1D1D),
                              fontWeight: FontWeight.w400,
                              height: isGerman ? 1.3 : 1.5,
                            ),
                            children: [
                              TextSpan(text: l.onboardingTermsPrefix),
                              TextSpan(
                                text: l.onboardingTermsOfService,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: termsTap,
                              ),
                              TextSpan(text: l.onboardingTermsMiddle),
                              TextSpan(
                                text: l.onboardingPrivacyPolicy,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: privacyTap,
                              ),
                              TextSpan(text: l.onboardingTermsAnd),
                              TextSpan(
                                text: l.onboardingCookiesPolicy,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: cookiesTap,
                              ),
                              TextSpan(text: l.onboardingTermsSuffix),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
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
