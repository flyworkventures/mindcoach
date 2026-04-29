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
      child: Center(child: SvgPicture.asset('assets/icons/ic_bakc.svg')),
    );
  }
}
