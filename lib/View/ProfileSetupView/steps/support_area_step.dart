import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/support_area_strings.dart';
import '../domain/profile_models.dart';

class SupportAreaStep extends StatelessWidget {
  const SupportAreaStep({
    super.key,
    required this.selectedSupportArea,
    required this.onSupportAreaChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  final SupportArea selectedSupportArea;
  final ValueChanged<SupportArea> onSupportAreaChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final options = SupportArea.values;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SupportAreaStrings.title(context),
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SupportAreaStrings.subtitle(context),
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF96989C),
            ),
          ),
          const SizedBox(height: 20),
          ...options.map((area) {
            final selected = selectedSupportArea == area;
            final label = SupportAreaStrings.optionLabel(context, area);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectableOptionTile(
                label: label,
                isSelected: selected,
                onTap: () => onSupportAreaChanged(area),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SelectableOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF21BC87).withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF21BC87)
                : const Color(0xFFE2E2E2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF21BC87)
                      : const Color(0xFF96989C),
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF21BC87),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
