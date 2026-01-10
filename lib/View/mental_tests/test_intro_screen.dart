import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/page_routes.dart';
import '../../core/utils/screen_size_extensions.dart';
import '../../l10n/app_localizations.dart';

import 'constants/test_colors.dart';
import 'notifiers/test_flow_notifier.dart';
import 'widgets/test_header.dart';

class TestIntroScreen extends ConsumerWidget {
  final String testName;
  final String testTitle;
  final String imagePath;
  final int totalQuestions;

  const TestIntroScreen({
    super.key,
    required this.testName,
    required this.testTitle,
    required this.imagePath,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: TestColors.pageBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: TestColors.pageBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TestHeader(title: testName),

                  SizedBox(height: 36.h),

                  // Title + questions count
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          testTitle,
                          style: GoogleFonts.quicksand(
                            fontSize: 20.w,
                            fontWeight: FontWeight.w700,
                            height: 24 / 20,
                            color: TestColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        l10n.questionsForAdults(totalQuestions),
                        style: GoogleFonts.quicksand(
                          fontSize: 14.w,
                          fontWeight: FontWeight.w500,
                          height: 18 / 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Card
                  Center(
                    child: Container(
                      width: 323.w,
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(29.w),
                        border: Border.all(color: TestColors.cardBorderSoft, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13.w),
                            child: SvgPicture.asset(imagePath, height: 150.h),
                          ),
                          SizedBox(height: 25.h),
                          _RuleList(rules: [l10n.testRule1, l10n.testRule2, l10n.testRule3]),
                          SizedBox(height: 15.h),
                          const Divider(color: TestColors.borderLight, thickness: 1.0),
                          SizedBox(height: 10.h),
                          Text(
                            l10n.testDisclaimer,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.quicksand(
                              fontSize: 13.w,
                              fontWeight: FontWeight.w300,
                              height: 15 / 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Continue
                  Center(
                    child: InkWell(
                      onTap: () {
                        ref.read(testFlowProvider.notifier).initTest(
                          testName: testName,
                          testTitle: testTitle,
                          imagePath: imagePath,
                          totalQuestions: totalQuestions,
                        );

                        Navigator.pushNamed(context, PageRoutes.testQuestionScreen);
                      },
                      child: Container(
                        width: 317.w,
                        height: 44.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TestColors.brandPrimaryGreen,
                          borderRadius: BorderRadius.circular(50.w),
                        ),
                        child: Text(
                          l10n.continueButton,
                          style: GoogleFonts.quicksand(
                            fontSize: 17.w,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleList extends StatelessWidget {
  const _RuleList({required this.rules});
  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules.map((rule) {
        final parts = rule.split('**');
        return Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 5.h, right: 8.w),
                width: 4.w,
                height: 4.h,
                decoration: const BoxDecoration(
                  color: TestColors.textPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.quicksand(
                      fontSize: 15.w,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                      color: TestColors.textPrimary,
                    ),
                    children: [
                      for (var i = 0; i < parts.length; i++)
                        TextSpan(
                          text: parts[i],
                          style: GoogleFonts.quicksand(
                            fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 15.w,
                            height: 20 / 15,
                            color: TestColors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
