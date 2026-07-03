import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/revenuecat_paywalls.dart';

class PremiumCard extends ConsumerWidget {
  const PremiumCard({super.key});

  static const _accentGreen = Color(0xFF2BD383);
  static const _cardDark = Color(0xFF17281E);
  static const _primaryGreen = Color(0xFF21BC87);
  static const _glowGreen = Color(0xFF13CF76);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(AllProviders.premiumProvider);
    final l = context.l10n;

    if (premiumState.isPurchased) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () async {
          final isGuest =
              (ref.read(AllProviders.userProvider)?.credential ?? '')
                  .toLowerCase() ==
              'guest';
          await presentPaywallForUser(context, isGuest: isGuest);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const RadialGradient(
              center: Alignment.topRight,
              radius: 1.1,
              colors: [_accentGreen, _cardDark],
            ),
            boxShadow: const [
              BoxShadow(
                color: _glowGreen,
                blurRadius: 14,
                offset: Offset(0, 0),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                decoration: BoxDecoration(
                  color: _primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset('assets/icons/ic_king.svg'),
                    const SizedBox(width: 6),
                    const Text(
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
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 32 / 24,
                  ),
                  children: [
                    TextSpan(text: l.premiumHeadlinePart1),
                    TextSpan(
                      text: l.premiumHeadlineHighlight,
                      style: const TextStyle(color: _accentGreen),
                    ),
                    TextSpan(text: l.premiumHeadlinePart2),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l.premiumSubtitle,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 18 / 14,
                ),
              ),
              const SizedBox(height: 10),
              _featureRow(l.premiumFeature1),
              const SizedBox(height: 8),
              _featureRow(l.premiumFeature2),
              const SizedBox(height: 8),
              _featureRow(l.premiumFeature3),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
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
                                  color: _accentGreen,
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
                            color: _accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.premiumCta,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 22 / 18,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/icons/ic_rightt.svg',
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
        SvgPicture.asset('assets/icons/ic_tick-circle.svg'),
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
