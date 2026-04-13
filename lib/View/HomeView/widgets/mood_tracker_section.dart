import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/l10n/app_localizations.dart';

import '../domain/mood.dart';
import '../home_notifier.dart';

class MoodTrackerSection extends ConsumerStatefulWidget {
  const MoodTrackerSection({super.key});

  @override
  ConsumerState<MoodTrackerSection> createState() => _MoodTrackerSectionState();
}

class _MoodTrackerSectionState extends ConsumerState<MoodTrackerSection> {
  String? _selectedMoodCode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(homeProvider);

    if (state.hasTodayMood) return const SizedBox.shrink();

    return Padding(
      // Dışarıdan ekran kenarlarına olan boşluk (Figma dışında kalan genel ekran boşluğu)
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        // Kartın iç boşluğu (Figma'daki Padding alanı)
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Çerçeve (Figma: Border 1px, #000000 5%)
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4), // Metinler arası ufak boşluk
            const Text(
              'A small check-in goes a long way',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF96989C),
              ),
            ),
            const SizedBox(height: 20),

            // Mood emoji row
            Row(
              // Görseldeki gibi kart genişliğine yayılması için spaceBetween kullanıldı
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: feels
                  .map(
                    (item) => _MoodButton(
                      item: item,
                      isSelected: _selectedMoodCode == item.code,
                      onTap: () => _onMoodTap(item, context),
                      l: l,
                    ),
                  )
                  .toList(),
            ),

            // Selected mood description
            if (_selectedMoodCode != null) ...[
              const SizedBox(height: 16),
              // İnce ayırıcı çizgi (Figma: Vector 9, Border 0.5px, #000000 5%)
              Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.black.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 16),
              Text(
                _getMoodTitle(_selectedMoodCode!),
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 24 / 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getMoodDescription(_selectedMoodCode!),
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF96989C),
                  height: 18 / 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onMoodTap(FeelItem item, BuildContext context) async {
    setState(() => _selectedMoodCode = item.code);

    const options = ConfettiOptions(
      spread: 660,
      ticks: 50,
      y: 0.6,
      gravity: -5,
      decay: 0.94,
      startVelocity: 30,
    );

    void shoot() {
      Confetti.launch(
        context,
        options: options.copyWith(particleCount: 20),
        particleBuilder: (index) =>
            Emoji(emoji: item.icon, textStyle: GoogleFonts.notoColorEmoji()),
      );
    }

    Timer(Duration.zero, shoot);
    Timer(const Duration(milliseconds: 200), shoot);
    Timer(const Duration(milliseconds: 400), shoot);

    await ref.read(homeProvider.notifier).setMood(item.mood);
  }

  String _getMoodTitle(String code) {
    switch (code) {
      case 'calm':
        return 'Calm';
      case 'happy':
        return 'Happy';
      case 'neutral':
        return 'Neutral';
      case 'tired':
        return 'Tired';
      case 'stressed':
        return 'Stressed';
      default:
        return code;
    }
  }

  String _getMoodDescription(String code) {
    switch (code) {
      case 'calm':
        return 'This peace in your mind is your greatest strength. Enjoy this moment and stay balanced.';
      case 'happy':
        return 'Your positive energy is contagious! Keep spreading joy and embracing this wonderful feeling.';
      case 'neutral':
        return 'A steady state of mind is perfectly fine. Take a moment to check in with yourself.';
      case 'tired':
        return 'Your body is telling you to rest. Take a break and recharge — you deserve it.';
      case 'stressed':
        return 'Take a deep breath. Remember, it\'s okay to slow down and take things one step at a time.';
      default:
        return '';
    }
  }
}

class _MoodButton extends StatelessWidget {
  final FeelItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final AppLocalizations l;

  const _MoodButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    String localizedText;
    switch (item.code) {
      case 'calm':
        localizedText = l.moodCalm;
      case 'happy':
        localizedText = l.moodHappy;
      case 'neutral':
        localizedText = l.moodNeutral;
      case 'tired':
        localizedText = l.moodTired;
      case 'stressed':
        localizedText = l.moodStressed;
      default:
        localizedText = item.code;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Text(
              item.icon,
              style: const TextStyle(
                fontSize: 32,
                fontFamilyFallback: [
                  'Apple Color Emoji',
                  'Segoe UI Emoji',
                  'Noto Color Emoji',
                ],
              ),
            ),
          ),
          const SizedBox(height: 4), // Emojinin altındaki ufak boşluk
          Text(
            localizedText,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? const Color(0xFF21BC87) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

List<FeelItem> feels = [
  FeelItem(icon: "😌", code: "calm", mood: Mood.calm),
  FeelItem(icon: "😊", code: "happy", mood: Mood.happy),
  FeelItem(icon: "😐", code: "neutral", mood: Mood.neutral),
  FeelItem(icon: "😴", code: "tired", mood: Mood.tired),
  FeelItem(icon: "😣", code: "stressed", mood: Mood.stressed),
];

class FeelItem {
  final String icon;
  final String code;
  final Mood mood;
  FeelItem({required this.icon, required this.code, required this.mood});
}
