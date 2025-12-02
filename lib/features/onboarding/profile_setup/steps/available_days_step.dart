import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

class AvailableDaysStep extends StatelessWidget {
  final Set<String> availableDays;
  final ValueChanged<String> onToggleDay;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const AvailableDaysStep({
    super.key,
    required this.availableDays,
    required this.onToggleDay,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final days = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Which days are you available?',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: days.map((day) {
            final bool selected = availableDays.contains(day);

            return GestureDetector(
              onTap: () => onToggleDay(day),
              child: Container(
                width: 96.w,
                height: 28.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2BD383) // yeşil çerçeve
                        : Colors.black,           // siyah çerçeve
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    day,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      color: selected
                          ? const Color(0xFF3EDC86) // seçili yeşil yazı
                          : Colors.black,           // normal siyah yazı
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
