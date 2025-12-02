import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/features/home/home_screen.dart';

import 'animated_flowgradient.dart';

// STEP WIDGETS
import 'steps/name_gender_step.dart';
import 'steps/dob_step.dart';
import 'steps/support_area_step.dart';
import 'steps/approach_step.dart';
import 'steps/available_days_step.dart';
import 'steps/meeting_time_step.dart';
import 'steps/success_step.dart';

class MindCoachOnboarding extends StatefulWidget {
  const MindCoachOnboarding({super.key});

  @override
  State<MindCoachOnboarding> createState() => _MindCoachOnboardingState();
}

class _MindCoachOnboardingState extends State<MindCoachOnboarding> {

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Ekran sayısı (success dahil)
  final int _totalSteps = 7;

  // Doğum tarihi wheel değerleri
  int _selectedDay = 1;
  int _selectedMonth = 1; // 1-12
  int _selectedYear = 2000; // örnek

  int _daysInMonth(int year, int month) {
    return DateUtils.getDaysInMonth(year, month);
  }

  void _fixDayForMonthYear() {
    final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > maxDay) {
      _selectedDay = maxDay;
    }
  }

  // Seçimler
  String _gender = 'Male';
  String _supportArea = 'Career';
  String _approach = 'Convincing';
  final Set<String> _availableDays = {'Monday', 'Wednesday', 'Friday'};
  String _meetingTime = 'Morning';

  void _goNext() {
    if (_currentPage < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
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

  void _goHomePage() {
    if (_currentPage == _totalSteps - 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  TextStyle get _titleStyle => GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0,
    color: const Color(0xFF1D1D1D),
  );

  TextStyle get _subtitleStyle => GoogleFonts.quicksand(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0,
    color: const Color(0xFF1D1D1D),
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      height: 393.h,
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
                                              fontWeight: FontWeight.bold,
                                              size: 22,
                                              color: _currentPage == 0
                                                  ? const Color(0xFFCACACA)
                                                  : const Color(0xFF2BD383),
                                            ),
                                          )
                                        :
                                          // InkWell(
                                          //   onTap: _currentPage == 0 ? null : _goBack,
                                          //   borderRadius: BorderRadius.circular(38),
                                          //   child: Icon(
                                          //     Icons.arrow_back,
                                          //     fontWeight: FontWeight.bold,
                                          //     size: 22,
                                          //     color: _currentPage == 0
                                          //         ? const Color(0xFFCACACA)
                                          //         : const Color(0xFF2BD383),
                                          //   ),),
                                          SizedBox(),
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
                                },
                                children: [
                                  NameGenderStep(
                                    gender: _gender,
                                    onGenderChanged: (g) {
                                      setState(() => _gender = g);
                                    },
                                    titleStyle: _titleStyle,
                                    subtitleStyle: _subtitleStyle,
                                  ),
                                  CustomWheelChooser(
                                    selectedDay: _selectedDay,
                                    selectedMonth: _selectedMonth,
                                    selectedYear: _selectedYear,
                                    onDayChanged: (d) {
                                      setState(() => _selectedDay = d);
                                    },
                                    onMonthChanged: (m) {
                                      setState(() {
                                        _selectedMonth = m;
                                        _fixDayForMonthYear();
                                      });
                                    },
                                    onYearChanged: (y) {
                                      setState(() {
                                        _selectedYear = y;
                                        _fixDayForMonthYear();
                                      });
                                    },
                                    titleStyle: _titleStyle,
                                    subtitleStyle: _subtitleStyle,
                                  ),

                                  SupportAreaStep(
                                    selectedSupportArea: _supportArea,
                                    onSupportAreaChanged: (s) {
                                      setState(() => _supportArea = s);
                                    },
                                    titleStyle: _titleStyle,
                                    subtitleStyle: _subtitleStyle,
                                  ),
                                  ApproachStep(
                                    selectedApproach: _approach,
                                    onApproachChanged: (a) {
                                      setState(() => _approach = a);
                                    },
                                    titleStyle: _titleStyle,
                                    subtitleStyle: _subtitleStyle,
                                  ),
                                  AvailableDaysStep(
                                    availableDays: _availableDays,
                                    onToggleDay: (day) {
                                      setState(() {
                                        if (_availableDays.contains(day)) {
                                          _availableDays.remove(day);
                                        } else {
                                          _availableDays.add(day);
                                        }
                                      });
                                    },
                                    titleStyle: _titleStyle,
                                    subtitleStyle: _subtitleStyle,
                                  ),
                                  MeetingTimeStep(
                                    selectedTime: _meetingTime,
                                    onTimeChanged: (t) {
                                      setState(() => _meetingTime = t);
                                    },
                                    titleStyle: _titleStyle,
                                    subtitleStyle: _subtitleStyle,
                                  ),
                                  SuccessStep(
                                    titleStyle: _titleStyle,
                                    subtitleStyle: _subtitleStyle,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _BottomPrimaryButton(
                              isLast: _currentPage == _totalSteps - 1,
                              onPressed: (_currentPage == _totalSteps - 1) ? _goHomePage : _goNext,                            ),
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
          final isActive = index <= currentPage && currentPage < totalSteps - 1;
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
  final VoidCallback onPressed;

  const _BottomPrimaryButton({required this.isLast, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 301.w,
      height: 45.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
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
            isLast ? 'Get Started' : 'Next',
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
