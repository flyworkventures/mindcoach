import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import '../constants/mood_colors.dart';
import '../domain/mood.dart';
import '../home_notifier.dart';

class MoodTrackerSection extends ConsumerWidget {
  const MoodTrackerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(homeProvider);

    final items = <({
    Mood mood,
    Color bg,
    String label,
    String svg,
    double size,
    })>[
      (mood: Mood.terrible, bg: MoodColors.terribleBg, label: l.moodTerrible, svg: 'assets/svg/face_very_sad.svg', size: 28),
      (mood: Mood.bad,      bg: MoodColors.badBg,      label: l.moodBad,      svg: 'assets/svg/face_sad.svg',      size: 44),
      (mood: Mood.neutral,  bg: MoodColors.neutralBg,  label: l.moodNeutral,  svg: 'assets/svg/face_notr.svg',     size: 32),
      (mood: Mood.good,     bg: MoodColors.goodBg,     label: l.moodGood,     svg: 'assets/svg/face_happy.svg',    size: 34),
      (mood: Mood.great,    bg: MoodColors.greatBg,    label: l.moodGreat,    svg: 'assets/svg/face_very_happy.svg', size: 30),
    ];

    return Padding(
      padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.howAreYouFeelIngToday,
            style: GoogleFonts.quicksand(
              fontSize: 17.w,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
              color: Colors.black,
            ),
          ),
          Text(
            l.timeToTrackMood,
            style: GoogleFonts.quicksand(
              fontSize: 14.w,
              fontWeight: FontWeight.w500,
              height: 24 / 14,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10.h),

          Container(
            width: 332.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13.w),
              border: Border.all(color: AppColors.cardBorder, width: 1.w),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.map((it) {
                final isSelected = state.selectedMood == it.mood;
                return GestureDetector(
                  onTap: () => ref.read(homeProvider.notifier).setMood(it.mood),
                  child: Container(
                    width: 46.w,
                    height: 46.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: it.bg,
                      border: isSelected ? Border.all(color: AppColors.primaryGreen, width: 2) : null,
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      it.svg,
                      width: it.size,
                      height: it.size,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
