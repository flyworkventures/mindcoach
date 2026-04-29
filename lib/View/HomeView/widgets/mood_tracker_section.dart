import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            Text(
              l.howAreYouFeelIngToday,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4), // Metinler arası ufak boşluk
            Text(
              l.moodTrackerSubtitle,
              style: const TextStyle(
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
                _getMoodTitle(l, _selectedMoodCode!),
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
                _getMoodDescription(l, _selectedMoodCode!),
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

    await ref.read(homeProvider.notifier).setMood(item.mood);
  }

  String _getMoodTitle(AppLocalizations l, String code) {
    switch (code) {
      case 'calm':
        return l.moodCalm;
      case 'happy':
        return l.moodHappy;
      case 'neutral':
        return l.moodNeutral;
      case 'tired':
        return l.moodTired;
      case 'stressed':
        return l.moodStressed;
      default:
        return code;
    }
  }

  String _getMoodDescription(AppLocalizations l, String code) {
    switch (code) {
      case 'calm':
        return l.moodDescCalm;
      case 'happy':
        return l.moodDescHappy;
      case 'neutral':
        return l.moodDescNeutral;
      case 'tired':
        return l.moodDescTired;
      case 'stressed':
        return l.moodDescStressed;
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
