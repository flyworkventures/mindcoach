import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/View/OnboardView/data/onboarding_localizations.dart';
import 'package:mindcoach/core/routes/page_routes.dart'; // Yönlendirme için eklendi

import '../../l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAutoTimer();
  }

  // Timer'ı başlatan veya sıfırlayan metod
  void _startAutoTimer() {
    _autoTimer?.cancel(); // Varsa eskisini iptal et
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final pageCount = ref
          .read(AllControllers.onboardController.notifier)
          .pages
          .length;
      setState(() {
        _currentIndex = (_currentIndex + 1) % pageCount;
      });
    });
  }

  // Sonraki sayfaya geç
  void _nextPage(int pageCount) {
    if (_currentIndex < pageCount - 1) {
      setState(() {
        _currentIndex++;
      });
      _startAutoTimer(); // Kullanıcı müdahale ettiği için süreyi sıfırla
    }
  }

  // Önceki sayfaya dön
  void _previousPage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startAutoTimer(); // Kullanıcı müdahale ettiği için süreyi sıfırla
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final titles = l.onboardingTitles;
    final descriptions = l.onboardingDescriptions;

    final pageCount = ref
        .read(AllControllers.onboardController.notifier)
        .pages
        .length;
    final isLastPage = _currentIndex == pageCount - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior:
              HitTestBehavior.opaque, // Boş alanlarda da swipe algılanması için
          onHorizontalDragEnd: (details) {
            // Sağa veya sola kaydırma hassasiyetini yakalama
            if (details.primaryVelocity! < 0) {
              // Sola kaydırıldı (İleri git)
              _nextPage(pageCount);
            } else if (details.primaryVelocity! > 0) {
              // Sağa kaydırıldı (Geri git)
              _previousPage();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Resim Alanı (Sabit Merkezlenmiş)
              Expanded(
                flex: 5,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    key: ValueKey<int>(_currentIndex),
                    alignment: Alignment
                        .center, // Resimlerin merkezde sabit durmasını sağlar
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Image.asset(
                      'assets/chars/onboard${_currentIndex + 1}.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),

              // 2. Metinler, Indicator ve Buton Alanı
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicator Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pageCount,
                        (index) => _buildDot(index),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Daha iyi boşluk için hafif artırıldı
                    // Title & Subtitle Area (Sabit Yükseklik ve Tam Genişlik Verildi)
                    SizedBox(
                      height: 120,
                      width: double.infinity, // Sağa sola kaymayı çözen satır
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: Column(
                          key: ValueKey<int>(_currentIndex),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[_currentIndex],
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF000000),
                                height: 1.0,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              descriptions[_currentIndex],
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF96989C),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Alt Buton Alanı (Get Started / Swipe to continue)
                    _buildBottomButton(isLastPage, l, pageCount),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Figma Indicator Tasarımı
  Widget _buildDot(int index) {
    bool isActive = index == _currentIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      height: 7,
      width: isActive ? 22 : 7,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF21BC87) : const Color(0xFFC4C4C4),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  // Figma Buton Tasarımı
  Widget _buildBottomButton(
    bool isLastPage,
    AppLocalizations l,
    int pageCount,
  ) {
    return GestureDetector(
      onTap: () {
        if (!isLastPage) {
          _nextPage(
            pageCount,
          ); // Butona basıldığında da manuel gitme sayılıyor, timer sıfırlanır
        } else {
          // KULLANICI GET STARTED'A BASTI -> Profile Setup (MindCoachOnboarding) Sayfasına Geç
          _autoTimer?.cancel();
          Navigator.of(context).pushReplacementNamed(PageRoutes.profileSetup);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isLastPage
              ? const Color(0xFF21BC87)
              : const Color(0xFF21BC87).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLastPage
              ? [
                  const BoxShadow(
                    color: Color(0xFF21BC87),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? l.getStarted : l.swipeToContinue,
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isLastPage ? Colors.white : const Color(0xFF21BC87),
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/icons/ic_rightArrow.svg',
              color: isLastPage ? Colors.white : const Color(0xFF21BC87),
            ),
          ],
        ),
      ),
    );
  }
}
