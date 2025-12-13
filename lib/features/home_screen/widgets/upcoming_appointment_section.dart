import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindcoach/core/global_constants/month_strings.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/utils/time_format_utils.dart';

import 'package:mindcoach/features/appointments/appointments_notifier.dart';

import '../constants/home_constants.dart';
import '../home_notifier.dart';

class UpcomingAppointmentSection extends ConsumerWidget {
  const UpcomingAppointmentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final next = ref.read(homeProvider.notifier).findNextAppointment();

    if (next == null) {
      return Padding(
        padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.upcomingMeetingTitle,
              style: GoogleFonts.quicksand(
                fontSize: 17.w,
                fontWeight: FontWeight.w700,
                height: 24.h / 17.w,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              l.noUpcomingMeetings,
              style: GoogleFonts.quicksand(
                fontSize: 14.w,
                fontWeight: FontWeight.w500,
                height: 24.h / 14.w,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    final DateTime date = next.key;
    final AppointmentInfo info = next.value;

    final time = TimeFormatUtils.formatTime(context, date);
    final desc = HomeStrings.appointmentDescription(context, info);

    return Padding(
      padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.upcomingMeetingTitle,
            style: GoogleFonts.quicksand(
              fontSize: 17.w,
              fontWeight: FontWeight.w700,
              height: 24.h / 17.w,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            l.timeRemainingTitle,
            style: GoogleFonts.quicksand(
              fontSize: 14.w,
              fontWeight: FontWeight.w500,
              height: 24.h / 14.w,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 15.h),
          _RemainingTimeCard(),
          SizedBox(height: 15.h),
          _AppointmentCard(date: date, time: time, description: desc),
        ],
      ),
    );
  }
}

class _RemainingTimeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(appointmentsProvider);

    return Container(
      width: 327.w,
      height: 84.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TimeItem(value: s.remainingDays, label: l.days),
          _Separator(),
          _TimeItem(value: s.remainingHours, label: l.hours),
          _Separator(),
          _TimeItem(value: s.remainingMinutes, label: l.minutes),
          _Separator(),
          _TimeItem(value: s.remainingSeconds, label: l.seconds),
        ],
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  const _TimeItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 40.w,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0.0, -5.h),
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 11.w,
              fontWeight: FontWeight.w600,
              height: 1.0,
              color: AppColors.appointmentTimeLabel,
            ),
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0.0, -5.h),
      child: Text(
        ':',
        style: GoogleFonts.quicksand(
          fontSize: 20.w,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: AppColors.separatorGrey.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.date,
    required this.time,
    required this.description,
  });

  final DateTime date;
  final String time;
  final String description;

  @override
  Widget build(BuildContext context) {
    final monthText = MonthStrings.name(context, date.month);

    return Container(
      width: 327.w,
      height: 100.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthText ${date.day}',
                style: GoogleFonts.quicksand(
                  fontSize: 17.w,
                  fontWeight: FontWeight.w600,
                  height: 24.h / 17.w,
                  color: Colors.black,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.quicksand(
                  fontSize: 12.w,
                  fontWeight: FontWeight.w600,
                  height: 24.h / 12.w,
                  color: AppColors.appointmentTimeText,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: GoogleFonts.quicksand(
              fontSize: 12.w,
              fontWeight: FontWeight.w500,
              height: 18.h / 12.w,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
