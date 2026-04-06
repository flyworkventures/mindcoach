import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/Riverpod/Controllers/HomeController/home_controller.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/View/GeneralAssistant/general_assistant_view.dart';

import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/locale_font_scaler.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/widgets/pill_page_indicator.dart';
import 'package:shimmer/shimmer.dart';

import '../home_notifier.dart';

class QuickActionsSection extends ConsumerStatefulWidget {
  const QuickActionsSection({super.key});

  @override
  ConsumerState<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends ConsumerState<QuickActionsSection> {
  late final PageController _pageController;
  Timer? timer;
  List<Widget> texts = [];

  void startController(){
    timer = Timer.periodic(Duration(seconds: 3), (a){
      
         if (_pageController.page ==1) {
          Future.delayed(Duration(seconds: 2)).then((a){
  _pageController.jumpTo(0);
          });
         
         }
      _pageController.nextPage(duration: Duration(milliseconds: 500), curve: Curves.easeIn);
    });
  }


void initialize(){
  MotivationModel? motivationModel = ref.read(AllControllers.homeController).motivationModel;
  if (motivationModel != null) {

  }
}


  @override
  void initState() {
    super.initState();
    initialize();
    _pageController = PageController();
    startController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    timer?.cancel();
    super.dispose();
  }

  Widget _pageItem(BuildContext context, {required String text, required Color color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.w, left: 12, right: 12, top: 8),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.quicksand(
            fontSize: LocaleFontScaler.scale(context, 20),
            fontWeight: FontWeight.w600,
            height: 1.0,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(homeProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 31.w),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol kart: quote slider
              Flexible(
                child: SizedBox(
                  width: 154.w,
                  height: 151.h,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Soldaki Quick Action'a git
                    },
                    child: Container(
                      width: 154.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13.w),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xffC4E0FE).withValues(alpha: 0.4),
                            blurRadius: 5.w,
                          ),
                        ],
                      ),
                      child: ref.watch(AllControllers.homeController).texts.isNotEmpty
                      ? Stack(
                        children: [
                          PageView(
                          // reverse: true,
                            padEnds: false,
                            controller: _pageController,
                            onPageChanged: (index) {
                              ref.read(homeProvider.notifier).setQuickActionPageIndex(index);
                            },
                            children: ref.watch(AllControllers.homeController).texts,
                          ),
                          Positioned(
                            bottom: 10.h,
                            left: 0,
                            right: 0,
                            child: PillPageIndicator(
                              count: 3,
                              currentIndex: state.quickActionPageIndex,
                              selectedColor: AppColors.primaryGreen,
                              unselectedColor: AppColors.indicatorUnselected,
                              selectedWidth: 33.w,
                              unselectedWidth: 10.w,
                              height: 3.h,
                              spacing: 4.w,
                            ),
                          ),
                        ],
                      )
                      : Shimmer.fromColors(
              baseColor: Colors.grey.withValues(alpha: 0.2),
              highlightColor: Colors.grey.withValues(alpha: 0.1),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Container(
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(50)),
                width: 130.w,
                height: 10.0,
              ),
              const SizedBox(height: 8.0),
              Container(
                width: 100.w,
                height: 10.0,
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(50)),
              ),
               const SizedBox(height: 8.0),
              Container(
                width: 120.w,
                height: 10.0,
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(50)),
              ),
               const SizedBox(height: 8.0),
                        Container(
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(50)),
                width: 105.w,
                height: 10.0,
              ),
              const SizedBox(height: 8.0),
              Container(
                width: 115.w,
                height: 10.0,
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(50)),
              ),
               const SizedBox(height: 8.0),
              Container(
                width: 95.w,
                height: 10.0,
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(50)),
              ),
          ],
              )
              
              )
                    ),
                  ),
                ),
              ),
          
              SizedBox(width: 23.w),
          
              // Sağ kart: Start talking
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Chatbot'a git
          
                    Navigator.push(context, CupertinoPageRoute(builder: (context)=> GeneralAssistantView()));
                  },
                  child: Container(
                    width: 154.w,
                    height: 151.h,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13.w),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xffC4E0FE).withValues(alpha: 0.4),
                          blurRadius: 5.w,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 77.w,
                          height: 77.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade100,
                            image: const DecorationImage(
                              image: AssetImage('assets/images/female_avatar.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l.someoneWantsToTalkToYou,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: LocaleFontScaler.scale(context, 13.w),
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l.startTalking,
                              style: GoogleFonts.quicksand(
                                fontSize: LocaleFontScaler.scale(context, 12.w),
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Icon(Icons.arrow_forward_ios, size: 10.w, color: AppColors.primaryGreen),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
