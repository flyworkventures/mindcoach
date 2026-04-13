import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';

class SpecialistsFilterSheet extends StatefulWidget {
  final Set<String> initial;
  final Function(Set<String>) onSave;
  final List<String> availableJobs;
  final List<String> availableFeatures;

  const SpecialistsFilterSheet({
    super.key,
    required this.initial,
    required this.onSave,
    this.availableJobs = const [],
    this.availableFeatures = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required Set<String> initial,
    required List<String> availableJobs,
    required Function(Set<String>) onSave,
    List<String> availableFeatures = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpecialistsFilterSheet(
        initial: initial,
        onSave: onSave,
        availableJobs: availableJobs,
        availableFeatures: availableFeatures,
      ),
    );
  }

  @override
  State<SpecialistsFilterSheet> createState() => _SpecialistsFilterSheetState();
}

class _SpecialistsFilterSheetState extends State<SpecialistsFilterSheet> {
  String? _selectedArea;
  String? _selectedExpertise;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      _selectedArea = widget.initial.first;
    }
  }

  /// Job key'lerini lokalize ederek dropdown için hazırla
  List<_DropdownItem> _buildCoachingAreas() {
    if (widget.availableJobs.isEmpty) {
      // Fallback default job keys
      return [
        'adult',
        'family_assistant',
        'child',
        'teenage',
        'personal',
        'exam_anxiety',
      ]
          .map((key) => _DropdownItem(
                key: key,
                label: JobConvert(key, context).call(),
              ))
          .toList();
    }
    return widget.availableJobs
        .map((key) => _DropdownItem(
              key: key,
              label: JobConvert(key, context).call(),
            ))
        .toList();
  }

  /// Expertise feature key'lerini lokalize et
  List<_DropdownItem> _buildExpertises() {
    final featureConvert = FeatureConvert(context);
    final defaultFeatures = [
      'communication',
      'stress_management',
      'career_guidance',
      'relationship_repair',
      'self_confidence',
      'anger_management',
    ];
    final features =
        widget.availableFeatures.isNotEmpty ? widget.availableFeatures : defaultFeatures;
    return features
        .map((key) => _DropdownItem(
              key: key,
              label: featureConvert.call(key),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coachingAreas = _buildCoachingAreas();
    final expertises = _buildExpertises();

    // Seçili alan için label bul
    final selectedAreaLabel = _selectedArea != null
        ? coachingAreas
            .where((item) => item.key == _selectedArea)
            .map((item) => item.label)
            .firstOrNull
        : null;

    final selectedExpertiseLabel = _selectedExpertise != null
        ? expertises
            .where((item) => item.key == _selectedExpertise)
            .map((item) => item.label)
            .firstOrNull
        : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E2E2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.filterTitle,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SvgPicture.asset(
                  'assets/icons/ic_close.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- COACHING AREA ---
          Text(
            l10n.filterCoachingArea,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          CustomDropdown(
            items: coachingAreas.map((e) => e.label).toList(),
            selectedValue: selectedAreaLabel,
            hint: l10n.filterSelectCoachingArea,
            onChanged: (val) {
              setState(() {
                // Label'dan key'e geri çevir
                final match = coachingAreas.where((item) => item.label == val).firstOrNull;
                _selectedArea = match?.key;
              });
            },
          ),
          const SizedBox(height: 20),

          // --- EXPERTISE ---
          Text(
            l10n.filterExpertise,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          CustomDropdown(
            items: expertises.map((e) => e.label).toList(),
            selectedValue: selectedExpertiseLabel,
            hint: l10n.featureCommunication,
            onChanged: (val) {
              setState(() {
                final match = expertises.where((item) => item.label == val).firstOrNull;
                _selectedExpertise = match?.key;
              });
            },
          ),
          const SizedBox(height: 32),

          // --- SAVE BUTTON ---
          GestureDetector(
            onTap: () {
              final Set<String> result = {};
              if (_selectedArea != null) {
                result.add(_selectedArea!);
              }
              widget.onSave(result);
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF21BC87),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.filterSave,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal model for dropdown items with key-label pair
class _DropdownItem {
  final String key;
  final String label;

  _DropdownItem({required this.key, required this.label});
}

// ============================================================================
// CUSTOM DROPDOWN WIDGET
// ============================================================================

class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String? selectedValue;
  final String hint;
  final Function(String?) onChanged;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  bool _isOpen = false;

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (tappable)
        GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E2E2), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedValue ?? widget.hint,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.selectedValue == null
                          ? const Color(0xFF96989C)
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF96989C),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable menu
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: _isOpen
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E2E2),
                      width: 2,
                    ),
                  ),
                  child: RawScrollbar(
                    thumbColor: const Color(0xFFE2E2E2),
                    radius: const Radius.circular(8),
                    thickness: 4,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        return InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            _toggleDropdown();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF96989C),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
