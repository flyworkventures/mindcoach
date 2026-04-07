import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/approach_strings.dart';

class ApproachStep extends StatelessWidget {
  final ApproachType selectedApproach;
  final ValueChanged<ApproachType> onApproachChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const ApproachStep({
    super.key,
    required this.selectedApproach,
    required this.onApproachChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final options = ApproachType.values;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ApproachStrings.title(context),
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ApproachStrings.subtitle(context),
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF96989C),
            ),
          ),
          const SizedBox(height: 20),
          ...options.map((approach) {
            final selected = selectedApproach == approach;
            final label = ApproachStrings.label(context, approach);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectableOptionTile(
                label: label,
                isSelected: selected,
                onTap: () => onApproachChanged(approach),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      : const Color(0xFF1D1D1D),
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
