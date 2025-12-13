import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/screen_size_extensions.dart';
import '../constants/test_colors.dart';

class TestHeader extends StatelessWidget {
  const TestHeader({
    super.key,
    required this.title,
    this.onBack,
    this.compact = false,
  });

  final String title;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: compact ? 10.h : 0,
        bottom: 10.h,
        left: 24.w,
        right: 24.w,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack ?? () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(34.w / 2),
            child: Container(
              width: compact ? 32.w : 34.w,
              height: compact ? 32.h : 34.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.0),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/arrow_back.svg',
                  width: compact ? 10.w : 12.w,
                  colorFilter: const ColorFilter.mode(
                    TestColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 17.w,
              fontWeight: FontWeight.w700,
              color: TestColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
