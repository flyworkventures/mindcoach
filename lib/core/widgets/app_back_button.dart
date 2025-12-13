import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  const AppBackButton({
    super.key,
    this.onTap,
    this.iconColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFC4C4C4),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/svg/arrow_back.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
