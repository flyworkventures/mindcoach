import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/View/specialists_screen/specialists_notifier.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/models/consultant_model.dart';

/// Coach category tabs + 2-column grid cards on the home screen.
class HomeCoachesSection extends ConsumerStatefulWidget {
  const HomeCoachesSection({super.key});

  @override
  ConsumerState<HomeCoachesSection> createState() => _HomeCoachesSectionState();
}

class _HomeCoachesSectionState extends ConsumerState<HomeCoachesSection> {
  String? _selectedJob;

  @override
  void initState() {
    super.initState();
    // TODO: "exam_coach" değerini kendi veri modelindeki Sınav Kaygısı Koçu koduyla (job) değiştir.
    _selectedJob = 'exam_anxiety';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(specialistsProvider);
    final specialists = state.specialists;

    if (specialists == null || specialists.isEmpty) {
      return const SizedBox.shrink();
    }

    // Extract unique job types
    final jobTypes = specialists.map((s) => s.job).toSet().toList();

    // Sınav kaygısı koçunun her zaman ilk sırada görünmesini istiyorsan listeyi sıralayabilirsin (Opsiyonel)
    // jobTypes.remove(_selectedJob);
    // if (_selectedJob != null) jobTypes.insert(0, _selectedJob!);

    // If no filter selected, show all. Otherwise filter by selected job.
    final filtered = _selectedJob == null
        ? specialists
        : specialists
              .where((s) => s.job == _selectedJob)
              .toList()
              .take(2) // Sadece 2 tanesini göster
              .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category tabs (horizontal scroll)
          SizedBox(
            height: 36,
            child: ListView.separated(
              physics: ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: jobTypes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final job = jobTypes[index];
                final isSelected = _selectedJob == job;
                final label = JobConvert(job, context).call();

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      // Eğer seçiliyse null yapma (her zaman biri seçili kalsın)
                      // Veya tıklanınca null olmasını (tümünü göstermeyi) istiyorsan eski mantığı bırakabilirsin.
                      // _selectedJob = isSelected ? null : job;
                      _selectedJob = job;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF21BC87)
                          : Color(0xFF898989).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF21BC87)
                            : const Color(0xFFE2E2E2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF737373),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2-column grid of coach cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 170 / 280,
              ),
              itemCount: filtered.length > 4 ? 4 : filtered.length,
              itemBuilder: (context, index) {
                return _HomeCoachCard(item: filtered[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCoachCard extends ConsumerWidget {
  final ConsultantModel item;

  const _HomeCoachCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = context.langCode;
    final featureConvert = FeatureConvert(context);

    final name =
        item.names[langCode] as String? ??
        item.names['en'] as String? ??
        item.names.values.first.toString();

    final jobTitle = JobConvert(item.job, context).call();

    // Show max 2 features + remaining count
    final features = item.features;
    final visibleCount = features.length > 2 ? 2 : features.length;
    final remaining = features.length - visibleCount;

    return GestureDetector(
      onTap: () {
        ref.read(specialistsProvider.notifier).selectSpecialist(item.id);
        Navigator.pushNamed(
          context,
          PageRoutes.specialistDetail,
          arguments: item,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB6BECA).withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(item.photoURL),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 20 / 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Job title
                  Text(
                    jobTitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF96989C),
                      height: 14 / 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Feature tags
                  Row(
                    children: [
                      for (int i = 0; i < visibleCount; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Flexible(
                          child: _tag(
                            featureConvert.call(features[i].toString()),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (remaining > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: _tag(
                            featureConvert.call(
                              features[visibleCount].toString(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _tag('$remaining+', isCount: true),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Create appointment button
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(specialistsProvider.notifier)
                          .selectSpecialist(item.id);
                      Navigator.pushNamed(
                        context,
                        PageRoutes.specialistDetail,
                        arguments: item,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21BC87),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF21BC87,
                            ).withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SvgPicture.asset("assets/icons/ic_yz.svg"),
                          Spacer(),
                          Text(
                            context.l10n.coachDetailCreateAppointment,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                        ],
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

  Widget _tag(String text, {bool isCount = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCount
            ? Colors.grey[200]
            : const Color(0xFF898989).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF737373),
          height: 12 / 9,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
