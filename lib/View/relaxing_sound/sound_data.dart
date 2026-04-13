import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mindcoach/l10n/app_localizations.dart';

/// Shared sound data used by both the home section and the full screen.
class SoundCategory {
  final String emoji;
  final String key;
  const SoundCategory({required this.emoji, required this.key});
}

class SoundItem {
  final int categoryIndex;
  final String titleKey;
  final String subtitleKey;
  final String imagePath;
  final String audioPath;

  const SoundItem({
    required this.categoryIndex,
    required this.titleKey,
    this.subtitleKey = '',
    required this.imagePath,
    required this.audioPath,
  });
}

const soundCategories = [
  SoundCategory(emoji: '🎯', key: 'focus'),
  SoundCategory(emoji: '🌙', key: 'sleep'),
  SoundCategory(emoji: '🧘', key: 'meditation'),
  SoundCategory(emoji: '☁️', key: 'relax'),
];

const allSounds = [
  // --- FOCUS (0) ---
  SoundItem(
    categoryIndex: 0,
    titleKey: 'soundDeepWorkFlow',
    subtitleKey: 'soundDeepWorkFlowSub',
    imagePath: 'assets/images/image_1.png',
    audioPath: 'assets/musics/sound_1.mp3',
  ),
  SoundItem(
    categoryIndex: 0,
    titleKey: 'soundBinauralBeats',
    subtitleKey: 'soundBinauralBeatsSub',
    imagePath: 'assets/images/image_2.png',
    audioPath: 'assets/musics/sound_2.mp3',
  ),
  SoundItem(
    categoryIndex: 0,
    titleKey: 'soundLibraryAmbience',
    subtitleKey: 'soundLibraryAmbienceSub',
    imagePath: 'assets/images/image_3.png',
    audioPath: 'assets/musics/sound_3.mp3',
  ),

  // --- SLEEP (1) ---
  SoundItem(
    categoryIndex: 1,
    titleKey: 'soundRainOnWindow',
    subtitleKey: 'soundRainOnWindowSub',
    imagePath: 'assets/images/image_4.png',
    audioPath: 'assets/musics/sound_4.mp3',
  ),
  SoundItem(
    categoryIndex: 1,
    titleKey: 'soundOceanWaves',
    subtitleKey: 'soundOceanWavesSub',
    imagePath: 'assets/images/image_5.png',
    audioPath: 'assets/musics/sound_5.mp3',
  ),
  SoundItem(
    categoryIndex: 1,
    titleKey: 'soundDeepSpaceDrone',
    subtitleKey: 'soundDeepSpaceDroneSub',
    imagePath: 'assets/images/image_6.png',
    audioPath: 'assets/musics/sound_6.mp3',
  ),

  // --- MEDITATION (2) ---
  SoundItem(
    categoryIndex: 2,
    titleKey: 'soundTibetanBowls',
    subtitleKey: 'soundTibetanBowlsSub',
    imagePath: 'assets/images/image_7.png',
    audioPath: 'assets/musics/sound_7.mp3',
  ),
  SoundItem(
    categoryIndex: 2,
    titleKey: 'soundForestBirds',
    subtitleKey: 'soundForestBirdsSub',
    imagePath: 'assets/images/image_8.png',
    audioPath: 'assets/musics/sound_8.mp3',
  ),
  SoundItem(
    categoryIndex: 2,
    titleKey: 'soundMorningZen',
    subtitleKey: 'soundMorningZenSub',
    imagePath: 'assets/images/image_9.png',
    audioPath: 'assets/musics/sound_9.mp3',
  ),

  // --- RELAX (3) ---
  SoundItem(
    categoryIndex: 3,
    titleKey: 'soundFireplaceCrackle',
    subtitleKey: 'soundFireplaceCrackleSub',
    imagePath: 'assets/images/image_10.png',
    audioPath: 'assets/musics/sound_10.mp3',
  ),
  SoundItem(
    categoryIndex: 3,
    titleKey: 'soundGentleStream',
    subtitleKey: 'soundGentleStreamSub',
    imagePath: 'assets/images/image_11.png',
    audioPath: 'assets/musics/sound_11.mp3',
  ),
  SoundItem(
    categoryIndex: 3,
    titleKey: 'soundSoftPiano',
    subtitleKey: 'soundSoftPianoSub',
    imagePath: 'assets/images/image_12.png',
    audioPath: 'assets/musics/sound_12.mp3',
  ),
];

