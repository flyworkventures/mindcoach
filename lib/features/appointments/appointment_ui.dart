import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/screen_size_extensions.dart';
import '../../core/utils/time_format_utils.dart';
import 'appointments_helper.dart';
import 'appointments_ui_provider.dart';

class AppointmentCardUi extends StatelessWidget {
  final AppointmentUiItem item;

  const AppointmentCardUi({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.isCompleted;

    final keyOrName = item.info.specialistName;
    final name = specialistName(context, keyOrName);
    final title = specialistTitle(context, keyOrName);

    final formattedTime = TimeFormatUtils.formatTime(context, item.dateTime);
    final relative = relativeLabel(context, item.dateTime);
    final timeText = '$relative | $formattedTime';

    final nameColor = isCompleted ? const Color(0xFF9F9F9F) : Colors.black;
    final titleColor = isCompleted ? const Color(0xFF9F9F9F) : Colors.black;
    const timeColor = Color(0xFF7B7B7B);

    final borderColor =
    isCompleted ? const Color(0xFF9F9F9F) : const Color(0xFF2BD383);

    return Container(
      height: 99.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDEDEDE), width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 61,
            height: 61,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 3),
              image: DecorationImage(
                image: AssetImage(item.avatarAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: GoogleFonts.quicksand(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 24 / 17,
                    color: nameColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  timeText,
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 18 / 11,
                    color: timeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
