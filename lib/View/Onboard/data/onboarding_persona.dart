import 'package:flutter/material.dart';

class OnboardingPersona {
  final String imagePath;

  const OnboardingPersona({
    required this.imagePath,
  });
}

// ÜSTTEKİ GÖSTERGE (DOT/BAR)
class PageIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;

  const PageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
  });

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
            color: isActive
                ? const Color(0xFF2BD383) // yeşil accent
                : const Color(0xFFd9d9d9),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }
}