// ── Localization helpers ──

String getSoundTitle(AppLocalizations l, String key) {
  switch (key) {
    case 'soundDeepWorkFlow':
      return l.soundDeepWorkFlow;
    case 'soundBinauralBeats':
      return l.soundBinauralBeats;
    case 'soundLibraryAmbience':
      return l.soundLibraryAmbience;
    case 'soundRainOnWindow':
      return l.soundRainOnWindow;
    case 'soundOceanWaves':
      return l.soundOceanWaves;
    case 'soundDeepSpaceDrone':
      return l.soundDeepSpaceDrone;
    case 'soundTibetanBowls':
      return l.soundTibetanBowls;
    case 'soundForestBirds':
      return l.soundForestBirds;
    case 'soundMorningZen':
      return l.soundMorningZen;
    case 'soundFireplaceCrackle':
      return l.soundFireplaceCrackle;
    case 'soundGentleStream':
      return l.soundGentleStream;
    case 'soundSoftPiano':
      return l.soundSoftPiano;
    default:
      return key;
  }
}

String getSoundSubtitle(AppLocalizations l, String key) {
  switch (key) {
    case 'soundDeepWorkFlowSub':
      return l.soundDeepWorkFlowSub;
    case 'soundBinauralBeatsSub':
      return l.soundBinauralBeatsSub;
    case 'soundLibraryAmbienceSub':
      return l.soundLibraryAmbienceSub;
    case 'soundRainOnWindowSub':
      return l.soundRainOnWindowSub;
    case 'soundOceanWavesSub':
      return l.soundOceanWavesSub;
    case 'soundDeepSpaceDroneSub':
      return l.soundDeepSpaceDroneSub;
    case 'soundTibetanBowlsSub':
      return l.soundTibetanBowlsSub;
    case 'soundForestBirdsSub':
      return l.soundForestBirdsSub;
    case 'soundMorningZenSub':
      return l.soundMorningZenSub;
    case 'soundFireplaceCrackleSub':
      return l.soundFireplaceCrackleSub;
    case 'soundGentleStreamSub':
      return l.soundGentleStreamSub;
    case 'soundSoftPianoSub':
      return l.soundSoftPianoSub;
    default:
      return key;
  }
}

String getCategoryLabel(AppLocalizations l, String key) {
  switch (key) {
    case 'focus':
      return l.soundCategoryFocus;
    case 'sleep':
      return l.soundCategorySleep;
    case 'meditation':
      return l.soundCategoryMeditation;
    case 'relax':
      return l.soundCategoryRelax;
    default:
      return key;
  }
}

/// Süre formatla: Duration → "2:30" veya "0:45"
String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Asset ses dosyalarının sürelerini bir kez yükleyip cache'le.
class SoundDurationCache {
  SoundDurationCache._();
  static final SoundDurationCache instance = SoundDurationCache._();

  final Map<String, Duration> _cache = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Duration? get(String audioPath) => _cache[audioPath];

  /// Tüm seslerin süresini yükle.
  Future<void> loadAll() async {
    if (_loaded) return;
    final player = AudioPlayer();
    try {
      for (final sound in allSounds) {
        if (_cache.containsKey(sound.audioPath)) continue;
        try {
          final dur = await player.setAsset(sound.audioPath);
          if (dur != null) {
            _cache[sound.audioPath] = dur;
          }
        } catch (e) {
          debugPrint('Duration load error for ${sound.audioPath}: $e');
        }
      }
      _loaded = true;
    } finally {
      await player.dispose();
    }
  }
}
