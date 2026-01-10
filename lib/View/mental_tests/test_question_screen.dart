import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/test_questions_model.dart';
import '../../core/routes/page_routes.dart';
import '../../core/utils/context_l10n_extensions.dart';
import '../../core/utils/screen_size_extensions.dart';

import 'constants/test_colors.dart';
import 'data/test_answers_helpers.dart';
import 'data/test_questions_helpers.dart';
import 'notifiers/test_flow_notifier.dart';
import 'notifiers/test_question_notifier.dart';
import 'widgets/test_header.dart';
import 'widgets/test_progress_bar.dart';
import 'widgets/test_answer_option_tile.dart';
import 'widgets/test_nav_button.dart';

class TestQuestionScreen extends ConsumerWidget {
  const TestQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final flowState = ref.watch(testFlowProvider);
    final qState = ref.watch(testQuestionProvider);

    final testName = flowState.testName ?? l10n.statusAssessmentTest;
    final totalFromFlow = (flowState.totalQuestions == 0) ? 7 : flowState.totalQuestions;

    final answerOptions = buildAnswerOptionsL10n(context);
    final questions = buildDummyQuestionsL10n(context);

    final total = totalFromFlow.clamp(1, questions.length);
    final currentIndex = qState.currentIndex.clamp(1, total);
    final Question currentQuestion = questions[currentIndex - 1];

    final selectedIndex = qState.selectedAnswers[currentQuestion.id];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: TestColors.pageBackground,
        child: SafeArea(
          child: Column(
            children: [
              TestHeader(title: testName, compact: true),

              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TestProgressBar(currentIndex: currentIndex, totalSteps: total),
                      SizedBox(height: 30.h),

                      _QuestionText(question: currentQuestion),
                      SizedBox(height: 30.h),

                      Column(
                        children: List.generate(answerOptions.length, (i) {
                          return TestAnswerOptionTile(
                            text: answerOptions[i],
                            isSelected: selectedIndex == i,
                            onTap: () {
                              ref.read(testQuestionProvider.notifier).selectAnswer(
                                questionId: currentQuestion.id,
                                answerIndex: i,
                              );
                            },
                          );
                        }),
                      ),

                      SizedBox(height: 8.h),

                      Center(
                        child: Text(
                          l10n.numberOfQuestions(currentIndex, questions.length),
                          style: GoogleFonts.quicksand(
                            fontSize: 16.w,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBFBFBF),
                            height: 24 / 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(left: 33.w, right: 33.w, bottom: 20.h, top: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TestNavButton(
                      text: l10n.back,
                      isPrimary: false,
                      isEnabled: currentIndex > 1,
                      onTap: () => ref.read(testQuestionProvider.notifier).goToQuestion(currentIndex - 1),
                      iconPath: 'assets/svg/arrow_back.svg',
                    ),
                    TestNavButton(
                      text: l10n.next,
                      isPrimary: true,
                      isEnabled: selectedIndex != null,
                      onTap: () {
                        final nextIndex = currentIndex + 1;
                        if (nextIndex <= total) {
                          ref.read(testQuestionProvider.notifier).goToQuestion(nextIndex);
                        } else {
                          Navigator.pushNamed(
                            context,
                            PageRoutes.testResultScreen,
                            arguments: qState.selectedAnswers,
                          );
                        }
                      },
                      iconPath: 'assets/svg/right_arrow.svg',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.question});
  final Question question;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${question.id}. ',
            style: GoogleFonts.quicksand(
              fontSize: 20.w,
              fontWeight: FontWeight.w700,
              color: TestColors.textPrimary,
              height: 24 / 20,
            ),
          ),
          TextSpan(
            text: question.text,
            style: GoogleFonts.quicksand(
              fontSize: 20.w,
              fontWeight: FontWeight.w700,
              color: TestColors.textPrimary,
              height: 24 / 20,
            ),
          ),
        ],
      ),
    );
  }
}
