import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import 'provider/faq_provider.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final asyncFaq = ref.watch(faqListProvider);
    final lang = Localizations.localeOf(context).languageCode; // en / tr / de

    return Scaffold(
      backgroundColor: Colors.white, // Figma arka planı temiz beyaz
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ÜST BAR (Geri Butonu ve Başlık) ---
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset('assets/icons/ic_bakc.svg'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.faq,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w400, // Regular
                      height: 1.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 28.h),

              // --- F.A.Q. LİSTESİ ---
              Expanded(
                child: asyncFaq.when(
                  data: (items) {
                    return ListView.separated(
                      physics: ClampingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final item = items[index];

                        final question =
                            item.question[lang] ?? item.question['en']!;
                        final answer = item.answer[lang] ?? item.answer['en']!;

                        final isExpanded = _expandedIndex == index;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // SORU KARTI
                            _FaqQuestionCard(
                              question: question,
                              isExpanded: isExpanded,
                              onTap: () {
                                setState(() {
                                  if (_expandedIndex == index) {
                                    _expandedIndex = null; // Zaten açıksa kapat
                                  } else {
                                    _expandedIndex = index; // Seçileni aç
                                  }
                                });
                              },
                            ),

                            // CEVAP KARTI (Animasyonlu Açılış/Kapanış)
                            AnimatedCrossFade(
                              firstChild: const SizedBox(
                                width: double.infinity,
                                height: 0,
                              ),
                              secondChild: Column(
                                children: [
                                  SizedBox(
                                    height: 10.h,
                                  ), // Kartlar arası gap 10px
                                  _FaqAnswerCard(answer: answer),
                                ],
                              ),
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 250),
                              sizeCurve: Curves.fastOutSlowIn,
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Something went wrong.\n${err.toString()}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// YEREL WIDGET'LAR
// -----------------------------------------------------------------------------

/// SORU KARTI WIDGET'I
class _FaqQuestionCard extends StatelessWidget {
  final String question;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqQuestionCard({
    required this.question,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50.h, // Figma'daki Fixed Height: 50px
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Figma Radius: 16px
          border: Border.all(
            color: const Color(0xFFE2E2E2), // Border Color: #E2E2E2
            width: 2, // Border Width: 2px
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Justify: space-between
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Soru Metni
            Expanded(
              child: Text(
                question,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w700, // Bold
                  height: 1.0,
                  color: Color(0xFF96989C), // Text Secondary (#96989C)
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Animasyonlu Yön Oku
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0, // 180 derece döner
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              child: SvgPicture.asset('assets/icons/ic_down.svg'),
            ),
          ],
        ),
      ),
    );
  }
}

/// CEVAP KARTI WIDGET'I
class _FaqAnswerCard extends StatelessWidget {
  final String answer;

  const _FaqAnswerCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Soruyla aynı ovallikte
        border: Border.all(
          color: const Color(0xFFE2E2E2), // Aynı Border: #E2E2E2
          width: 2, // 2px border
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(
        answer,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          fontWeight: FontWeight.w400, // Regular
          height: 18 / 12, // Figma Line Height: 18px (1.5)
          color: Color(0xFF96989C), // Text Secondary (#96989C)
        ),
      ),
    );
  }
}
