import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/screen_size_extensions.dart';
import '../constants/available_days_strings.dart';
import '../domain/profile_models.dart';

/// AvailableDaysStep
/// ------------------------------------------------------------
/// Kullanıcının müsait olduğu günleri seçtiği ekran.
/// - State: Set<Weekday>
/// - UI: localized label gösterir
class AvailableDaysStep extends StatelessWidget {
  const AvailableDaysStep({
    super.key,
    required this.availableDays,
    required this.onToggleDay,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final Set<Weekday> availableDays;
  final ValueChanged<Weekday> onToggleDay;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  static const _days = Weekday.values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          AvailableDaysStrings.title(context),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _days.map((day) {
            final selected = availableDays.contains(day);
            return GestureDetector(
              onTap: () => onToggleDay(day),
              child: Container(
                width: 96.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? const Color(0xFF2BD383) : Colors.black,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    AvailableDaysStrings.dayLabel(context, day),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      color: selected ? const Color(0xFF3EDC86) : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
