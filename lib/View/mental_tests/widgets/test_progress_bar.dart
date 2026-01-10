import 'package:flutter/material.dart';
import '../constants/test_colors.dart';

class TestProgressBar extends StatelessWidget {
  const TestProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
  });

  final int currentIndex; // 1-based
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    const double spacing = 3.0;
    const double barHeight = 4.0;

    return SizedBox(
      height: barHeight,
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i < currentIndex;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : spacing),
              decoration: BoxDecoration(
                color: isActive ? TestColors.brandPrimaryGreen : TestColors.borderLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}
