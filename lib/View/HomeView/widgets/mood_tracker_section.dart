import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/l10n/app_localizations.dart';

import '../domain/mood.dart';
import '../home_notifier.dart';

class MoodTrackerSection extends ConsumerWidget {
  const MoodTrackerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(homeProvider);

    // Eğer bugünkü mood kaydı varsa, widget'ı gösterme
    // hasTodayMood = true -> widget görünmez
    // hasTodayMood = false -> widget görünür
    if (state.hasTodayMood) {
      debugPrint("🚫 MoodTrackerSection: Bugünkü mood var, widget gizleniyor (hasTodayMood = true)");
      return const SizedBox.shrink();
    }
    
    debugPrint("✅ MoodTrackerSection: Bugünkü mood yok, widget gösteriliyor (hasTodayMood = false)");



    return ref.watch(homeProvider).hasTodayMood ? SizedBox.shrink()
    : Padding(
      padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 20.h),
      child: Container(
        width: 332.w,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.w),
            boxShadow: [
        BoxShadow(
          color: Color(0xffC4E0FE).withValues(alpha: 0.4),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      Text(
        l.howAreYouFeelIngToday,
        style: GoogleFonts.lato(
          fontSize: 16.w,
          fontWeight: FontWeight.w700,
          height: 24 / 17,
          color: Colors.black,
        ),
      ),
      Text(
        l.timeToTrackMood,
        style: GoogleFonts.lato(
          fontSize: 12.w,
          fontWeight: FontWeight.w500,
          height: 24 / 14,
          color: Colors.black,
        ),
      ),
      SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:  feels.map((a)=> feelItemWidget(a, context, ref, l)).toList()
            ),
          ],
        ),
      ),
    );
  }


  
}

List<FeelItem> feels =[
  FeelItem(icon: "😌", code: "calm",mood: Mood.calm),
  FeelItem(icon: "😊", code: "happy",mood: Mood.happy),
  FeelItem(icon: "😐", code: "neutral",mood: Mood.neutral),
  FeelItem(icon: "😴", code: "tired",mood: Mood.tired),
  FeelItem(icon: "😣", code: "stressed",mood: Mood.stressed),
];


// feels.map((a)=> feelItemWidget(a, context)).toList()
Widget feelItemWidget(FeelItem item, BuildContext context, WidgetRef ref, AppLocalizations l){
  // Mood code'una göre lokalize edilmiş text'i al
  String localizedText;
  switch (item.code) {
    case 'calm':
      localizedText = l.moodCalm;
      break;
    case 'happy':
      localizedText = l.moodHappy;
      break;
    case 'neutral':
      localizedText = l.moodNeutral;
      break;
    case 'tired':
      localizedText = l.moodTired;
      break;
    case 'stressed':
      localizedText = l.moodStressed;
      break;
    default:
      localizedText = item.code;
  }

  return GestureDetector(
    onTap: ()async{


const options = ConfettiOptions(
  spread: 660,
  ticks: 50,
  y: 0.6,
  gravity: -5,
  decay: 0.94,
  startVelocity: 30,
);

shoot() {
  Confetti.launch(context,
      options: options.copyWith(
        particleCount: 20,
      ),
      particleBuilder: (index) => Emoji(
          emoji: item.icon,
          textStyle: GoogleFonts.notoColorEmoji()));

}

Timer(Duration.zero, shoot);
Timer(const Duration(milliseconds: 200), shoot);
Timer(const Duration(milliseconds: 400), shoot);

 await ref.read(homeProvider.notifier).setMood(item.mood);

    },
    child: SizedBox(
      width: 60.w,
      child: Column(
        children: [
          Text(item.icon,style: TextStyle(fontSize: 26, fontFamilyFallback: const [
        'Apple Color Emoji', // iOS
        'Segoe UI Emoji',    // Windows
        'Noto Color Emoji',  // Android
      ],),),
          Text(localizedText,style: GoogleFonts.lato(fontSize: 12,fontWeight: FontWeight.w400),)
        ],
      ),
    ),
  );
}



class FeelItem {
  final String icon;
  final String code;
  final Mood mood;
  FeelItem({
    required this.icon,
    required this.code,
    required this.mood
  });
}
