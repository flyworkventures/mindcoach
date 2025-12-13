import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_gradients.dart';

class AppTitle extends StatelessWidget {
  final String text;
  final bool gradient;
  final Color solidColor;

  const AppTitle({
    super.key,
    this.text = 'Mind Coach',
    this.gradient = true,
    this.solidColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final title = Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: -0.1,
        color: gradient ? Colors.white : solidColor,
      ),
    );

    if (!gradient) return title;

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return AppGradients.brandHorizontal.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      child: title,
    );
  }
}
