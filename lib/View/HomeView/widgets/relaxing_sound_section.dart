import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/View/relaxing_sound/sound_data.dart';
import 'package:mindcoach/View/relaxing_sound/sound_player_screen.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

class RelaxingSoundSection extends StatefulWidget {
  const RelaxingSoundSection({super.key});

  @override
  State<RelaxingSoundSection> createState() => _RelaxingSoundSectionState();
}

class _RelaxingSoundSectionState extends State<RelaxingSoundSection> {
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
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

    final currentSounds = allSounds
        .where((s) => s.categoryIndex == _selectedCategory)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l.relaxingSound,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    height: 24 / 18,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      PageRoutes.relaxingSoundScreen,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.seeAll,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF21BC87),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/icons/ic_see_all_arrow.svg',
                        width: 14,
                        height: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Kategori Tabları ──
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: soundCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = soundCategories[index];
                final isSelected = _selectedCategory == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF21BC87).withValues(alpha: 0.1)
                          : Color(0xff898989).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF21BC87)
                            : const Color(0xFFE2E2E2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          getCategoryLabel(l, cat.key),
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF21BC87)
                                : const Color(0xFF737373),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Ses Listesi ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(currentSounds.length, (i) {
                final sound = currentSounds[i];
                final durText = formatDuration(
                  Duration(seconds: sound.displayDurationSeconds),
                );

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getSoundTitle(l, sound.titleKey),
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF96989C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SvgPicture.asset('assets/icons/ic_play_sound.svg'),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
