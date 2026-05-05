import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/widgets/future_progress_dialog.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PremiumCard extends ConsumerWidget {
  const PremiumCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(AllProviders.premiumProvider);
    final l = context.l10n;

    if (isPremium) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () async {
          await context.runWithProgressDialog(() async {
            await RevenueCatUI.presentPaywall();
          }, message: context.l10n.pleaseWait);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF17281E),
            borderRadius: BorderRadius.circular(16),
          ),
          // 1. FIX: Ana Column'u minimum boyuta zorluyoruz
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF21BC87),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset("assets/icons/ic_king.svg"),
                    SizedBox(width: 6),
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(text: l.premiumHeadlinePart1),
                    TextSpan(
                      text: l.premiumHeadlineHighlight,
                      style: const TextStyle(color: Color(0xFF21BC87)),
                    ),
                    TextSpan(text: l.premiumHeadlinePart2),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.premiumSubtitle,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF96989C),
                ),
              ),
              const SizedBox(height: 12),
              _featureRow(l.premiumFeature1),
              const SizedBox(height: 8),
              _featureRow(l.premiumFeature2),
              const SizedBox(height: 8),
              _featureRow(l.premiumFeature3),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    // 2. FIX: Row içindeki Expanded Column'u minimuma zorluyoruz
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: l.premiumPrice,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: l.premiumPricePeriod,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF21BC87),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.premiumAnnualDiscount,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF21BC87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    // Padding: Top 10, Bottom 10, Right 20, Left 20
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      // DİKKAT: Buraya kendi koyu arka plan rengini girmelisin.
                      // Aksi takdirde gölge (shadow) butonun içini beyaz doldurur.
                      color: const Color(0xFF1B231E),
                      borderRadius: BorderRadius.circular(12), // Radius: 12px
                      border: Border.all(
                        color: Colors.white, // Border: 1px, #FFFFFF
                        width: 1,
                      ),
                      boxShadow: const [
                        // Shadows and blurs: Drop shadow, X:0, Y:0, Blur:4, #FFFFFF
                        BoxShadow(
                          color: Colors.white, // Beyaz parlama efekti
                          blurRadius: 4,
                          offset: Offset(0, 0),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.premiumCta, // Veya "Başlayın"
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 18, // Size: 18px
                            fontWeight: FontWeight.w600, // SemiBold
                            color: Colors.white, // Colors: #FFFFFF
                            height: 22 / 18, // Line height: 22px
                          ),
                        ),
                        const SizedBox(width: 8), // Gap: 8px
                        SvgPicture.asset(
                          "assets/icons/ic_rightt.svg",
                          // Ok ikonunun siyah veya başka renk kalmaması, tam beyaz olması için:
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Row(
      children: [
        SvgPicture.asset("assets/icons/ic_tick-circle.svg"),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
