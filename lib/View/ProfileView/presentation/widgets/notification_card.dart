import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationCard extends StatelessWidget {
  final String iconAsset;
  final String title;
  final Color borderColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NotificationCard({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.borderColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F4F4),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Color(0xFF505050),
                BlendMode.srcIn,
              ),
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
                color: Colors.black,
              ),
            ),
          ),
          _GradientSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _GradientSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GradientSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: value
              ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2BD383), Color(0xFF11998E)],
          )
              : const LinearGradient(
            colors: [Color(0xFFE3E3E3), Color(0xFFE3E3E3)],
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
