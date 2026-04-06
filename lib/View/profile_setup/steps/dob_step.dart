import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/View/ProfileSetupView/constants/dob_strings.dart';


import 'package:mindcoach/core/global_constants/month_strings.dart';

class DobStep extends StatefulWidget {
  /// Seçili doğum tarihi (yoksa null)
  final DateTime? selectedDate;

  /// Tarih değişince tetiklenir
  final ValueChanged<DateTime?> onDateChanged;

  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const DobStep({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  State<DobStep> createState() => _DobStepState();
}

class _DobStepState extends State<DobStep> {
  late int _day;
  late int _month;
  late int _year;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  Timer? _notifyTimer;

  List<int> get _days => List.generate(31, (i) => i + 1);

  List<int> get _months => List.generate(12, (i) => i + 1);

  List<int> get _years {
    final max = DobStrings.maxYear();
    final min = DobStrings.minYear;
    // En yeni yıldan eskiye doğru liste
    return List.generate(max - min + 1, (i) => max - i);
  }

  @override
  void initState() {
    super.initState();

    final initialDate =
        widget.selectedDate ?? DateTime(DobStrings.defaultYear(), 1, 1);

    // Yıl sınırları içinde değilse clamp et
    final clampedYear = initialDate.year.clamp(
      DobStrings.minYear,
      DobStrings.maxYear(),
    );

    _year = clampedYear;
    _month = initialDate.month.clamp(1, 12);
    _day = initialDate.day.clamp(1, 31);

    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);

    final years = _years;
    final yearIndex = years.indexOf(_year);
    _yearController = FixedExtentScrollController(
      initialItem: yearIndex >= 0 ? yearIndex : 0,
    );

    // Parent'a ilk değeri build sonrası bildir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyParent();
    });
  }

  @override
  void didUpdateWidget(covariant DobStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate &&
        widget.selectedDate != null) {
      final d = widget.selectedDate!;
      final clampedYear = d.year.clamp(
        DobStrings.minYear,
        DobStrings.maxYear(),
      );

      _year = clampedYear;
      _month = d.month.clamp(1, 12);
      _day = d.day.clamp(1, 31);

      if (_dayController.hasClients) {
        _dayController.jumpToItem(_day - 1);
      }
      if (_monthController.hasClients) {
        _monthController.jumpToItem(_month - 1);
      }
      if (_yearController.hasClients) {
        final years = _years;
        final yearIndex = years.indexOf(_year);
        _yearController.jumpToItem(yearIndex >= 0 ? yearIndex : 0);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyParent();
      });
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _notifyTimer?.cancel();
    super.dispose();
  }

  void _onDayChanged(int index) {
    setState(() {
      _day = _days[index];
    });
    _scheduleNotify();
  }

  void _onMonthChanged(int index) {
    setState(() {
      _month = _months[index];
    });
    _scheduleNotify();
  }

  void _onYearChanged(int index) {
    final years = _years;
    setState(() {
      _year = years[index];
    });
    _scheduleNotify();
  }

  void _scheduleNotify() {
    // her değişimde eski timer'ı iptal edip yenisini başlat
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 200), () {
      _notifyParent();
    });
  }

  void _notifyParent() {
    // Geçersiz kombinasyon (örn: 31 Şubat) için try/catch
    DateTime? result;
    try {
      result = DateTime(_year, _month, _day);
      if (result.year != _year ||
          result.month != _month ||
          result.day != _day) {
        result = null;
      }
    } catch (_) {
      result = null;
    }

    widget.onDateChanged(result);
  }

  TextStyle _wheelStyle(bool isSelected) {
    if (isSelected) {
      return GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.0,
        color: Colors.black,
      );
    }

    return GoogleFonts.quicksand(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.0,
      color: const Color(0xFF8E8E8E),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = _years;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          DobStrings.title(context),
          style: widget.titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          DobStrings.subtitle(context),
          style: widget.subtitleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                DobStrings.dayLabel(context),
                textAlign: TextAlign.center,
                style: widget.subtitleStyle,
              ),
            ),
            Expanded(
              child: Text(
                DobStrings.monthLabel(context),
                textAlign: TextAlign.center,
                style: widget.subtitleStyle,
              ),
            ),
            Expanded(
              child: Text(
                DobStrings.yearLabel(context),
                textAlign: TextAlign.center,
                style: widget.subtitleStyle,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 42 * 3,
          child: Row(
            children: [
              // Day wheel
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _dayController,
                  itemExtent: 32,
                  physics: const FixedExtentScrollPhysics(),
                  overAndUnderCenterOpacity: 0.6,
                  perspective: 0.0002,
                  diameterRatio: 10.0,
                  onSelectedItemChanged: _onDayChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _days.length,
                    builder: (context, index) {
                      final value = _days[index];
                      final isSelected = value == _day;
                      return Center(
                        child: Text(
                          value.toString().padLeft(2, '0'),
                          style: _wheelStyle(isSelected),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Month wheel
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _monthController,
                  itemExtent: 32,
                  physics: const FixedExtentScrollPhysics(),
                  overAndUnderCenterOpacity: 0.6,
                  perspective: 0.0002,
                  diameterRatio: 10.0,
                  onSelectedItemChanged: _onMonthChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _months.length,
                    builder: (context, index) {
                      final value = _months[index];
                      final isSelected = value == _month;
                      final label = MonthStrings.name(context, value);

                      return Center(
                        child: Text(label, style: _wheelStyle(isSelected)),
                      );
                    },
                  ),
                ),
              ),

              // Year wheel
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _yearController,
                  itemExtent: 32,
                  physics: const FixedExtentScrollPhysics(),
                  overAndUnderCenterOpacity: 0.6,
                  perspective: 0.0002,
                  diameterRatio: 10.0,
                  onSelectedItemChanged: _onYearChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: years.length,
                    builder: (context, index) {
                      final value = years[index];
                      final isSelected = value == _year;

                      return Center(
                        child: Text(
                          value.toString(),
                          style: _wheelStyle(isSelected),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
