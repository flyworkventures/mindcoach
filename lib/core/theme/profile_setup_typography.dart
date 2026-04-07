import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/locale_font_scaler.dart';

class ProfileSetupTypography {
  ProfileSetupTypography._();


  static TextStyle title(BuildContext context) {
    return GoogleFonts.quicksand(
      fontSize: LocaleFontScaler.scale(context, 20),
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0,
      color: const Color(0xFF1D1D1D),
    );
  }


  static TextStyle subtitle(BuildContext context) {
    return GoogleFonts.quicksand(
      fontSize: LocaleFontScaler.scale(context, 14),
      fontWeight: FontWeight.w400,
      height: 1.35,
      letterSpacing: 0,
      color: const Color(0xFF1D1D1D),
    );
  }
}
