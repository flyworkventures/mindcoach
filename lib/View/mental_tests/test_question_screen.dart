import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/test_questions_model.dart';
import '../../core/routes/page_routes.dart';
import '../../l10n/app_localizations.dart';
import 'data/test_answers_helpers.dart';
import 'data/test_questions_helpers.dart';
import 'notifiers/test_flow_notifier.dart';
import 'notifiers/test_question_notifier.dart';

class TestQuestionScreen extends ConsumerWidget {
  const TestQuestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final flowState = ref.watch(testFlowProvider);
    final qState = ref.watch(testQuestionProvider);

    final testName = flowState.testName ?? l10n.statusAssessmentTest;
    final totalFromFlow = (flowState.totalQuestions == 0)
        ? 7
        : flowState.totalQuestions;

    final answerOptions = buildAnswerOptionsL10n(context);
    final questions = buildQuestionsL10n(
      context,
      testTitle: flowState.testTitle ?? l10n.stressScaleTest,
      totalQuestions: totalFromFlow,
      seed: flowState.questionSeed,
    );

    final total = totalFromFlow.clamp(1, questions.length);
    final currentIndex = qState.currentIndex.clamp(1, total);
    final Question currentQuestion = questions[currentIndex - 1];

    final selectedIndex = qState.selectedAnswers[currentQuestion.id];

    return Scaffold(
      backgroundColor: Colors.white, // Tasarımdaki bembeyaz arkaplan
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    // İlk sorudaysa komple ekrandan çıksın, değilse bir önceki soruya dönsün
                    onTap: () {
                      if (currentIndex > 1) {
                        ref
                            .read(testQuestionProvider.notifier)
                            .goToQuestion(currentIndex - 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    testName, // Örn: Mental Test
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // --- PROGRESS BAR (Kesik çizgiler) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(total, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index == total - 1 ? 0 : 8,
                      ),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index < currentIndex
                            ? const Color(0xFF21BC87) // Dolu yeşil
                            : const Color(0xFFE8E8E8), // Boş gri
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // --- MAIN CONTENT (Soru ve Seçenekler) ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SORU METNİ
                    Text(
                      '${currentQuestion.id}. ${currentQuestion.text}',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w500, // Medium
                        color: Colors.black,
                        height: 24 / 16, // Line height 24px
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SEÇENEKLER LİSTESİ
                    Column(
                      children: List.generate(answerOptions.length, (i) {
                        final bool isSelected = (selectedIndex == i);
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(testQuestionProvider.notifier)
                                .selectAnswer(
                                  questionId: currentQuestion.id,
                                  answerIndex: i,
                                );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56, // Figma Hug(56px)
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                10,
                              ), // Radius 10px
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF21BC87) // Seçiliyse yeşil
                                    : Colors.black.withValues(
                                        alpha: 0.05,
                                      ), // Değilse 5% siyah
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  answerOptions[i],
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600, // SemiBold
                                    color: Colors.black,
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? const Color(0xFF21BC87)
                                      : const Color(0xFFBFBFBF),
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    // QUESTION 1 OF 7
                    Center(
                      child: Text(
                        l10n.numberOfQuestions(
                          currentIndex,
                          questions.length,
                        ), // Veya statik 'Question $currentIndex of $total'
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w500, // Medium
                          color: Color(0xFF96989C), // Text Secondary
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- BOTTOM BUTTONS (Alt Alta Back ve Continue) ---
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
              child: Column(
                children: [
                  // BACK BUTTON
                  GestureDetector(
                    onTap: () {
                      if (currentIndex > 1) {
                        ref
                            .read(testQuestionProvider.notifier)
                            .goToQuestion(currentIndex - 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E2E2), // Gri ince kenarlık
                          width: 1,
                        ),
                      ),
                      child: Text(
                        l10n.back,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 18,
                          fontWeight: FontWeight.w600, // SemiBold
                          color: Color(0xFF96989C), // Gri Text
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CONTINUE BUTTON
                  GestureDetector(
                    onTap: () {
                      // Eğer hiçbir seçenek seçilmemişse ilerlemeye izin verme
                      if (selectedIndex == null) return;

                      final nextIndex = currentIndex + 1;
                      if (nextIndex <= total) {
                        ref
                            .read(testQuestionProvider.notifier)
                            .goToQuestion(nextIndex);
                      } else {
                        Navigator.pushNamed(
                          context,
                          PageRoutes.testResultScreen,
                          arguments: qState.selectedAnswers,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // Seçim yapılmadıysa buton biraz soluk görünebilir (opsiyonel)
                        color: selectedIndex != null
                            ? const Color(0xFF21BC87)
                            : const Color(0xFF21BC87).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        l10n.continueButton,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 18,
                          fontWeight: FontWeight.w600, // SemiBold
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
