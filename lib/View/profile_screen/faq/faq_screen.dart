import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.transparent,
      body: Container(
        // 🔹 Arka plan gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -1.0),
            end: Alignment(1.0, 0.9),
            colors: [
              Color(0xFFFBFCFF),
              Color(0xFFF9FAFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ÜST BAR
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: const Color(0xFFC4C4C4),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svg/arrow_back.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _subTitleForLang(lang),
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 36),
                  ],
                ),

                SizedBox(height: 32.h),

                // LİSTE
                Expanded(
                  child: asyncFaq.when(
                    data: (items) {
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          final question =
                              item.question[lang] ?? item.question['en']!;
                          final answer =
                              item.answer[lang] ?? item.answer['en']!;

                          final isExpanded = _expandedIndex == index;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _FaqQuestionCard(
                                question: question,
                                isExpanded: isExpanded,
                                onTap: () {
                                  setState(() {
                                    if (_expandedIndex == index) {
                                      _expandedIndex = null;
                                    } else {
                                      _expandedIndex = index;
                                    }
                                  });
                                },
                              ),
                              if (isExpanded) ...[
                                SizedBox(height: 6.h),
                                _FaqAnswerCard(answer: answer),
                              ],
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
      ),
    );
  }

  String _subTitleForLang(String lang) {
    switch (lang) {
      case 'tr':
        return 'Sık Sorulan Sorular';
      case 'de':
        return 'Häufig gestellte Fragen';
      default:
        return 'Frequently Asked Questions';
    }
  }
}

/// SORU KARTI
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDEDEDE), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 51.h, // 🔹 sabit yükseklik (Figma 51)
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Soru metni
                  Expanded(
                    child: Text(
                      question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700, // Bold
                        height: 1.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Up / Down arrow (SVG)
                  SvgPicture.asset(
                    isExpanded
                        ? 'assets/svg/up_arrow.svg'
                        : 'assets/svg/down_arrow.svg',
                    width: 9,
                    height: 9,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
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

/// CEVAP KARTI
class _FaqAnswerCard extends StatelessWidget {
  final String answer;

  const _FaqAnswerCard({required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 121.h, // 🔹 Figma: 121
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFDEDEDE),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: SingleChildScrollView(
        // olası uzun cevaplar için
        child: Text(
          answer,
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12, // line-height: 18px
            color: Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}
