import 'package:flutter/material.dart';

import '../../../../core/utils/screen_size_extensions.dart';
import '../constants/success_strings.dart';

class SuccessStep extends StatelessWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const SuccessStep({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SuccessCircleIcon(size: 100),
        const SizedBox(height: 30),
        Text(
          SuccessStrings.title(context),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          SuccessStrings.subtitle(context),
          style: subtitleStyle,
          textAlign: TextAlign.center,

        ),
      ],
    );
  }
}

class SuccessCircleIcon extends StatelessWidget {
  final double size;

  const SuccessCircleIcon({
    super.key,
    this.size = 102,
  });

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF2BD383);

    return SizedBox(
      width: 102.w,
      height: 102.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft dış halka
          Container(
            width: 102.w,
            height: 102.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withValues(alpha: 0.2),
            ),
          ),

          // İç halo + check
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withValues(alpha: 0.05),
              border: Border.all(
                color: green,
                width: size * 0.08,
              ),
            ),
            child: CustomPaint(
              painter: _SmoothCheckPainter(color: green),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothCheckPainter extends CustomPainter {
  final Color color;

  _SmoothCheckPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round      // köşeleri yumuşak yapar
      ..strokeJoin = StrokeJoin.round;   // bağlantılar yumuşak

    final path = Path();
    path.moveTo(size.width * 0.28, size.height * 0.52);
    path.lineTo(size.width * 0.44, size.height * 0.68);
    path.lineTo(size.width * 0.72, size.height * 0.36);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
