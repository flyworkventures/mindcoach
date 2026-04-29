import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AnimatedFlowBackground extends StatefulWidget {
  const AnimatedFlowBackground({super.key});

  @override
  State<AnimatedFlowBackground> createState() => _AnimatedFlowBackgroundState();
}

class _AnimatedFlowBackgroundState extends State<AnimatedFlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<Color> colors = const [
    Color(0xFF9CC7FF), // soft mavi
    Color(0xFFF1B9FF), // pembe-lila
    Color(0xFFB9FFF2), // mint / turkuazımsı
    Color(0xFFD5C8FF), // lavanta
    Color(0xFFC6E5FF), // açık mavi
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          color: Colors.grey.shade100,
          child: Stack(
            children: [
              // Blobların base pozisyonları biraz yukarı kayık
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(
                        0,
                        -0.5,
                      ), // tam ortadan biraz yukarı
                      radius: 0.85,
                      colors: [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Alt tarafı ve kenarları hafif yumuşatan overlay (renkleri öldürmeden)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),

              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),

              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 8),
                child: Container(color: Colors.white.withValues(alpha: 0.04)),
              ),

              /// deneme amaçlı koydum bu olmayabilir
              Center(child: Lottie.asset('assets/json/setup_animation.json')),
            ],
          ),
        );
      },
    );
  }
}
