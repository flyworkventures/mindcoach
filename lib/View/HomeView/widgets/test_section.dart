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
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.takeTheTestNow,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14.w,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Text(
            l.testDescription,
            style: GoogleFonts.quicksand(
              fontSize: 12.w,
              fontWeight: FontWeight.w400,
              height: 18.h / 14.w,
              color: Color(0xFF96989C),
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
                  size: 150,
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
              const SizedBox(width: 8),
              Expanded(
                child: _TestCard(
                  title: l.areYouAnxious,
                  subtitle: AppLocalizations.of(context)!.questionsForAdults(7),
                  svgPath: 'assets/svg/anxious2.svg',
                  size: 150,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 205, // Layout -> Width: 194px
        // Height "Hug" olduğu için sabit height vermiyoruz, içindeki elemanlar kadar büyüyecek
        padding: const EdgeInsets.all(8), // Layout -> Padding: 10px
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Layout -> Radius: 16px
          border: Border.all(
            color: Colors.black.withValues(
              alpha: 0.05,
            ), // Borders -> 1px, #000000 5%
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Hug height mantığı
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim Alanı
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(16),
              child: SizedBox(
                height: size,
                width: double.infinity,
                child: SvgPicture.asset(svgPath, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 12),
            // Metin Alanı
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12, // Typography -> Size: 12px
                    fontWeight:
                        FontWeight.w600, // Typography -> Weight: 600 (SemiBold)
                    color: Colors.black, // Colors -> #000000
                    height: 16 / 12, // Typography -> Line height: 16px
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12, // Typography -> Size: 12px
                    fontWeight:
                        FontWeight.w400, // Typography -> Weight: 400 (Regular)
                    color: Color(
                      0xFF96989C,
                    ), // Colors -> Text Secondary (#96989C)
                    height: 16 / 12, // Typography -> Line height: 16px
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
