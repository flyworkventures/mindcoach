import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/screen_size_extensions.dart';
import '../constants/test_colors.dart';

class TestAnswerOptionTile extends StatelessWidget {
  const TestAnswerOptionTile({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.w),
            border: Border.all(color: TestColors.borderLight, width: 1.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: GoogleFonts.quicksand(
                  fontSize: 15.w,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _darken(TestColors.brandPrimaryGreen, 10) : TestColors.textPrimary,
                  height: 20 / 15,
                ),
              ),
              _Radio(isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: isSelected ? TestColors.brandPrimaryGreen : TestColors.radioUnselected,
          width: 1.5.w,
        ),
      ),
      child: isSelected
          ? Center(
        child: Container(
          width: 11.w,
          height: 11.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: TestColors.brandPrimaryGreen,
          ),
        ),
      )
          : null,
    );
  }
}

Color _darken(Color c, int percent) {
  final f = 1 - (percent / 100);
  return Color.fromARGB(
    c.alpha,
    (c.red * f).round(),
    (c.green * f).round(),
    (c.blue * f).round(),
  );
}
