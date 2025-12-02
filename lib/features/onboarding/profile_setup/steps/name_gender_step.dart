import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/screen_size_extensions.dart';

class NameGenderStep extends StatelessWidget {
  final String gender;
  final ValueChanged<String> onGenderChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const NameGenderStep({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Tell us a bit about yourself',
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
            child: Text(
              'A short bio helps others know the real you. Keep it fun and genuine.',
              style: subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            'Full Name',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.0,
              letterSpacing: 0,
              color: const Color(0xFF1D1D1D),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: SizedBox(
            width: 301.w,
            height: 50.h,
            child: TextField(
              cursorColor: Color(0xFF434343),
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                hintStyle: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF434343),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(
                    color: Color(0xFF2BD383),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            'Gender',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.0,
              letterSpacing: 0,
              color: const Color(0xFF1D1D1D),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                _GenderChip(
                  label: 'Male',
                  icon: Icons.male,
                  isSelected: gender == 'Male',
                  onTap: () => onGenderChanged('Male'),
                ),
                const SizedBox(width: 10),
                _GenderChip(
                  label: 'Female',
                  icon: Icons.female,
                  isSelected: gender == 'Female',
                  onTap: () => onGenderChanged('Female'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 301.w,
          height: 50.h,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2BD383)
                  : const Color(0xFF000000),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF434343),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 34,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF2bd383)
                    : const Color(0xFF3A3A3A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
