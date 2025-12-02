import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeetingTimeStep extends StatefulWidget {
  final String selectedTime;
  final ValueChanged<String> onTimeChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const MeetingTimeStep({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  State<MeetingTimeStep> createState() => _MeetingTimeStepState();
}

class _MeetingTimeStepState extends State<MeetingTimeStep> {
  final Map<String, String> _optionsMap = const {
    'Afternoon': '(12:00–06:00)',
    'Morning': '(08:00–12:00)',
    'Evening': '(06:00–09:00)',
    'Flexible': '',
  };

  late final List<String> _options; // ['Morning', 'Afternoon', ...]
  late int _currentIndex;
  late FixedExtentScrollController _controller;

  int _indexForInitial() {
    final externalIndex = _options.indexOf(widget.selectedTime);
    if (externalIndex != -1) return externalIndex;

    final fallbackIndex = _options.indexOf('Morning');
    return fallbackIndex == -1 ? 0 : fallbackIndex;
  }

  @override
  void initState() {
    super.initState();
    _options = _optionsMap.keys.toList();
    _currentIndex = _indexForInitial();
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant MeetingTimeStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedTime != widget.selectedTime) {
      final newIndex = _indexForInitial();
      if (newIndex != _currentIndex) {
        _currentIndex = newIndex;
        if (_controller.hasClients) {
          _controller.jumpToItem(_currentIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _styleForIndex(int index) {
    final diff = (index - _currentIndex).abs();

    if (diff == 0) {
      // Seçili satır
      return GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: Colors.black,
      );
    } else if (diff == 1) {
      // Bir üst / bir alt
      return GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFF8E8E8E),
      );
    } else {
      // İki üst / iki alt (ve daha uzaklar)
      return GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFFCBCBCB),
      );
    }
  }

  TextStyle _styleForRange(int index) {
    final diff = (index - _currentIndex).abs();

    if (diff == 0) {
      // Seçili satır
      return GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: Colors.black,
      );
    } else if (diff == 1) {
      // Bir üst / bir alt
      return GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFF8E8E8E),
      );
    } else {
      // İki üst / iki alt (ve daha uzaklar)
      return GoogleFonts.quicksand(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFFCBCBCB),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'What time would you like to meet?',
          style: widget.titleStyle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 42*4,
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 38,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 1.0,
            perspective: 0.0002,
            diameterRatio: 10.0,
            onSelectedItemChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onTimeChanged(_options[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _options.length,
              builder: (context, index) {
                if (index < 0 || index >= _options.length) return null;
                final key = _options[index];
                final range = _optionsMap[key] ?? '';
                final style = _styleForIndex(index);
                final rangeStyle = _styleForRange(index);

                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        key,
                        textAlign: TextAlign.center,
                        style: style,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        range,
                        textAlign: TextAlign.start,
                        style: rangeStyle,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
