import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/routes/app_router.dart';
import 'package:mindcoach/core/routes/page_routes.dart';

import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/widgets/app_svg_icon_button.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader( {
    super.key,
    required this.userName,
    required this.ppPath,
    this.onTapNotifications,
  });

  final String userName;
  final String ppPath;
  final VoidCallback? onTapNotifications;

  @override
  Widget build(BuildContext context,WidgetRef ref) {
    final l = context.l10n;


    return Padding(
      padding: EdgeInsets.only(
        left: 31.w,
        right: 31.w,
        top: 22.h,
        bottom: 20.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white,width: 2),
                    shape: BoxShape.circle,
                    color: Colors.pink.shade100,
                    image:  DecorationImage(
                      image: NetworkImage(ppPath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                premiumWidget(ref.watch(AllProviders.premiumProvider))
            
              ],
            ),
          ),
   
          Container(
            width: 34.w,
            height: 34.h,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, 0),
                  blurRadius: 10,
                  color: Colors.black.withValues(alpha: 0.05)
                )
              ],
              color: Colors.white,
              borderRadius: BorderRadius.circular(30)
            ),
            child: AppSvgIconButton(
              assetPath: 'assets/svg/notification.svg',
              size: 24.w,
              color: Colors.black54,
              onPressed: onTapNotifications ?? () {
                Navigator.pushNamed(context, PageRoutes.notifications);
              },
            ),
          ),

          
        ],
      ),
    );
  }




Widget premiumWidget(bool isPremium){
  return    GestureDetector(
    onTap: ()async{
    if (!isPremium) {
      final paywallResult = await RevenueCatUI.presentPaywall();
    }
    },
    child: Container(
      height: 26.h,
    
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isPremium ? Colors.white.withValues(alpha: 0.4) : null,
        gradient: isPremium ? null : LinearGradient(colors: [Color(0xff11998E),Color(0xff38EF7D)],begin: Alignment.centerLeft,end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(40),
     
      ),
              child: Row(
                children: [
                  Icon(isPremium ? Iconsax.medal_star: Iconsax.award,color: Colors.white,size: 20,),
                  SizedBox(width: 5.w,),
                  Text(isPremium ? "PREMIUM":"Get Pro",style: GoogleFonts.lato(color:  Colors.white,fontSize: isPremium == true ? 11 : 16,fontWeight: FontWeight.w600,letterSpacing: -0.3),)
                ],
              )
            ),
  );
}


}
