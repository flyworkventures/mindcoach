import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    super.key,
    required this.userName,
    this.onTap,
  });

  final String userName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 31.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 331.w,
          height: 120.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.w),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.8726, 0.1841),
              colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
              stops: [0.1841, 0.8726],
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.w, top: 15.h, bottom: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${l.welcome}, $userName.',
                            style: GoogleFonts.quicksand(
                              fontSize: 24.w,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: '\n${l.howAreYouFeelIngToday}',
                            style: GoogleFonts.quicksand(
                              fontSize: 14.w,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.getStart,
                          style: GoogleFonts.quicksand(
                            fontSize: 15.w,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Icon(Icons.arrow_forward_ios, size: 10.w, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 5.h),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                bottom: -20.h,
                child: Image.asset(
                  'assets/chars/char2_nobg.png',
                  width: 110.w,
                  height: 140.h,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
