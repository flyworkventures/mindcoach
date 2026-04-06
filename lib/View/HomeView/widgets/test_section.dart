import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/l10n/app_localizations.dart';

class TestSection extends StatelessWidget {
  const TestSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Padding(
      padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.takeTheTestNow,
            style: GoogleFonts.quicksand(
              fontSize: 17.w,
              fontWeight: FontWeight.w700,
              height: 24.h / 17.w,
              color: Colors.black,
            ),
          ),
          Text(
            l.testDescription,
            style: GoogleFonts.quicksand(
              fontSize: 14.w,
              fontWeight: FontWeight.w500,
              height: 18.h / 14.w,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 15.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _TestCard(
                  title: l.areYouStressed,
                  subtitle: AppLocalizations.of(context)!.questionsForAdults(7),
                  svgPath: 'assets/svg/stressed2.svg',
                  size: 122,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      PageRoutes.testIntroScreen,
                      arguments: {
                        'testName': l.statusAssessmentTest,
                        'testTitle': l.stressScaleTest,
                        'imagePath': 'assets/svg/stressed.svg',
                        'totalQuestions': 7,
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TestCard(
                  title: l.areYouAnxious,
                  subtitle: AppLocalizations.of(context)!.questionsForAdults(7),
                  svgPath: 'assets/svg/anxious2.svg',
                  size: 120,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      PageRoutes.testIntroScreen,
                      arguments: {
                        'testName': l.statusAssessmentTest,
                        'testTitle': l.anxietyScaleTest,
                        'imagePath': 'assets/svg/anxious.svg',
                        'totalQuestions': 7,
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.title,
    required this.subtitle,
    required this.svgPath,
    required this.onTap,
    required this.size,
  });

  final String title;
  final String subtitle;
  final String svgPath;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cardRadius = 13.w;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 154.w,
        height: 190.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: size,
              width: double.infinity,
              child: SvgPicture.asset(svgPath, fit: BoxFit.contain),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 12.w,
                    fontWeight: FontWeight.w700,
                    height: 24.h / 12.w,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 10.w,
                    fontWeight: FontWeight.w500,
                    height: 1.w,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
