import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/l10n/app_localizations.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return GestureDetector(
      onTap: () async{
        final paywallResult = await RevenueCatUI.presentPaywall();
      },
      child: Padding(
        padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 30.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Premium!",
              style: GoogleFonts.quicksand(
                fontSize: 17.w,
                fontWeight: FontWeight.w700,
                height: 24.h / 17.w,
                color: Colors.black,
              ),
            ),
      
            Container(
        width: double.infinity,
        height: 150.h,
        padding: EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black,Colors.black,Color(0xff81501F)],begin: Alignment.topRight,end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Premium Plan",
                    style: GoogleFonts.quicksand(
                      fontSize: 20.w,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Unlock your ai chatbot & get all premium features",
                    style: GoogleFonts.quicksand(
                      fontSize: 12.w,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              
                   ElevatedButton.icon(
                icon: Icon(Iconsax.medal,color: Colors.white,),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: Size(112.w, 22.h),
                  backgroundColor: Color(0xffFFB200),
                ),
                onPressed: () async{
                          final paywallResult = await RevenueCatUI.presentPaywall();
                },
       

  
                label: Text(
                  "Upgrade Plan",
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
                ],
              ),
            ),
           
          Expanded(child: Image.asset("assets/chars/womenpng.png", fit: BoxFit.cover,)),
          ],
        ),
      )
          
          ],
        ),
      ),
    );
  }
}
