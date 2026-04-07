import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/available_days_strings.dart';
import '../domain/profile_models.dart';

class AvailableDaysStep extends StatelessWidget {
  const AvailableDaysStep({
    super.key,
    required this.availableDays,
    required this.onToggleDay,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final List<Weekday> availableDays;
  final ValueChanged<Weekday> onToggleDay;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  static const _days = Weekday.values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AvailableDaysStrings.title(context),
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          AvailableDaysStrings.subtitle(context),
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF96989C),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: _days.map((day) {
            final selected = availableDays.contains(day);
            return GestureDetector(
              onTap: () => onToggleDay(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF21BC87).withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF21BC87)
                        : const Color(0xFFE2E2E2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    AvailableDaysStrings.dayLabel(context, day),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? const Color(0xFF21BC87)
                          : const Color(0xFF1D1D1D),
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
