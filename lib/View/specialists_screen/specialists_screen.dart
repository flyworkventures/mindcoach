import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/View/specialists_screen/presentation/widgets/specialists_filter_sheet.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/models/consultant_model.dart';

import '../../core/routes/page_routes.dart';
import '../../core/utils/context_l10n_extensions.dart';
import 'specialists_notifier.dart';

class SpecialistsScreen extends ConsumerStatefulWidget {
  const SpecialistsScreen({super.key});

  @override
  ConsumerState<SpecialistsScreen> createState() => _SpecialistsScreenState();
}

class _SpecialistsScreenState extends ConsumerState<SpecialistsScreen> {
  FilterResult _activeFilter = const FilterResult();

  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getAvailableJobs(List<ConsultantModel>? specialists) {
    if (specialists == null || specialists.isEmpty) return [];
    const jobOrder = [
      'exam_anxiety',
      'adult',
      'child',
      'teenage',
      'personal',
      'family_assistant',
      'thought_and_habit_guide',
      'emotional_balance',
      'difficult_experiences',
      'resilience_empowerment',
    ];
    final raw = specialists.map((s) => s.job).toSet();
    return [
      ...jobOrder.where(raw.contains),
      ...raw.where((j) => !jobOrder.contains(j)),
    ];
  }

  List<String> _getAvailableFeatures(List<ConsultantModel>? specialists) {
    if (specialists == null || specialists.isEmpty) return [];
    final all = specialists
        .expand((s) => s.features.map((f) => f.toString()))
        .toSet()
        .toList();
    all.sort();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(specialistsProvider);

    // Seçilen filtrelere VE arama metnine göre listeyi ayır
    final filteredSpecialists = state.specialists?.where((specialist) {
      // Job (Koçluk alanı) filtresi
      final matchesJob =
          _activeFilter.job == null || specialist.job == _activeFilter.job;

      // Feature (Uzmanlık) filtresi
      final matchesFeature =
          _activeFilter.feature == null ||
          specialist.features
              .map((f) => f.toString())
              .contains(_activeFilter.feature);

      // Arama filtresi
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final specialistName =
            (specialist.names[context.langCode] as String? ??
                    specialist.names['en'] as String? ??
                    specialist.names.values.first.toString())
                .toLowerCase();
        final jobTitle = JobConvert(
          specialist.job,
          context,
        ).call().toLowerCase();
        matchesSearch =
            specialistName.contains(query) || jobTitle.contains(query);
      }

      return matchesJob && matchesFeature && matchesSearch;
    }).toList();

    // Figma'daki gibi kategori bazlı göstermek için gruplama yapıyoruz
    // Önce sınav kaygısı, ortada mevcut tipler, sonda yeni rehberlik tipleri
    const groupJobOrder = [
      'exam_anxiety',
      'adult',
      'child',
      'teenage',
      'personal',
      'family_assistant',
      'thought_and_habit_guide',
      'emotional_balance',
      'difficult_experiences',
      'resilience_empowerment',
    ];
    final Map<String, List<ConsultantModel>> groupedSpecialists = {};
    if (filteredSpecialists != null) {
      final sorted = [...filteredSpecialists]
        ..sort((a, b) {
          final ai = groupJobOrder.indexOf(a.job);
          final bi = groupJobOrder.indexOf(b.job);
          return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
        });
      for (var specialist in sorted) {
        final jobTitle = JobConvert(specialist.job, context).call();
        if (!groupedSpecialists.containsKey(jobTitle)) {
          groupedSpecialists[jobTitle] = [];
        }
        groupedSpecialists[jobTitle]!.add(specialist);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: kToolbarHeight),

              // HEADER: "Coaches" & Filter Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.coachesTitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 18 / 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await SpecialistsFilterSheet.show(
                        context,
                        initial: _activeFilter,
                        availableJobs: _getAvailableJobs(state.specialists),
                        availableFeatures: _getAvailableFeatures(
                          state.specialists,
                        ),
                        onSave: (result) {
                          setState(() => _activeFilter = result);
                        },
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/icons/ic_filter.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // SEARCH BAR
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB6BECA).withValues(alpha: 0.75),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/ic_search.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF96989C),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController, // 3. Controller eklendi
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value; // 4. Arama metni güncellendi
                          });
                        },
                        decoration: InputDecoration(
                          hintText: context.l10n.searchAtMindcoach,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF96989C),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Aktif filtre chip'leri
              if (!_activeFilter.isEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    if (_activeFilter.job != null)
                      _FilterChip(
                        label: JobConvert(_activeFilter.job!, context).call(),
                        onRemove: () => setState(
                          () => _activeFilter = FilterResult(
                            feature: _activeFilter.feature,
                          ),
                        ),
                      ),
                    if (_activeFilter.feature != null)
                      _FilterChip(
                        label: FeatureConvert(
                          context,
                        ).call(_activeFilter.feature!),
                        onRemove: () => setState(
                          () => _activeFilter = FilterResult(
                            job: _activeFilter.job,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // LISTE
              Expanded(
                child: groupedSpecialists.isEmpty
                    ? Center(
                        child:
                            state.specialists == null ||
                                state.specialists!.isEmpty
                            ? const CircularProgressIndicator(
                                color: Color(0xFF21BC87),
                              )
                            : Text(
                                // Arama yapıldığında ve sonuç bulunamadığında gösterilecek metin
                                _searchQuery.isNotEmpty
                                    ? context.l10n.noResultsFound(_searchQuery)
                                    : context.l10n.noSpecialistsFound,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 14,
                                  color: Color(0xFF96989C),
                                ),
                              ),
                      )
                    : ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        itemCount: groupedSpecialists.keys.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (context, index) {
                          final categoryName = groupedSpecialists.keys
                              .elementAt(index);
                          final specialistsInCategory =
                              groupedSpecialists[categoryName]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryName,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  height: 18 / 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GridView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 195 / 321,
                                    ),
                                itemCount: specialistsInCategory.length,
                                itemBuilder: (context, gridIndex) {
                                  final specialist =
                                      specialistsInCategory[gridIndex];
                                  return _SpecialistCard(item: specialist);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialistCard extends ConsumerWidget {
  final ConsultantModel item;

  const _SpecialistCard({required this.item});

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
                    // Figma'daki arka plan gradyanı burada tanımlanıyor
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF6F6F6), // Üstteki açık gri
                          Color.fromARGB(
                            255,
                            49,
                            43,
                            43,
                          ), // Alttaki koyu siyahımsı renk
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

// ── Aktif filtre chip'i (X ile kaldırılabilir) ──
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF21BC87).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF21BC87), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF21BC87),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: Color(0xFF21BC87),
            ),
          ),
        ],
      ),
    );
  }
}
