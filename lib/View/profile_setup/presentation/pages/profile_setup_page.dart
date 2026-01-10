import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import '../../../../../core/theme/profile_setup_typography.dart';
import '../../../../../core/widgets/top_toast.dart';
import '../../animated_flowgradient.dart';
import 'package:mindcoach/View/profile_setup/application/profile_setup_notifier.dart';
// STEP WIDGETS
import 'package:mindcoach/View/profile_setup/steps/available_days_step.dart';
import '../../steps/name_gender_step.dart';
import '../../steps/dob_step.dart';
import '../../steps/support_area_step.dart';
import '../../steps/approach_step.dart';
import '../../steps/meeting_time_step.dart';
import '../../steps/success_step.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/config/app_status_notifier.dart';




class MindCoachOnboarding extends ConsumerStatefulWidget {
  const MindCoachOnboarding({super.key});

  @override
  ConsumerState<MindCoachOnboarding> createState() => _MindCoachOnboardingState();
}

class _MindCoachOnboardingState extends ConsumerState<MindCoachOnboarding> {
  final PageController _pageController = PageController();


  int _currentPage = 0;
  
  // Ekran sayısı (success dahil)
  final int _totalSteps = 7;

  bool _hasNameError = false; // 🔴 isim boşken butonu kırmızı yapmak için
  bool _usernameInitialized = false; // Username'in bir kez set edilmesi için flag
  Timer? _autoNavigateTimer; // Success ekranında otomatik yönlendirme için timer

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
      // Delay to avoid modifying provider during build phase
      Future.microtask(() {
        if (!mounted) return;
        // 1) Uygulama durumunu "authenticated" yap
        ref.read(appStatusProvider.notifier).goToAuthenticated();
        
        // 2) Stack'i root'a kadar temizle (root: AuthGate route'u)
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Apple ile giriş yapıldığında fullName'i set et (sadece bir kez)
    if (!_usernameInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && !_usernameInitialized) {
          try {
            await ref.read(profileSetupProvider.notifier).initFromUser();
            if (mounted) {
              setState(() {
                _usernameInitialized = true;
              });
            }
          } catch (e) {
            debugPrint('Error initializing username: $e');
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileSetupProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedFlowBackground(),
          Column(
            children: [
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: SizedBox(
                      width: 360.w,
                      height: _currentPage == 0 ? 480.h : 430.h, // 480 430
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(38),
                        ),
                        child: Column(
                          children: [
                            // Üst bar: back + progress
                            SizedBox(
                              width: double.infinity,
                              height: 28.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: _currentPage != 6
                                        ? InkWell(
                                      onTap: _currentPage == 0
                                          ? null
                                          : _goBack,
                                      borderRadius: BorderRadius.circular(
                                        38,
                                      ),
                                      child: Icon(
                                        Icons.arrow_back,
                                        size: 22,
                                        color: _currentPage == 0
                                            ? const Color(0xFFCACACA)
                                            : const Color(0xFF2BD383),
                                      ),
                                    )
                                        : const SizedBox(),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 28.0,
                                          left: 8,
                                        ),
                                        child: _OnboardingProgressBar(
                                          currentPage: _currentPage,
                                          totalSteps: _totalSteps,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (i) {
                                  setState(() {
                                    _currentPage = i;
                                  });
                                  
                                  // Success ekranına (son ekran) geçildiğinde otomatik yönlendirme başlat
                                  if (i == _totalSteps - 1) {
                                    _autoNavigateTimer?.cancel();
                                    _autoNavigateTimer = Timer(const Duration(seconds: 2), () {
                                      if (mounted) {
                                        _goHome();
                                      }
                                    });
                                  } else {
                                    // Başka bir ekrana geçildiğinde timer'ı iptal et
                                    _autoNavigateTimer?.cancel();
                                  }
                                },
                                children: [
                                  // 1) İsim + cinsiyet
                                  NameGenderStep(
                                    fullName: profileState.fullName,
                                    onFullNameChanged: (name) {
                                      ref.read(profileSetupProvider.notifier).setFullName(name);
                                    },
                                    gender: profileState.gender,
                                    onGenderChanged: (g) {
                                      ref.read(profileSetupProvider.notifier).setGender(g);
                                    },
                                    titleStyle: ProfileSetupTypography.title(context),
                                    subtitleStyle: ProfileSetupTypography.subtitle(context),
                                  ),


                                  // 2) Doğum tarihi
                                  DobStep(
                                    selectedDate: profileState.dob,
                                    onDateChanged: (date) {
                                      ref.read(profileSetupProvider.notifier).setDob(date);
                                    },
                                    titleStyle: ProfileSetupTypography.title(context),
                                    subtitleStyle: ProfileSetupTypography.subtitle(context),
                                  ),

                                  // 3) Destek alanı
                                  SupportAreaStep(
                                    selectedSupportArea: profileState.supportArea,
                                    onSupportAreaChanged: (area) {
                                      ref.read(profileSetupProvider.notifier).setSupportArea(area);
                                    },
                                    titleStyle: ProfileSetupTypography.title(context),
                                    subtitleStyle: ProfileSetupTypography.subtitle(context),
                                  ),

                                  // 4) Uzmanın yaklaşımı (enum tabanlı)
                                  ApproachStep(
                                    selectedApproach: profileState.approach,
                                    onApproachChanged: (value) {
                                          ref.read(profileSetupProvider.notifier).setApproach(value);
                                    },
                                    titleStyle: ProfileSetupTypography.title(context),
                                    subtitleStyle: ProfileSetupTypography.subtitle(context),
                                  ),

                                  // 5) Uygun günler
                                  AvailableDaysStep(
                                    availableDays: profileState.availableDays,
                                    onToggleDay: (day) {
                                      ref.read(profileSetupProvider.notifier).toggleDay(day);
                                    },
                                    titleStyle: ProfileSetupTypography.title(context),
                                    subtitleStyle: ProfileSetupTypography.subtitle(context),
                                  ),

                                  // 6) Görüşme zamanı
                                  MeetingTimeStep(
                                    selectedTime: profileState.meetingTime,
                                    onTimeChanged: (t) {
                                      // Delay the state update to avoid modifying provider during build phase
                                      Future.microtask(() {
                                        ref.read(profileSetupProvider.notifier).setMeetingTime(t);
                                      });
                                    },
                                    titleStyle: ProfileSetupTypography.title(context),
                                    subtitleStyle: ProfileSetupTypography.subtitle(context),
                                  ),

                                  // 7) Başarı ekranı
                                  SuccessStep(
                                    titleStyle: ProfileSetupTypography.title(context),
                                    subtitleStyle: ProfileSetupTypography.subtitle(context),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _BottomPrimaryButton(
                              isLast: _currentPage == _totalSteps - 1,
                              isError: _currentPage == 0 && _hasNameError, // sadece 1. adımda
                              onPressed: () async{
                                if (_currentPage == _totalSteps - 1) {
                                  // Delay to avoid modifying provider during build phase
                                  Future.microtask(() {
                                    _goHome();
                                  });
                                  return;
                                }
                                if (_currentPage == 5) {
                                  // Delay to avoid modifying provider during build phase
                                  Future.microtask(() async {
                                    bool success = await ref.read(profileSetupProvider.notifier).completeProfile();
                                    if (success && mounted) {
                                      // Delay navigation to avoid modifying provider during build phase
                                      Future.microtask(() {
                                        if (mounted) {
                                          ref.read(appStatusProvider.notifier).goToAuthenticated();
                                        }
                                      });
                                    }
                                  });
                                  // Move to next page (success step)
                                  _goNext();
                                  return;
                                } 

                                if (_currentPage == 0) {
                                  final profileState = ref.read(profileSetupProvider);
                                  final fullName = profileState.fullName;

                                  // Sadece boş olmamalı kontrolü (boşluk ve uzunluk kontrolü yok)
                                  if (fullName.isEmpty) {
                                    setState(() {
                                      _hasNameError = true;
                                    });

                                    // uyarı
                                    showTopToast(context, l10n.enterFullNamePrompt);
                                    return;
                                  }
                                }

                                // her şey yolundaysa hata flag'ini sıfırla ve ilerle
                                if (_hasNameError) {
                                  setState(() {
                                    _hasNameError = false;
                                  });
                                }

                                _goNext();
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- Progress Bar ----------------

class _OnboardingProgressBar extends StatelessWidget {
  final int currentPage;
  final int totalSteps;

  const _OnboardingProgressBar({
    required this.currentPage,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    // Success ekranında progress gizle
    if (currentPage == totalSteps - 1) {
      return const SizedBox.shrink();
    }

    const int visibleSteps = 6;
    const double spacing = 3;

    return SizedBox(
      height: 2,
      child: Row(
        children: List.generate(visibleSteps, (index) {
          final isActive =
              index <= currentPage && currentPage < totalSteps - 1;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index == visibleSteps - 1 ? 0 : spacing,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2BD383)
                    : const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------- Alt Buton ----------------

class _BottomPrimaryButton extends StatelessWidget {
  final bool isLast;
  final bool isError;
  final VoidCallback onPressed;

  const _BottomPrimaryButton({required this.isLast,     required this.isError,
    required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return SizedBox(
      width: 301.w,
      height: 45.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: isError
              ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFE53935), // kırmızı
              Color(0xFFB71C1C),
            ],
          )
              : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF3EDC86), Color(0xFF0F9A86)],
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            isLast ? l.getStarted : l.next,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
