import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/locale_font_scaler.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

class PremiumPlanSection extends StatelessWidget {
  const PremiumPlanSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Padding(
      padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Premium!',
            style: GoogleFonts.quicksand(
              fontSize: 17.w,
              fontWeight: FontWeight.w700,
              height: 24.h / 17.w,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 15.h),
          Container(
            width: 331.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13.w),
              border: Border.all(color: AppColors.premiumCardBorder, width: 1.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5.w,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.premiumPlan,
                          style: GoogleFonts.quicksand(
                            fontSize: LocaleFontScaler.scale(context, 24),
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          l.premiumDescription,
                          style: GoogleFonts.quicksand(
                            fontSize: LocaleFontScaler.scale(context, 14),
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            color: Colors.black54,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Premium sayfası
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/svg/premium.svg',
                                  width: 18.w,
                                  height: 18.h,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.primaryGreen,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  l.upgradePlan,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 12.w,
                                    fontWeight: FontWeight.w600,
                                    height: 1.0,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    child: SvgPicture.asset(
                      'assets/svg/Isolation_Mode.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
