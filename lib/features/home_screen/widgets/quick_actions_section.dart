import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/locale_font_scaler.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/widgets/pill_page_indicator.dart';

import '../home_notifier.dart';

class QuickActionsSection extends ConsumerStatefulWidget {
  const QuickActionsSection({super.key});

  @override
  ConsumerState<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends ConsumerState<QuickActionsSection> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _pageItem(BuildContext context, {required String text, required Color color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.w, left: 12, right: 12, top: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: LocaleFontScaler.scale(context, 20),
            fontWeight: FontWeight.w600,
            height: 1.0,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(homeProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 31.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol kart: quote slider
          Flexible(
            child: SizedBox(
              width: 154.w,
              height: 151.h,
              child: GestureDetector(
                onTap: () {
                  // TODO: Soldaki Quick Action'a git
                },
                child: Container(
                  width: 154.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.w),
                    border: Border.all(color: AppColors.cardBorder, width: 1.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5.w,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          ref.read(homeProvider.notifier).setQuickActionPageIndex(index);
                        },
                        children: [
                          _pageItem(context, text: l.onboardingQuote1, color: Colors.black),
                          _pageItem(context, text: l.onboardingQuote2, color: Colors.blueGrey),
                          _pageItem(context, text: l.onboardingQuote3, color: Colors.indigo),
                        ],
                      ),
                      Positioned(
                        bottom: 10.h,
                        left: 0,
                        right: 0,
                        child: PillPageIndicator(
                          count: 3,
                          currentIndex: state.quickActionPageIndex,
                          selectedColor: AppColors.primaryGreen,
                          unselectedColor: AppColors.indicatorUnselected,
                          selectedWidth: 33.w,
                          unselectedWidth: 10.w,
                          height: 3.h,
                          spacing: 4.w,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 23.w),

          // Sağ kart: Start talking
          Flexible(
            child: GestureDetector(
              onTap: () {
                // TODO: Chatbot'a git
              },
              child: Container(
                width: 154.w,
                height: 151.h,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13.w),
                  border: Border.all(color: AppColors.cardBorder, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5.w,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 77.w,
                      height: 77.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade100,
                        image: const DecorationImage(
                          image: AssetImage('assets/images/female_avatar.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l.someoneWantsToTalkToYou,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: LocaleFontScaler.scale(context, 13),
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.startTalking,
                          style: GoogleFonts.quicksand(
                            fontSize: LocaleFontScaler.scale(context, 12),
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Icon(Icons.arrow_forward_ios, size: 10.w, color: AppColors.primaryGreen),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
