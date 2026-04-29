import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/meeting_time_constants.dart';
import '../domain/profile_models.dart';

class MeetingTimeStep extends StatelessWidget {
  const MeetingTimeStep({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final MeetingTime? selectedTime;
  final ValueChanged<MeetingTime> onTimeChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  static const _displayOptions = [
    MeetingTime.morning,
    MeetingTime.afternoon,
    MeetingTime.evening,
  ];

  static const _icons = {
    MeetingTime.morning: '🌅',
    MeetingTime.afternoon: '🌤️',
    MeetingTime.evening: '🌙',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MeetingTimeStrings.title(context),
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            MeetingTimeStrings.subtitle(context),
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF96989C),
            ),
          ),
          const SizedBox(height: 20),
          ..._displayOptions.map((time) {
            final selected = selectedTime == time;
            final label = MeetingTimeStrings.label(context, time);
            final range = MeetingTimeStrings.range(context, time);
            final icon = _icons[time] ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MeetingTimeCard(
                icon: icon,
                label: label,
                range: range,
                isSelected: selected,
                onTap: () => onTimeChanged(time),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MeetingTimeCard extends StatelessWidget {
  final String icon;
  final String label;
  final String range;
  final bool isSelected;
  final VoidCallback onTap;

  const _MeetingTimeCard({
    required this.icon,
    required this.label,
    required this.range,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF21BC87).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF21BC87)
                : const Color(0xFFE2E2E2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF21BC87)
                          : const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  Text(
                    range,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF96989C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
