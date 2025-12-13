import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/utils/screen_size_extensions.dart';

/// SocialButton
/// ------------------------------------------------------------
/// Sosyal login butonu UI bileşeni.
/// - Apple/Facebook: FontAwesome icon
/// - Google: asset ikon
///
/// Not:
/// - Bu widget auth işlemi yapmaz.
/// - Sadece onPressed callback tetikler.
class SocialButton extends StatelessWidget {
  const SocialButton._({
    required this.onPressed,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final VoidCallback onPressed;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Widget icon;

  factory SocialButton.google({required VoidCallback onPressed}) {
    return SocialButton._(
      onPressed: onPressed,
      label: 'Google',
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      icon: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('assets/icons/google_icon.png'),
      ),
    );
  }

  factory SocialButton.facebook({required VoidCallback onPressed}) {
    return SocialButton._(
      onPressed: onPressed,
      label: 'Facebook',
      backgroundColor: const Color(0xFF1877F2),
      textColor: Colors.white,
      icon: const SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: FaIcon(FontAwesomeIcons.facebookF, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  factory SocialButton.apple({required VoidCallback onPressed}) {
    return SocialButton._(
      onPressed: onPressed,
      label: 'Apple',
      backgroundColor: Colors.black,
      textColor: Colors.white,
      icon: const SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: FaIcon(FontAwesomeIcons.apple, size: 24, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = backgroundColor == Colors.white;

    return SizedBox(
      height: 44.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(
            color: isLight ? const Color(0xFFE5E7EB) : Colors.transparent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
