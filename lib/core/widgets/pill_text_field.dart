import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class PillTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  final bool readOnly;

  const PillTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,

  });

  @override
  Widget build(BuildContext context) {
    final textColor = readOnly ? const Color(0xFF8E8E8E) : const Color(0xFF525252);
    final borderColor = readOnly ? const Color(0xFFE6E6E6) : const Color(0xFFD4D4D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.0,
            color: const Color(0xFF4C4C4C),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            keyboardType: keyboardType,
            obscuringCharacter: '*',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.0,
              color:textColor
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                height: 1.0,
                color: const Color(0xFF525252),
              ),
              filled: true,
              fillColor: readOnly ? const Color(0xFFF6F6F6) : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(color: Color(0xFFD4D4D4), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide(color:  readOnly ? borderColor : AppColors.primaryGreen, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
