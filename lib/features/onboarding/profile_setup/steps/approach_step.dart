import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApproachStep extends StatefulWidget {
  final String selectedApproach;
  final ValueChanged<String> onApproachChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const ApproachStep({
    super.key,
    required this.selectedApproach,
    required this.onApproachChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  State<ApproachStep> createState() => _ApproachStepState();
}

class _ApproachStepState extends State<ApproachStep> {
  final List<String> _options = const [
    'Patient',
    'Supportive',
    'Convincing',
    'Energetic',
    'Humorous',
  ];

  late int _currentIndex;
  late FixedExtentScrollController _controller;

  int _indexForInitial() {
    // Dışarıdan gelen değer listede yoksa Supportive'e düş
    final externalIndex = _options.indexOf(widget.selectedApproach);
    if (externalIndex != -1) return externalIndex;

    final fallbackIndex = _options.indexOf('Supportive');
    return fallbackIndex == -1 ? 0 : fallbackIndex;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexForInitial();
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant ApproachStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedApproach != widget.selectedApproach) {
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
      // İki üst / iki alt
      return GoogleFonts.quicksand(
        fontSize: 12,
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
          'How would you like the specialist to approach you?',
          style: widget.titleStyle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

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
              widget.onApproachChanged(_options[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _options.length,
              builder: (context, index) {
                if (index < 0 || index >= _options.length) return null;
                final style = _styleForIndex(index);
                return Center(
                  child: Text(
                    _options[index],
                    textAlign: TextAlign.center,
                    style: style,
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
