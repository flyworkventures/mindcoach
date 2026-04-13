import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routes/page_routes.dart';
import '../../core/utils/context_l10n_extensions.dart';
import '../../l10n/app_localizations.dart';
import 'notifiers/result_notifier.dart';
import 'notifiers/test_flow_notifier.dart';

class TestResultScreen extends ConsumerStatefulWidget {
  final Map<int, int> results;

  const TestResultScreen({super.key, required this.results});

  @override
  ConsumerState<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends ConsumerState<TestResultScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      final l10n = context.l10n;

      ref
          .read(resultProvider.notifier)
          .compute(
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
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF21BC87)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Figma arkaplanı bembeyaz
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        PageRoutes.navbar,
                        (route) => false,
                      );
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    flowState.testName ?? 'Mental Test',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w400, // Medium
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- TITLE ---
            const Text(
              'Test result',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.w600, // SemiBold
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // --- MAIN CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // KART 1: SKOR KARTI
                    _ScoreCard(
                      score: resultState.score,
                      level: resultState.level,
                      description: resultState.description,
                    ),
                    const SizedBox(height: 12), // Kartlar arası boşluk
                    // KART 2: AÇIKLAMA METİNLERİ KARTI
                    const _AnalysisCard(),
                    const SizedBox(height: 12),

                    // KART 3: DİSCLAIMER KARTI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE8E8E8),
                        ), // 1px gri kenarlık
                      ),
                      child: Text(
                        l10n.stressAnalysisRemember,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: FontWeight.w400, // Regular
                          color: Color(0xFF96989C), // Gri ikincil renk
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // --- BOTTOM BUTTON ---
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 12),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    PageRoutes.navbar,
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 54, // Figma standardımız
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF21BC87,
                    ), // Tasarımdaki yeşil (Ana ton)
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Back to Home', // veya l10n.backToHome
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w600, // SemiBold
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
// SKOR KARTI WIDGET'I
// ============================================================================
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ), // Hafif gri kenarlık
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _ModernCircularProgress(score)),
          const SizedBox(height: 32),

          Text.rich(
            TextSpan(
              text: l10n.yourStressLevelPrefix,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.w400, // Regular
                color: Colors.black,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: level, // "Moderate stress"
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w700, // Bold
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description, // "Thank you for completing the test..."
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w400, // Regular
              color: Color(0xFF96989C), // Text Secondary
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// YUVARLAK İLERLEME ÇUBUĞU WIDGET'I
// ============================================================================
// ============================================================================
// YUVARLAK İLERLEME ÇUBUĞU WIDGET'I (Custom Paint ile)
// ============================================================================
class _ModernCircularProgress extends StatelessWidget {
  const _ModernCircularProgress(this.progressValue);

  final double progressValue;

  @override
  Widget build(BuildContext context) {
    final score = progressValue.clamp(0.0, 1.0);
    const double indicatorSize = 140.0;

    return SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Çizimi Yapan Özel Painter
          CustomPaint(
            size: const Size(indicatorSize, indicatorSize),
            painter: _CircularChartPainter(
              progress: score,
              strokeWidth: 12.0,
              backgroundColor: const Color(0xFFE8E8E8), // Gri arka plan
              progressColor: const Color(0xFF2BD383), // Yeşil ilerleme
            ),
          ),
          // Ortadaki % Yazısı
          Text(
            '${(score * 100).toInt()}%',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 36,
              fontWeight: FontWeight.w500, // Medium
              color: Color(0xFF55B381), // Yazı rengi de yeşil
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularChartPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _CircularChartPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Başlangıç ve toplam açı ayarları
    // Başlangıç açısı: Yaklaşık 135 derece radyan karşılığı
    // Toplam yay uzunluğu (sweepAngle): Yaklaşık 270 derece radyan karşılığı
    const startAngle = 1.62619;
    const totalSweepAngle = 6.0000;

    // Çizgi stili
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Uçları yuvarlak

    // Ne kadarlık bir açı yeşil olacak?
    final progressSweepAngle = totalSweepAngle * progress;

    // Yeşil ve gri parçalar arasındaki boşluk miktarı (Radyan cinsinden)
    // Değeri artırırsan boşluk büyür, azaltırsan boşluk küçülür.
    const gapAngle = 0.4;

    // 1. İLERLEME ÇEMBERİNİ (YEŞİL) ÇİZ
    paint.color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweepAngle,
      false,
      paint,
    );

    // 2. GERİ KALAN ÇEMBERİ (GRİ) ÇİZ
    // Eğer ilerleme %100 değilse gri kısmı çiz
    if (progress < 1.0) {
      // Gri kısım, yeşil kısmın bittiği yerden "gapAngle" kadar sonrasında başlar
      final remainingStartAngle = startAngle + progressSweepAngle + gapAngle;

      // Gri kısmın uzunluğu, toplam uzunluktan (yeşil uzunluk + boşluklar) çıkarılarak bulunur
      // Çemberin sonunda da aynı boşluktan olsun diye 1 tane daha gapAngle çıkartıyoruz.
      // Eğer boşluktan dolayı negatif değer çıkarsa (çok yüksek yüzdelerde) 0'a sabitliyoruz.
      double remainingSweepAngle =
          totalSweepAngle - progressSweepAngle - (gapAngle * 1);

      if (remainingSweepAngle > 0) {
        paint.color = backgroundColor;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          remainingStartAngle,
          remainingSweepAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircularChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// DETAYLI ANALİZ KARTI WIDGET'I
// ============================================================================
class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final baseStyle = const TextStyle(
      fontFamily: 'Geist',
      fontSize: 13,
      fontWeight: FontWeight.w400, // Regular
      color: Color(0xFF96989C), // Gri ikincil renk
      height: 1.2,
    );
    final boldStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 13,
      color: Color(0xFF96989C),
      height: 1.2,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Radius 16px
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // l10n dosyasındaki çevirilere göre bu yapıyı koruduk,
          // Eğer tek bir string geliyorsa ona göre düzenlenebilir.
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
          ),
          const SizedBox(height: 16),
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
          ),
        ],
      ),
    );
  }
}
