import 'package:cached_network_image/cached_network_image.dart';
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
    // Varsayılan filtre: sınav kaygısı koçları
    _selectedJob = 'personal';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(specialistsProvider);
    final specialists = state.specialists;

    if (specialists == null || specialists.isEmpty) {
      return const SizedBox.shrink();
    }

    // API'den gelen gerçek job tiplerine göre filtre listesi oluştur
    // Önce sınav kaygısı, ortada mevcut tipler, sonda yeni rehberlik tipleri
    const jobOrder = [
      'personal',
      'exam_anxiety',
      'adult',
      'child',
      'teenage',
      'family_assistant',
      'thought_and_habit_guide',
      'emotional_balance',
      'difficult_experiences',
      'resilience_empowerment',
    ];
    final rawJobs = specialists.map((s) => s.job).toSet();
    final jobTypes = [
      ...jobOrder.where(rawJobs.contains),
      ...rawJobs.where((j) => !jobOrder.contains(j)),
    ];

    // Filtre seçiliyse sadece o job tipini göster (max 4), seçili değilse tümünü göster
    final filtered = _selectedJob == null
        ? specialists
        : specialists.where((s) => s.job == _selectedJob).toList();

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
                      // Her zaman en az bir rehber türü seçili kalsın.
                      // Aynı tipe tekrar basılsa da seçimi kaldırma.
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
    // Uzman ismini ayarla
    final specialistName =
        item.names[context.langCode] as String? ??
        item.names['en'] as String? ??
        item.names.values.first.toString();

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
          borderRadius: BorderRadius.circular(16), // Figma: Radius 16px
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
          ), // Inner border
        ),
        child: Padding(
          padding: const EdgeInsets.all(10), // Figma: Padding 10px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTOĞRAF (Yuvarlak köşe ile) - Dinamik SVG / PNG kontrolü
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    // Figma'daki arka plan gradyanı
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2BD383), // Üstteki açık gri
                          Color(0xFF166D44), // Alttaki koyu siyahımsı renk
                        ],
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final url = item.photoURL;
                        final isSvg = url.toLowerCase().endsWith('.svg');

                        // Hata durumunda çıkacak ikon
                        Widget fallbackIcon() => const Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF96989C),
                          ),
                        );

                        if (isSvg) {
                          return SvgPicture.network(
                            url,
                            fit: BoxFit.cover,
                            alignment: const Alignment(0.0, -0.8),
                            errorBuilder: (_, _, _) => fallbackIcon(),
                          );
                        } else {
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorWidget: (_, _, _) => fallbackIcon(),
                            placeholder: (_, _) => const SizedBox.shrink(),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // İSİM
              Text(
                specialistName,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 20,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Colors.black,
                  height: 28 / 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),

              // ALT BAŞLIK + RATING
              Row(
                children: [
                  Expanded(
                    child: Text(
                      JobConvert(item.job, context).call(),
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF96989C),
                        height: 16 / 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ETİKETLER (Tags) - Dynamic features
              ..._buildFeatureTags(context),

              const SizedBox(height: 12),

              // BUTON (Create an appointment)
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
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF21BC87),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF21BC87).withValues(alpha: 0.5),
                        offset: const Offset(0, 0),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        "assets/icons/ic_ic.svg",
                        width: 12,
                        height: 12,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          context.l10n.coachDetailCreateAppointment,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeatureTags(BuildContext context) {
    final featureConvert = FeatureConvert(context);
    final features = item.features;
    if (features.isEmpty) return [];

    // Show first 2 tags in first row, then 1 tag + count in second row
    final visibleCount = features.length > 3 ? 3 : features.length;
    final remaining = features.length - visibleCount;

    final firstRowCount = visibleCount >= 2 ? 2 : visibleCount;
    final secondRowCount = visibleCount > 2 ? 1 : 0;

    return [
      Row(
        children: [
          for (int i = 0; i < firstRowCount; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Flexible(
              child: _buildTag(featureConvert.call(features[i].toString())),
            ),
          ],
        ],
      ),
      if (secondRowCount > 0) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildTag(
                featureConvert.call(features[2].toString()),
                isExpanded: true,
              ),
            ),
            if (remaining > 0) ...[
              const SizedBox(width: 4),
              _buildTag('$remaining+', isCount: true),
            ],
          ],
        ),
      ],
    ];
  }

  // Ufak gri etiketler (Tags) için yardımcı widget
  Widget _buildTag(
    String text, {
    bool isExpanded = false,
    bool isCount = false,
  }) {
    final tagWidget = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Figma: Padding 4px Top/Bottom, 8px Left/Right
      decoration: BoxDecoration(
        color: isCount
            ? Colors.grey[200]
            : const Color(
                0xFF898989,
              ).withValues(alpha: 0.10), // #898989 10% Opacity
        borderRadius: BorderRadius.circular(99), // Tam oval radius
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 10,
          fontWeight: FontWeight.w600, // SemiBold
          color: const Color(0xFF737373),
          height: 14 / 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );

    if (isExpanded) {
      return tagWidget;
    }
    return tagWidget;
  }
}
