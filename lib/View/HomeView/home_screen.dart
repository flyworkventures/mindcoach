import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/VideoCallView/video_call_view.dart';


import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import 'widgets/home_header.dart';
import 'widgets/welcome_card.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/mood_tracker_section.dart';
import 'widgets/upcoming_appointment_section.dart';
import 'widgets/test_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    var userModel = ref.read(AllProviders.userProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.90, -1.0),
            end: Alignment(1.0, 1.0),
            colors: [Color(0xFFFBFCFF), Color(0xFFF9FAFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                 HomeHeader(userName: userModel?.username ?? "",ppPath: userModel?.profilePhotoUrl ?? "https://mindcoach.b-cdn.net/1024x1024.jpg",),
                 WelcomeCard(userName: userModel?.username ?? "",onTap: (){
              //    Navigator.push(context, CupertinoPageRoute(builder: (context)=> RiveView()));
               Navigator.push(context, CupertinoPageRoute(builder: (context)=> VideoCallView()));
                 },),

                Padding(
                  padding: EdgeInsets.only(left: 31.w, top: 30.h, bottom: 15.h),
                  child: Text(
                    l.quickActions,
                    style: GoogleFonts.quicksand(
                      fontSize: 17.w,
                      fontWeight: FontWeight.w700,
                      height: 24 / 17,
                      color: Colors.black,
                    ),
                  ),
                ),

                const QuickActionsSection(),
                const SizedBox(height: 8),
                const MoodTrackerSection(),
                const UpcomingAppointmentSection(),
               // const PremiumPlanSection(),
                const TestSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
