import 'dart:async';
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
import 'steps/success_step.dart';
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

  // Ekran sayısı (success dahil)
  final int _totalSteps = 6;

  Timer?
  _autoNavigateTimer; // Success ekranında otomatik yönlendirme için timer

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

  void _goHome() {
    if (_currentPage == _totalSteps - 1) {
      Future.microtask(() {
        if (!mounted) return;
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          PageRoutes.navbar,
          (a) => false,
        );

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
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
    _autoNavigateTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Mevcut adımın validasyonunun sağlanıp sağlanmadığını kontrol eder.
  bool _isStepValid(dynamic profileState) {
    if (_currentPage == 0) {
      return profileState.fullName.trim().isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(AllControllers.profileSetupProvider);
    final l = context.l10n;
    // Gerçek adım sayısı (Success ekranını sayma)
    final int stepCount = _totalSteps - 1;
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
                  if (_currentPage != stepCount)
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
                              "Step ${_currentPage + 1} of $stepCount",
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

                        if (i == _totalSteps - 1) {
                          _autoNavigateTimer?.cancel();
                          _autoNavigateTimer = Timer(
                            const Duration(seconds: 2),
                            () {
                              if (mounted) _goHome();
                            },
                          );
                        } else {
                          _autoNavigateTimer?.cancel();
                        }
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
                        SuccessStep(
                          titleStyle: ProfileSetupTypography.title(context),
                          subtitleStyle: ProfileSetupTypography.subtitle(
                            context,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -- Alt Buton --
                  if (_currentPage != stepCount)
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

                          if (_currentPage == 4) {
                            Future.microtask(() async {
                              bool success = await ref
                                  .read(
                                    AllControllers
                                        .profileSetupProvider
                                        .notifier,
                                  )
                                  .completeProfile();
                              if (success && mounted) {
                                _goNext();
                              }
                            });
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

    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF21BC87),
          disabledBackgroundColor: const Color(0x4D21BC87), // %30 opacity
          shadowColor: Colors.transparent,
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
                color: Colors.white,
              ),
            ),
            if (isLast) ...[
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/ic_rightArrow.svg',
                color: isLast ? Colors.white : const Color(0xFF21BC87),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
