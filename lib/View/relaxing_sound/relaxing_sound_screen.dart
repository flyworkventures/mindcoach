import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/View/relaxing_sound/sound_data.dart';
import 'package:mindcoach/View/relaxing_sound/sound_player_screen.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

class RelaxingSoundScreen extends StatefulWidget {
  const RelaxingSoundScreen({super.key});

  @override
  State<RelaxingSoundScreen> createState() => _RelaxingSoundScreenState();
}

class _RelaxingSoundScreenState extends State<RelaxingSoundScreen> {
  int _selectedCategory = -1; // -1 = Tümü (All)
  String _searchQuery = '';
  late TextEditingController _searchController;
  late SoundItem _featuredSound;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _featuredSound = allSounds[Random().nextInt(allSounds.length)];

    // Süreleri yükle
    SoundDurationCache.instance.loadAll().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Playlist oluştur ve player'ı aç.
  void _openPlayer(List<SoundItem> sounds, int tappedIndex) {
    final l = context.l10n;
    final playlist = sounds.map((s) {
      return SoundPlayerItem(
        title: getSoundTitle(l, s.titleKey),
        subtitle: s.subtitleKey.isNotEmpty
            ? getSoundSubtitle(l, s.subtitleKey)
            : '',
        imagePath: s.imagePath,
        audioPath: s.audioPath,
        categoryLabel: getCategoryLabel(
          l,
          soundCategories[s.categoryIndex].key,
        ),
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SoundPlayerScreen(playlist: playlist, initialIndex: tappedIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cache = SoundDurationCache.instance;

    // Kategori filtresi: -1 = Tümü
    List<SoundItem> currentSounds = _selectedCategory == -1
        ? List<SoundItem>.from(allSounds)
        : allSounds.where((s) => s.categoryIndex == _selectedCategory).toList();

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      currentSounds = allSounds.where((s) {
        final title = getSoundTitle(l, s.titleKey).toLowerCase();
        return title.contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/ic_bakc.svg"),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.relaxingSound,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search Bar ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFB6BECA,
                              ).withValues(alpha: 0.75),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/icons/ic_search.svg'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: l.searchSoundHint,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: const TextStyle(
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
                    ),
                    const SizedBox(height: 24),

                    // ── Featured For You ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l.featuredForYou,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 20 / 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Featured card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () {
                          final idx = allSounds.indexOf(_featuredSound);
                          _openPlayer(allSounds, idx >= 0 ? idx : 0);
                        },
                        child: Container(
                          width: double.infinity,
                          height: 183,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF1A2A3A),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                _featuredSound.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1A3A5C),
                                        Color(0xFF0D1B2A),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      l.mostPopular.toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF21BC87),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      getSoundTitle(l, _featuredSound.titleKey),
                                      style: const TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 28 / 22,
                                      ),
                                    ),
                                    if (_featuredSound
                                        .subtitleKey
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        getSoundSubtitle(
                                          l,
                                          _featuredSound.subtitleKey,
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: SvgPicture.asset(
                                  "assets/icons/ic_featured.svg",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Category Tabs ──
                    SizedBox(
                      height: 26,
                      child: ListView.separated(
                        physics: ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        // +1 for the "Tümü" chip at index 0
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: soundCategories.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          // index 0 = Tümü, index 1..n = soundCategories[index-1]
                          final isAllChip = index == 0;
                          final cat = isAllChip ? null : soundCategories[index - 1];
                          final chipCategory = isAllChip ? -1 : index - 1;
                          final isSelected =
                              _selectedCategory == chipCategory &&
                              _searchQuery.isEmpty;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = chipCategory;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                top: 2,
                                right: 10,
                                bottom: 2,
                                left: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFF21BC87,
                                      ).withValues(alpha: 0.1)
                                    : Color(0xff898989).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF21BC87)
                                      : Color(0xff898989).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isAllChip)
                                  Text(
                                    cat!.emoji,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (!isAllChip) const SizedBox(width: 4),
                                  Text(
                                    isAllChip
                                        ? l.soundCategoryAll
                                        : getCategoryLabel(l, cat!.key),
                                    style: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                      color: isSelected
                                          ? const Color(0xFF21BC87)
                                          : const Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Sound List ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(currentSounds.length, (i) {
                          final sound = currentSounds[i];
                          final dur = cache.get(sound.audioPath);
                          final durText = dur != null
                              ? formatDuration(dur)
                              : '--:--';

                          return GestureDetector(
                            onTap: () => _openPlayer(currentSounds, i),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              // Flow: Width Fill -> double.infinity
                              width: double.infinity,
                              // Flow: Height Hug -> İçeriğe göre yüksekliği ayarlaması için padding kullanıyoruz
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                // Colors: #FFFFFF
                                color: Colors.white,
                                // Radius: 16px
                                borderRadius: BorderRadius.circular(16),
                                // Borders: 1px, All sides, #000000 5%
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFF5F5F5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        sound.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.music_note_rounded,
                                          color: Color(0xFF96989C),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getSoundTitle(l, sound.titleKey),
                                          style: const TextStyle(
                                            fontFamily: 'Geist',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                            height: 20 / 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          durText,
                                          style: const TextStyle(
                                            fontFamily: 'Geist',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF96989C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    'assets/icons/ic_play_sound.svg',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
