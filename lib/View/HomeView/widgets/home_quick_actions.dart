import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/View/specialists_screen/specialists_notifier.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/models/consultant_model.dart';

/// Quick Actions — vertical list of coaches with photo, name, job, rating, arrow.
class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  static const _silaYilmazId = 3;

  List<ConsultantModel> _quickActionConsultants(
    List<ConsultantModel> specialists,
  ) {
    final sila = specialists
        .where((s) => s.id == _silaYilmazId)
        .cast<ConsultantModel?>()
        .firstOrNull;
    final base = specialists.take(2).toList();

    if (sila == null) return base;

    final result = <ConsultantModel>[];
    for (final coach in base) {
      final isFemale = coach.roles?.contains('female') ?? false;
      if (isFemale) {
        if (!result.any((c) => c.id == sila.id)) {
          result.add(sila);
        }
      } else {
        result.add(coach);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(specialistsProvider);
    final specialists = state.specialists;

    if (specialists == null || specialists.isEmpty) {
      return const SizedBox.shrink();
    }

    final quickActions = _quickActionConsultants(specialists);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.quickActions,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 24 / 18,
            ),
          ),
          const SizedBox(height: 12),

          // Coach list
          ...quickActions.map(
            (coach) => _QuickActionCoachTile(coach: coach),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCoachTile extends ConsumerWidget {
  final ConsultantModel coach;

  const _QuickActionCoachTile({required this.coach});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = context.langCode;

    final name =
        coach.names[langCode] as String? ??
        coach.names['en'] as String? ??
        coach.names.values.first.toString();

    final jobTitle = JobConvert(coach.job, context).call();

    return GestureDetector(
      onTap: () {
        ref.read(specialistsProvider.notifier).selectSpecialist(coach.id);
        Navigator.pushNamed(
          context,
          PageRoutes.specialistDetail,
          arguments: coach,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10), // Layout -> Padding: 10px
        decoration: BoxDecoration(
          color: Colors.white, // Colors -> #FFFFFF
          borderRadius: BorderRadius.circular(16), // Layout -> Radius: 16px
          border: Border.all(
            color: Colors.black.withValues(
              alpha: 0.05,
            ), // Borders -> 1px, All sides, #000000 5%
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceBetween, // Layout -> Justify: space-between
          children: [
            Expanded(
              child: Row(
                children: [
                  // Coach photo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE8E8E8),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Transform.translate(
                        offset: const Offset(0, 4),
                        child: Image(
                          image: CachedNetworkImageProvider(coach.photoURL),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ), // Öğeler arası boşluk (sabit bırakıldı)
                  // Name + job
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14, // Typography -> Size: 14px
                            fontWeight: FontWeight
                                .w600, // Typography -> Weight: 600 (SemiBold)
                            color: Colors.black, // Colors -> #000000
                            height: 18 / 14, // Typography -> Line height: 18px
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          jobTitle,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12, // Typography -> Size: 12px
                            fontWeight: FontWeight
                                .w400, // Typography -> Weight: 400 (Regular)
                            color: Color(
                              0xFF96989C,
                            ), // Colors -> Text Secondary (#96989C)
                            height: 16 / 12, // Typography -> Line height: 16px
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sağ tarafı kapsayan Row (Rating pill + ok ikonu)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFC107), // #FFC107 @10%
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/star.svg",
                        width: 18,
                        height: 18,
                        color: Color(0xFFFFCC00),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        coach.rating.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFCC00),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset("assets/icons/ic_quick.svg"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
