import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/analyse_section.dart';
import 'widgets/home_coaches_section.dart';
import 'widgets/home_header.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/mood_tracker_section.dart';
import 'widgets/premium_card.dart';
import 'widgets/relaxing_sound_section.dart';
import 'widgets/test_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              HomeHeader(),
              MoodTrackerSection(),
              AnalyseSection(),
              HomeCoachesSection(),
              HomeQuickActions(),
              PremiumCard(),
              TestSection(),
              RelaxingSoundSection(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
