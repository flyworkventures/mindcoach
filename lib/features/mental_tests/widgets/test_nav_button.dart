import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/screen_size_extensions.dart';
import '../constants/test_colors.dart';

class TestNavButton extends StatelessWidget {
  const TestNavButton({
    super.key,
    required this.text,
    required this.isPrimary,
    required this.isEnabled,
    required this.onTap,
    required this.iconPath,
  });

  final String text;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback onTap;
  final String iconPath;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? TestColors.brandPrimaryGreen : Colors.transparent;
    final textColor = isPrimary ? Colors.white : TestColors.textPrimary;
    final borderColor = isPrimary ? Colors.transparent : TestColors.brandPrimaryGreen;

    const double horizontalPadding = 18.0;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 159.w,
          height: 44.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(50.w),
            border: Border.all(color: borderColor, width: 1.w),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 13.w,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
              if (!isPrimary)
                Positioned(
                  left: horizontalPadding.w,
                  child: SvgPicture.asset(
                    iconPath,
                    width: 10.w,
                    colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                  ),
                ),
              if (isPrimary)
                Positioned(
                  right: horizontalPadding.w,
                  child: SvgPicture.asset(
                    iconPath,
                    width: 10.w,
                    colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
