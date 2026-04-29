import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/ProfileSetupView/steps/available_days_step.dart';
import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import '../../../core/theme/profile_setup_typography.dart';
import 'animated_flowgradient.dart';
import 'steps/approach_step.dart';
import 'steps/meeting_time_step.dart';
import 'steps/name_gender_step.dart';
import 'steps/support_area_step.dart';

// ============================================================================
// 1. ANA SAYFA (ONBOARDING)
// ============================================================================

class MindCoachOnboarding extends ConsumerStatefulWidget {
  const MindCoachOnboarding({super.key});

  @override
  ConsumerState<MindCoachOnboarding> createState() =>
      _MindCoachOnboardingState();
}

class _MindCoachOnboardingState extends ConsumerState<MindCoachOnboarding> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  // Ekran sayısı (success yok, login sayfasına yönlendirilecek)
  final int _totalSteps = 5;

  void _goNext() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      debugPrint(_currentPage.toString());
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      log(
        "Username and Token: ${ref.read(AllProviders.userProvider)?.credential}, ${ref.read(AllProviders.userProvider)?.token}. ",
      );
      ref.read(AllControllers.profileSetupProvider.notifier).initFromUser();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Mevcut adımın validasyonunun sağlanıp sağlanmadığını kontrol eder.
  bool _isStepValid(dynamic profileState) {
    switch (_currentPage) {
      case 0:
        return profileState.fullName.trim().isNotEmpty;
      case 1:
        return profileState.supportArea != null;
      case 2:
        return profileState.approach != null;
      case 3:
        return (profileState.availableDays as List).isNotEmpty;
      case 4:
        return profileState.meetingTime != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(AllControllers.profileSetupProvider);
    final l = context.l10n;
    final int stepCount = _totalSteps;
    final bool canProceed = _isStepValid(profileState);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ---------------- Üst %40 – Animasyon Alanı ----------------
          const Expanded(
            flex: 4,
            child: Center(child: AnimatedFlowBackground()),
          ),

          // ---------------- Alt %60 – İçerik Alanı ----------------
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  // -- Üst Bar (Back + Progress + Step) --
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      height: 28.h,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _currentPage == 0 ? null : _goBack,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: _currentPage == 0
                                      ? const Color(0xFFCACACA)
                                      : const Color(0xFF96989C),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l.back,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: _currentPage == 0
                                        ? const Color(0xFFCACACA)
                                        : const Color(0xFF96989C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _OnboardingProgressBar(
                              currentPage: _currentPage,
                              totalSteps: stepCount,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l.stepOf(_currentPage + 1, stepCount),
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF21BC87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -- İçerik (PageView) --
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) {
                        setState(() {
                          _currentPage = i;
                        });
                      },
                      children: [
                        NameGenderStep(
                          fullName: profileState.fullName,
                          onFullNameChanged: (name) {
                            ref
                                .read(
                                  AllControllers.profileSetupProvider.notifier,
                                )
                                .setFullName(name);
                          },
                          gender: profileState.gender,
                          onGenderChanged: (g) {
                            ref
                                .read(
                                  AllControllers.profileSetupProvider.notifier,
                                )
                                .setGender(g);
                          },
                          titleStyle: ProfileSetupTypography.title(context),
                          subtitleStyle: ProfileSetupTypography.subtitle(
                            context,
                          ),
                        ),
                        SupportAreaStep(
                          selectedSupportArea: profileState.supportArea,
                          onSupportAreaChanged: (area) {
                            ref
                                .read(
                                  AllControllers.profileSetupProvider.notifier,
                                )
                                .setSupportArea(area);
                          },
                          titleStyle: ProfileSetupTypography.title(context),
                          subtitleStyle: ProfileSetupTypography.subtitle(
                            context,
                          ),
                        ),
                        ApproachStep(
                          selectedApproach: profileState.approach,
                          onApproachChanged: (value) {
                            ref
                                .read(
                                  AllControllers.profileSetupProvider.notifier,
                                )
                                .setApproach(value);
                          },
                          titleStyle: ProfileSetupTypography.title(context),
                          subtitleStyle: ProfileSetupTypography.subtitle(
                            context,
                          ),
                        ),
                        AvailableDaysStep(
                          availableDays: profileState.availableDays,
                          onToggleDay: (day) {
                            ref
                                .read(
                                  AllControllers.profileSetupProvider.notifier,
                                )
                                .toggleDay(day);
                          },
                          titleStyle: ProfileSetupTypography.title(context),
                          subtitleStyle: ProfileSetupTypography.subtitle(
                            context,
                          ),
                        ),
                        MeetingTimeStep(
                          selectedTime: profileState.meetingTime,
                          onTimeChanged: (t) {
                            ref
                                .read(
                                  AllControllers.profileSetupProvider.notifier,
                                )
                                .setMeetingTime(t);
                          },
                          titleStyle: ProfileSetupTypography.title(context),
                          subtitleStyle: ProfileSetupTypography.subtitle(
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -- Alt Buton --
                  Padding(
                    padding: EdgeInsets.only(
                      top: 12,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: _BottomPrimaryButton(
                      isLast: _currentPage == stepCount - 1,
                      isEnabled: canProceed,
                      onPressed: () async {
                        if (!canProceed) return;

                        if (_currentPage == stepCount - 1) {
                          navigatorKey.currentState?.pushNamed(
                            PageRoutes.findCoach,
                          );
                          return;
                        }

                        _goNext();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. YENİ PROGRESS BAR TASARIMI (Tek parça kesintisiz)
// ============================================================================

class _OnboardingProgressBar extends StatelessWidget {
  final int currentPage;
  final int totalSteps;

  const _OnboardingProgressBar({
    required this.currentPage,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    double progressFraction = (currentPage + 1) / totalSteps;

    return Container(
      height: 9, // Figma Height: 9px
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(99), // Figma Radius: 99px
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: constraints.maxWidth * progressFraction,
              decoration: BoxDecoration(
                color: const Color(0xFF21BC87),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 3. YENİ ALT BUTON TASARIMI
// ============================================================================
class _BottomPrimaryButton extends StatelessWidget {
  final bool isLast;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _BottomPrimaryButton({
    required this.isLast,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Sadece isEnabled true olduğunda Figma'daki gölgeyi ekliyoruz
        boxShadow: isEnabled
            ? [
                const BoxShadow(
                  color: Color(0xFF21BC87),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, 0),
                ),
              ]
            : null, // isEnabled false ise gölge yok
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF21BC87),
          disabledBackgroundColor: const Color(0x4D21BC87), // %30 opacity
          shadowColor: Colors
              .transparent, // Butonun kendi default gölgesini kapatıyoruz ki çakışmasın
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast ? l.findMyCoaches : l.next,
              style: GoogleFonts.quicksand(
                fontSize: 18.w,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : const Color(0xFF21BC87),
              ),
            ),
            if (isLast) ...[
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/ic_rightArrow.svg',
                colorFilter: ColorFilter.mode(
                  isLast ? Colors.white : const Color(0xFF21BC87),
                  BlendMode.srcIn,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
