import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/page_routes.dart';
import '../../core/utils/context_l10n_extensions.dart';
import '../../core/utils/screen_size_extensions.dart';
import '../../l10n/app_localizations.dart';

import 'constants/test_colors.dart';
import 'notifiers/result_notifier.dart';
import 'notifiers/test_flow_notifier.dart';

class TestResultScreen extends ConsumerStatefulWidget {
  final Map<int, int> results;

  const TestResultScreen({
    super.key,
    required this.results,
  });

  @override
  ConsumerState<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends ConsumerState<TestResultScreen> {
  @override
  void initState() {
    super.initState();

    // Provider update build sırasında değil, build sonrası çalışsın.
    Future.microtask(() {
      if (!mounted) return;

      final l10n = context.l10n;

      ref.read(resultProvider.notifier).compute(
        answers: widget.results,
        levelResolver: (score) {
          if (score < 0.35) return l10n.stressLevelLow;
          if (score < 0.65) return l10n.stressLevelModerate;
          return l10n.stressLevelHigh;
        },
        descriptionResolver: (score) {
          if (score < 0.35) return l10n.stressLevelLowDescription;
          if (score < 0.65) return l10n.stressLevelModerateDescription;
          return l10n.stressLevelHighDescription;
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final flowState = ref.watch(testFlowProvider);
    final resultState = ref.watch(resultProvider);

    if (resultState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenTitle = flowState.testTitle ?? l10n.stressScaleTitle;

    return Scaffold(
      body: Container(
        color: TestColors.pageBackground,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 30.h, bottom: 10.h),
                child: Text(
                  screenTitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 20.w,
                    fontWeight: FontWeight.w700,
                    color: TestColors.textPrimary,
                    height: 24 / 20,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      _ResultCard(
                        score: resultState.score,
                        level: resultState.level,
                        description: resultState.description,
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: () {
                      // İstersen burada da clear/reset yapabilirsin:
                      // ref.read(resultProvider.notifier).clear();
                      // ref.read(testFlowProvider.notifier).reset();

                      Navigator.of(context).pushNamedAndRemoveUntil(
                        PageRoutes.navbar,
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TestColors.brandPrimaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.w),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.backToHome,
                      style: GoogleFonts.poppins(
                        fontSize: 15.w,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.score,
    required this.level,
    required this.description,
  });

  final double score;
  final String level;
  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(29.w),
        border: Border.all(
          color: const Color(0xFFC4C4C4).withValues(alpha: 0.61),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _ModernCircularProgress(score)),
          SizedBox(height: 30.h),

          Center(
            child: Text.rich(
              TextSpan(
                text: l10n.yourStressLevelPrefix,
                style: GoogleFonts.quicksand(
                  fontSize: 17.w,
                  fontWeight: FontWeight.w500,
                  color: TestColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: level,
                    style: GoogleFonts.quicksand(
                      fontSize: 17.w,
                      fontWeight: FontWeight.w700,
                      color: TestColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // İstersen description'ı burada direkt gösterebilirsin:
          // Center(
          //   child: Text(
          //     description,
          //     textAlign: TextAlign.center,
          //     style: GoogleFonts.quicksand(
          //       fontSize: 14.w,
          //       fontWeight: FontWeight.w500,
          //       color: TestColors.textPrimary,
          //       height: 1.4,
          //     ),
          //   ),
          // ),

          _AnalysisText(),
        ],
      ),
    );
  }
}

class _ModernCircularProgress extends StatelessWidget {
  const _ModernCircularProgress(this.progressValue);

  final double progressValue;

  @override
  Widget build(BuildContext context) {
    final score = progressValue.clamp(0.0, 1.0);
    const indicatorSize = 180.0;
    const innerPadding = 15.0;

    return SizedBox(
      width: indicatorSize.w,
      height: indicatorSize.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: indicatorSize.w - innerPadding.w,
            height: indicatorSize.w - innerPadding.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TestColors.brandPrimaryGreen.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(
            width: indicatorSize.w - innerPadding.w,
            height: indicatorSize.w - innerPadding.w,
            child: CircularProgressIndicator(
              value: score,
              strokeWidth: 14.w,
              backgroundColor: TestColors.passiveGray.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation<Color>(
                TestColors.brandPrimaryGreen,
              ),
            ),
          ),
          Text(
            '${(score * 100).toInt()}%',
            style: GoogleFonts.quicksand(
              fontSize: 40.w,
              fontWeight: FontWeight.w700,
              color: TestColors.brandPrimaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final baseStyle = GoogleFonts.quicksand(
      fontSize: 15.w,
      fontWeight: FontWeight.w300,
      color: Colors.black,
      height: 1.5,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 15.h),
        Text(
          l10n.stressAnalysisIntro,
          textAlign: TextAlign.center,
          style: baseStyle,
        ),
        SizedBox(height: 20.h),

        Text.rich(
          TextSpan(
            text: l10n.stressAnalysisP1Part1,
            style: baseStyle,
            children: [
              TextSpan(text: l10n.stressAnalysisP1Bold1, style: boldStyle),
              TextSpan(text: l10n.stressAnalysisP1Part2, style: baseStyle),
              TextSpan(text: l10n.stressAnalysisP1Bold2, style: boldStyle),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),

        Text.rich(
          TextSpan(
            text: l10n.stressAnalysisP2Part1,
            style: baseStyle,
            children: [
              TextSpan(text: l10n.stressAnalysisP2Bold1, style: boldStyle),
              TextSpan(text: l10n.stressAnalysisP2Part2, style: baseStyle),
              TextSpan(text: l10n.stressAnalysisP2Bold2, style: boldStyle),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),

        Container(
          width: double.infinity,
          height: 1.0,
          color: const Color(0xFFDEDEDE),
        ),
        SizedBox(height: 20.h),

        Text(
          l10n.stressAnalysisRemember,
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: 13.w,
            fontWeight: FontWeight.w300,
            color: TestColors.textPrimary,
            height: 15 / 13,
          ),
        ),
      ],
    );
  }
}
