import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/meeting_time_constants.dart';
import '../domain/profile_models.dart';

/// MeetingTimeStep
/// ------------------------------------------------------------
/// Kullanıcının tercih ettiği görüşme zaman aralığını seçtiği step.
/// - State: MeetingTime (enum)
/// - UI: MeetingTimeStrings ile localized label + range gösterir
///
/// TODO(N8N):
/// - Bu enum server payload’ına mapper ile çevrilecek (swap kolay)
class MeetingTimeStep extends StatefulWidget {
  const MeetingTimeStep({
    super.key,
    required this.selectedTime,
    required this.onTimeChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final MeetingTime selectedTime;
  final ValueChanged<MeetingTime> onTimeChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  @override
  State<MeetingTimeStep> createState() => _MeetingTimeStepState();
}

class _MeetingTimeStepState extends State<MeetingTimeStep> {
  late final List<MeetingTime> _options;
  late int _currentIndex;
  late FixedExtentScrollController _controller;

  int _indexForInitial() {
    final externalIndex = _options.indexOf(widget.selectedTime);
    if (externalIndex != -1) return externalIndex;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _options = MeetingTime.values;
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
      return GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: Colors.black,
      );
    } else if (diff == 1) {
      return GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: const Color(0xFF8E8E8E),
      );
    } else {
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
      return GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.0,
        color: Colors.black,
      );
    } else if (diff == 1) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          MeetingTimeStrings.title(context),
          style: widget.titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42 * 4,
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 38,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 1.0,
            perspective: 0.0002,
            diameterRatio: 10.0,
            onSelectedItemChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onTimeChanged(_options[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _options.length,
              builder: (context, index) {
                if (index < 0 || index >= _options.length) return null;

                final time = _options[index];
                final label = MeetingTimeStrings.label(context, time);
                final range = MeetingTimeStrings.range(context, time);

                final style = _styleForIndex(index);
                final rangeStyle = _styleForRange(index);

                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(label, style: style),
                      const SizedBox(width: 6),
                      Text(range, style: rangeStyle),
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
