import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/HomeView/widgets/premium_card.dart';
import 'package:mindcoach/View/VideoCallView/video_call_view.dart';
import 'package:mindcoach/app/navbar_provider.dart';


import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/rive_page.dart';
import 'package:shimmer/shimmer.dart';

import 'widgets/home_header.dart';
import 'widgets/welcome_card.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/mood_tracker_section.dart';
import 'widgets/upcoming_appointment_section.dart';
import 'widgets/test_section.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    var userModel = ref.read(AllProviders.userProvider);

    return Scaffold(
      backgroundColor: Color(0xffFAFBFF),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: CustomScrollView(
          
          slivers: [
            SliverAppBar(
              expandedHeight: 267.h,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: AssetImage("assets/images/background.png",),fit: BoxFit.cover)
                  ),
                  child: Stack(
                 
                    children: [
                      SafeArea(child:   HomeHeader(userName: userModel?.username ?? "",ppPath: userModel?.profilePhotoUrl ?? "https://mindcoach.b-cdn.net/1024x1024.jpg",),),
                     Align(
                      alignment: Alignment.bottomCenter,
                      child:  Container(width: double.infinity,height: 120.h,decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.white,Colors.white.withValues(alpha: 0.4),Colors.white.withValues(alpha: 0.1),Colors.white.withValues(alpha: 0.02)],begin: Alignment.bottomCenter,end: Alignment.topCenter)
                      ),),
                      )
                    ],
                  )
                ),
              ),
            ),
        
         SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        period: Duration(seconds: 4),
                        baseColor: Color(0xff2BD383),
                        highlightColor: Color.fromARGB(255, 2, 254, 99),
                        child: Text('${l.welcome}, ${ref.watch(AllProviders.userProvider)?.username ?? "MindCoach User"}.',style: GoogleFonts.quicksand(fontSize: 24,fontWeight: FontWeight.w700),)),
                        Text(l.howAreYouFeelIngToday,style: GoogleFonts.quicksand(fontSize: 13,fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
        
                GestureDetector(
                  onTap: () {
               //  ref.read(bottomNavProvider.notifier).setTab(1);
                Navigator.push(context, CupertinoPageRoute(builder: (context)=> AvatarDataBindingPage()));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                          
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      
                      border: Border.all(color: Colors.black,)
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(l.getStart,style: GoogleFonts.quicksand(fontSize: 13,fontWeight: FontWeight.w600),),
                        SizedBox(width: 1,),
                        Icon(CupertinoIcons.right_chevron,size: 20,)
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
         ),
         SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: QuickActionsSection(),
          ),
         ),
                       SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: MoodTrackerSection(),
          ),
         ),
        
                SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: UpcomingAppointmentSection(),
          ),
         ),

          if(!ref.watch(AllProviders.premiumProvider))...[

                                SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: PremiumCard(),
          ),
         ),
        
          ],

          


        
        
                       SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TestSection(),
          ),
         ),
        
        
        
            
          ],
        ),
      )
    );
  }




}
