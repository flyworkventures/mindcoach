import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/routes/app_router.dart';
import 'package:mindcoach/core/routes/page_routes.dart';

import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/widgets/app_svg_icon_button.dart';

class HomeHeader extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 64.w,
                  height: 64.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pink.shade100,
                    image:  DecorationImage(
                      image: NetworkImage(ppPath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l.hi}, $userName',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.quicksand(
                          fontSize: 24.w,
                          
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3.w,
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        l.goodMorning,
                        style: GoogleFonts.quicksand(
                          fontSize: 14.w,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.3.w,
                          height: 1.0,
                          color: AppColors.lightGreyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(
            width: 34.w,
            height: 34.h,
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
}
