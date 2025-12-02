import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportAreaStep extends StatefulWidget {
  final String selectedSupportArea;
  final ValueChanged<String> onSupportAreaChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const SupportAreaStep({
    super.key,
    required this.selectedSupportArea,
    required this.onSupportAreaChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  State<SupportAreaStep> createState() => _SupportAreaStepState();
}

class _SupportAreaStepState extends State<SupportAreaStep> {
  final List<String> _options = const [
    'Individual',
    'Family',
    'Career',
    'Education',
    'Personal Development',
  ];

  late int _currentIndex;
  late FixedExtentScrollController _controller;

  int _indexForInitial() {
    // Dışarıdan gelen değer listede yoksa Career'e düş
    final externalIndex = _options.indexOf(widget.selectedSupportArea);
    if (externalIndex != -1) return externalIndex;

    final careerIndex = _options.indexOf('Career');
    return careerIndex == -1 ? 0 : careerIndex;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexForInitial();
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant SupportAreaStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Parent seçili alanı dışarıdan değiştirirse (teorik olarak)
    if (oldWidget.selectedSupportArea != widget.selectedSupportArea) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'In which area would you like to receive support?',
          style: widget.titleStyle,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Picker alanı — yüksekliği sabitle, overflow’u kes
        SizedBox(
          height: 160,
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 37,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 1.0,
            perspective: 0.002, // hafif 3D hissi, istersen 0.0 yaparsın tamamen flat
            onSelectedItemChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onSupportAreaChanged(_options[index]);
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
