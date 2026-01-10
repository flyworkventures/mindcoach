import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import '../constants/support_area_strings.dart';
import '../domain/profile_models.dart';

/// SupportAreaStep
/// ------------------------------------------------------------
/// Kullanıcının destek almak istediği alanı seçtiği step.
/// - State: SupportArea (enum)
/// - UI: SupportAreaStrings ile localized label gösterir
///
/// TODO(N8N):
/// - Enum → backend string mapping tek noktada yapılacak.
class SupportAreaStep extends StatefulWidget {
  const SupportAreaStep({
    super.key,
    required this.selectedSupportArea,
    required this.onSupportAreaChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final SupportArea selectedSupportArea;
  final ValueChanged<SupportArea> onSupportAreaChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  @override
  State<SupportAreaStep> createState() => _SupportAreaStepState();
}

class _SupportAreaStepState extends State<SupportAreaStep> {
  late final List<SupportArea> _options;
  late int _currentIndex;
  late FixedExtentScrollController _controller;

  int _indexForInitial() {
    final externalIndex = _options.indexOf(widget.selectedSupportArea);
    if (externalIndex != -1) return externalIndex;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _options = SupportArea.values;
    _currentIndex = _indexForInitial();
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant SupportAreaStep oldWidget) {
    super.didUpdateWidget(oldWidget);

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          SupportAreaStrings.title(context),
          style: widget.titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Expanded(
     
          child: ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 37,
            useMagnifier: true,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 1.0,
            perspective: 0.00001,
            onSelectedItemChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onSupportAreaChanged(_options[index]);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _options.length,
              builder: (context, index) {
                if (index < 0 || index >= _options.length) return null;

                final area = _options[index];
                final label = SupportAreaStrings.optionLabel(context, area);

                return Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: _styleForIndex(index),
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
