import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/routes/page_routes.dart';
import '../../l10n/app_localizations.dart';
import 'notifiers/test_flow_notifier.dart';

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
                    onTap: () => Navigator.pop(context),
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

            const SizedBox(height: 24),

            // --- TITLE & SUBTITLE ---
            Text(
              testTitle, // Örn: Stress scale test
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.w600, // SemiBold
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.questionsForAdults(
                totalQuestions,
              ), // Örn: 7 Questions for Adults
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w500, // Medium
                color: Color(0xFF96989C), // Gri ikincil renk
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // --- MAIN CARD ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.03,
                        ), // Çok hafif gölge
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Illustration
                      SvgPicture.asset(
                        imagePath, // Örn: 'assets/svg/stressed.svg'
                        height: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),

                      // Rules List
                      _RuleList(
                        rules: [l10n.testRule1, l10n.testRule2, l10n.testRule3],
                      ),

                      const SizedBox(height: 24),
                      const Divider(
                        color: Color(0xFFE8E8E8),
                        thickness: 1.0,
                        height: 1,
                      ),
                      const SizedBox(height: 24),

                      // Disclaimer Text
                      Text(
                        l10n.testDisclaimer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          fontWeight: FontWeight.w300, // Light
                          color: Color(0xFF96989C),
                          height: 16 / 12, // Figma'daki line-height
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- BOTTOM CONTINUE BUTTON ---
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(testFlowProvider.notifier)
                      .initTest(
                        testName: testName,
                        testTitle: testTitle,
                        imagePath: imagePath,
                        totalQuestions: totalQuestions,
                      );
                  Navigator.pushNamed(context, PageRoutes.testQuestionScreen);
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF21BC87,
                    ), // Tasarımdaki yeşil ton (yaklaşık değer)
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.continueButton,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// KURALLAR LİSTESİ WIDGET'I
// ============================================================================
class _RuleList extends StatelessWidget {
  const _RuleList({required this.rules});
  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rules.map((rule) {
        // Metin içindeki kalın (bold) yapılması gereken kısımları "**" işaretinden ayırıyoruz
        final parts = rule.split('**');

        return Padding(
          padding: const EdgeInsets.only(bottom: 8), // Satırlar arası boşluk
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Madde İşareti (Nokta)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 8),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              // Metin
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w400, // Regular
                      color: Colors.black,
                      height: 20 / 14, // Figma Line Height: 20px
                    ),
                    children: [
                      for (var i = 0; i < parts.length; i++)
                        TextSpan(
                          text: parts[i],
                          style: TextStyle(
                            fontFamily: 'Geist',
                            // ** arasındaki metinler bold olacak
                            fontWeight: i.isOdd
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontSize: 14,
                            color: Colors.black,
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
