import 'package:flutter/material.dart';

class PillPageIndicator extends StatelessWidget {
  const PillPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.selectedColor,
    required this.unselectedColor,
    this.selectedWidth = 33,
    this.unselectedWidth = 10,
    this.height = 3,
    this.spacing = 4,
    this.animationMs = 300,
    this.borderRadius = 999,
  });

  final int count;
  final int currentIndex;
  final Color selectedColor;
  final Color unselectedColor;
  final double selectedWidth;
  final double unselectedWidth;
  final double height;
  final double spacing;
  final int animationMs;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isSelected = i == currentIndex;
        return AnimatedContainer(
          duration: Duration(milliseconds: animationMs),
          margin: EdgeInsets.symmetric(horizontal: spacing),
          width: isSelected ? selectedWidth : unselectedWidth,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isSelected ? selectedColor : unselectedColor,
          ),
        );
      }),
    );
  }
}
