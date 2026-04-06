import 'package:flutter/material.dart';


class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
  });

  final int itemCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          height: 3,
          width: isActive ? 33 : 12,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF2BD383) : const Color(0xFFd9d9d9),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }
}
