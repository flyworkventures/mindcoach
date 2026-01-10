import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/specialists_color.dart';
import '../../domain/specialist_filters.dart';
import '../../domain/specialist_profile.dart';

class SpecialistsFilterSheet extends StatefulWidget {
  const SpecialistsFilterSheet({
    super.key,
    required this.initial,
  });

  final SpecialistFilters initial;

  static Future<SpecialistFilters?> show(
      BuildContext context, {
        required SpecialistFilters initial,
      }) {
    return showModalBottomSheet<SpecialistFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SpecialistsFilterSheet(initial: initial),
    );
  }

  @override
  State<SpecialistsFilterSheet> createState() => _SpecialistsFilterSheetState();
}

class _SpecialistsFilterSheetState extends State<SpecialistsFilterSheet> {
  late Set<SpecialistCategory> _categories;
  late Set<Availability> _availability;
  late Set<PriceTier> _priceTiers;
  late double _minRating;

  @override
  void initState() {
    super.initState();
    _categories = {...widget.initial.categories};
    _availability = {...widget.initial.availability};
    _priceTiers = {...widget.initial.priceTiers};
    _minRating = widget.initial.minRating;
  }

  SpecialistFilters _buildFilters() {
    return SpecialistFilters(
      categories: _categories,
      availability: _availability,
      minRating: _minRating,
      priceTiers: _priceTiers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: SpecialistsColors.sheetHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Text(
                      'Filter',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: SpecialistsColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _categories.clear();
                          _availability.clear();
                          _priceTiers.clear();
                          _minRating = 0;
                        });
                      },
                      child: Text(
                        'Reset',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w700,
                          color: SpecialistsColors.brandPrimaryGreen,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const Divider(color: SpecialistsColors.divider, height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Category'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: SpecialistCategory.values.map((c) {
                          final selected = _categories.contains(c);
                          return _chip(
                            label: _categoryLabel(c),
                            selected: selected,
                            onTap: () {
                              setState(() {
                                selected ? _categories.remove(c) : _categories.add(c);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),
                      _sectionTitle('Availability'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: Availability.values.map((a) {
                          final selected = _availability.contains(a);
                          return _chip(
                            label: _availabilityLabel(a),
                            selected: selected,
                            onTap: () {
                              setState(() {
                                selected ? _availability.remove(a) : _availability.add(a);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),
                      _sectionTitle('Min. rating'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _minRating.clamp(0, 5),
                              min: 0,
                              max: 5,
                              divisions: 10,
                              onChanged: (v) => setState(() => _minRating = v),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              _minRating.toStringAsFixed(1),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: SpecialistsColors.textPrimary,
                              ),
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 18),
                      _sectionTitle('Price'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: PriceTier.values.map((p) {
                          final selected = _priceTiers.contains(p);
                          return _chip(
                            label: _priceLabel(p),
                            selected: selected,
                            onTap: () {
                              setState(() {
                                selected ? _priceTiers.remove(p) : _priceTiers.add(p);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: SpecialistsColors.brandPrimaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700,
                            color: SpecialistsColors.brandPrimaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _buildFilters()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SpecialistsColors.brandPrimaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: SpecialistsColors.textPrimary,
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? SpecialistsColors.brandPrimaryGreen.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? SpecialistsColors.brandPrimaryGreen : SpecialistsColors.chipBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? SpecialistsColors.brandPrimaryGreen : SpecialistsColors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _categoryLabel(SpecialistCategory c) {
    switch (c) {
      case SpecialistCategory.mentorship:
        return 'Mentorship';
      case SpecialistCategory.relationship:
        return 'Relationship';
      case SpecialistCategory.mindfulness:
        return 'Mindfulness';
      case SpecialistCategory.anxiety:
        return 'Anxiety';
      case SpecialistCategory.focus:
        return 'Focus';
    }
  }

  String _availabilityLabel(Availability a) {
    switch (a) {
      case Availability.availableNow:
        return 'Available now';
      case Availability.today:
        return 'Today';
      case Availability.thisWeek:
        return 'This week';
    }
  }

  String _priceLabel(PriceTier p) {
    switch (p) {
      case PriceTier.budget:
        return 'Budget';
      case PriceTier.standard:
        return 'Standard';
      case PriceTier.premium:
        return 'Premium';
    }
  }
}
