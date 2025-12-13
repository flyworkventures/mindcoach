import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/screen_size_extensions.dart';

enum ProfileArrowType { greenOutlined, black }

class ProfileMenuCard extends StatelessWidget {
  final String title;
  final String iconAsset;
  final Color iconBgColor;
  final Color borderColor;
  final Color titleColor;
  final Color? iconStrokeColor;
  final ProfileArrowType arrowType;
  final VoidCallback onTap;

  const ProfileMenuCard({
    super.key,
    required this.title,
    required this.iconAsset,
    required this.iconBgColor,
    required this.borderColor,
    required this.titleColor,
    required this.arrowType,
    required this.onTap,
    this.iconStrokeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        height: 56.h,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Icon bubble
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: iconStrokeColor != null
                    ? ColorFilter.mode(iconStrokeColor!, BlendMode.srcIn)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  color: titleColor,
                ),
              ),
            ),
            _buildArrow(),
          ],
        ),
      ),
    );
  }

  Widget _buildArrow() {
    switch (arrowType) {
      case ProfileArrowType.greenOutlined:
        return SvgPicture.asset(
          'assets/svg/right_arrow.svg',
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(Color(0xFF2BD383), BlendMode.srcIn),
        );
      case ProfileArrowType.black:
        return SvgPicture.asset(
          'assets/svg/right_arrow.svg',
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(Color(0xFF000000), BlendMode.srcIn),
        );
    }
  }
}
