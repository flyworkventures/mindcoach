import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wheel_chooser/wheel_chooser.dart';

import '../../../../core/utils/screen_size_extensions.dart';

class CustomWheelChooser extends StatelessWidget {
  final int selectedDay;
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const CustomWheelChooser({
    super.key,
    required this.selectedDay,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onDayChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final months = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final years = List.generate(60, (index) => 2007 - index);

    // Calculate max day based on selected year and month
    final maxDay = DateUtils.getDaysInMonth(selectedYear, selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "What’s your date of birth",
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us your birthday. Your profile does not '
              'display your birthdate. Only your age.',
          style: subtitleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        SizedBox(
          height: 150.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ---------- DAY ----------
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Day',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: WheelChooser.integer(
                        onValueChanged: (value) => onDayChanged(value as int),
                        minValue: 1,
                        maxValue: maxDay,
                        perspective: 0.002,
                        initValue: selectedDay, // Keep the selected day fixed
                        isInfinite: true,
                        itemSize: 28,
                        listHeight: 32 * 4,
                        selectTextStyle: _getTextStyleForDay(0),
                        unSelectTextStyle: _getTextStyleForDay(1),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- MONTH ----------
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Month',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: WheelChooser(
                        datas: months,
                        onValueChanged: (value) {
                          final index = months.indexOf(value as String);
                          // Update selected month and also fix the day
                          onMonthChanged(index + 1);
                          _fixDayForMonthYear(); // Adjust day if necessary
                        },
                        startPosition: selectedMonth - 1,
                        isInfinite: true, // 🔁 month is circular
                        itemSize: 28,
                        listHeight: 32 * 4,
                        perspective: 0.002,
                        selectTextStyle: _getTextStyleForMonth(0),
                        unSelectTextStyle: _getTextStyleForMonth(1),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- YEAR ----------
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Year',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: WheelChooser(
                        datas: years,
                        onValueChanged: (value) => onYearChanged(value as int),
                        startPosition: years.indexOf(selectedYear),
                        isInfinite: true, // 🔁 year is circular
                        itemSize: 28,
                        listHeight: 32 * 4,
                        perspective: 0.002,
                        selectTextStyle: _getTextStyleForYear(0),
                        unSelectTextStyle: _getTextStyleForYear(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Custom TextStyle functions for Day, Month and Year
  TextStyle _getTextStyleForDay(int index) {
    if (index == 0) {
      return GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.0,
        color: Colors.black,
      );
    } else if (index == 1) {
      return GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFF8E8E8E),
      );
    } else {
      return GoogleFonts.quicksand(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFFCBCBCB),
      );
    }
  }

  TextStyle _getTextStyleForMonth(int index) {
    if (index == 0) {
      return GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.0,
        color: Colors.black,
      );
    } else if (index == 1) {
      return GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFF8E8E8E),
      );
    } else {
      return GoogleFonts.quicksand(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFFCBCBCB),
      );
    }
  }

  TextStyle _getTextStyleForYear(int index) {
    if (index == 0) {
      return GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.0,
        color: Colors.black,
      );
    } else if (index == 1) {
      return GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFF8E8E8E),
      );
    } else {
      return GoogleFonts.quicksand(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFFCBCBCB),
      );
    }
  }

  // Fixes the day when month or year changes to ensure it is within valid range
  void _fixDayForMonthYear() {
    final maxDay = DateUtils.getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > maxDay) {
      onDayChanged(maxDay); // If day exceeds max, set it to max day
    }
  }
}
