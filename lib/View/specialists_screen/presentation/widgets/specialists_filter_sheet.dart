import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';

class FilterResult {
  final String? job;
  final String? feature;

  const FilterResult({this.job, this.feature});

  bool get isEmpty => job == null && feature == null;
}

class SpecialistsFilterSheet extends StatefulWidget {
  final FilterResult initial;
  final Function(FilterResult) onSave;
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
    required FilterResult initial,
    required List<String> availableJobs,
    required List<String> availableFeatures,
    required Function(FilterResult) onSave,
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
    _selectedArea = widget.initial.job;
    _selectedExpertise = widget.initial.feature;
  }

  List<_DropdownItem> _buildCoachingAreas() {
    const jobOrder = [
      'exam_anxiety',
      'adult',
      'child',
      'teenage',
      'personal',
      'family_assistant',
      'thought_and_habit_guide',
      'emotional_balance',
      'difficult_experiences',
      'resilience_empowerment',
    ];
    final rawJobs = widget.availableJobs.isNotEmpty
        ? widget.availableJobs
        : jobOrder;
    final rawSet = rawJobs.toSet();
    final keys = [
      ...jobOrder.where(rawSet.contains),
      ...rawSet.where((j) => !jobOrder.contains(j)),
    ];
    return keys
        .map(
          (key) =>
              _DropdownItem(key: key, label: JobConvert(key, context).call()),
        )
        .toList();
  }

  List<_DropdownItem> _buildExpertises() {
    final featureConvert = FeatureConvert(context);
    if (widget.availableFeatures.isEmpty) return [];
    return widget.availableFeatures
        .map((key) => _DropdownItem(key: key, label: featureConvert.call(key)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coachingAreas = _buildCoachingAreas();
    final expertises = _buildExpertises();

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
        bottom: MediaQuery.of(context).padding.bottom + 16,
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
          const SizedBox(height: 16),

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
          ClearableDropdown(
            items: coachingAreas.map((e) => e.label).toList(),
            selectedValue: selectedAreaLabel,
            hint: l10n.filterSelectCoachingArea,
            allowClear: false,
            onChanged: (val) {
              setState(() {
                if (val == null) return;
                final match = coachingAreas
                    .where((item) => item.label == val)
                    .firstOrNull;
                _selectedArea = match?.key;
              });
            },
          ),

          if (expertises.isNotEmpty) ...[
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
            ClearableDropdown(
              items: expertises.map((e) => e.label).toList(),
              selectedValue: selectedExpertiseLabel,
              hint: l10n.filterSelectCoachingArea,
              onChanged: (val) {
                setState(() {
                  if (val == null) {
                    _selectedExpertise = null;
                  } else {
                    final match = expertises
                        .where((item) => item.label == val)
                        .firstOrNull;
                    _selectedExpertise = match?.key;
                  }
                });
              },
            ),
          ],

          const SizedBox(height: 24),

          // --- RESET + SAVE row ---
          Row(
            children: [
              // Reset button
              if (_selectedArea != null || _selectedExpertise != null)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedArea = null;
                        _selectedExpertise = null;
                      });
                    },
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.filterClear,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    widget.onSave(
                      FilterResult(
                        job: _selectedArea,
                        feature: _selectedExpertise,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownItem {
  final String key;
  final String label;
  _DropdownItem({required this.key, required this.label});
}

// ============================================================================
// CLEARABLE DROPDOWN — seçili değer X ile kaldırılabilir
// ============================================================================

class ClearableDropdown extends StatefulWidget {
  final List<String> items;
  final String? selectedValue;
  final String hint;
  final Function(String?) onChanged;
  final bool allowClear;

  const ClearableDropdown({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.hint,
    required this.onChanged,
    this.allowClear = true,
  });

  @override
  State<ClearableDropdown> createState() => _ClearableDropdownState();
}

class _ClearableDropdownState extends State<ClearableDropdown> {
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedValue != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        GestureDetector(
          onTap: _toggle,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    widget.selectedValue ?? widget.hint,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.black87
                          : const Color(0xFF96989C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // X butonu — seçiliyse göster, aksi halde ok
                if (isSelected && widget.allowClear)
                  GestureDetector(
                    onTap: () {
                      setState(() => _isOpen = false);
                      widget.onChanged(null); // filtreyi temizle
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF96989C),
                    ),
                  )
                else
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
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

        // Expandable list
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: _isOpen
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 200),
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
                        final isItemSelected = item == widget.selectedValue;
                        return InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            _toggle();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isItemSelected
                                  ? const Color(
                                      0xFF21BC87,
                                    ).withValues(alpha: 0.08)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 14,
                                      fontWeight: isItemSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isItemSelected
                                          ? const Color(0xFF21BC87)
                                          : Color(0xFf96989C),
                                    ),
                                  ),
                                ),
                                if (isItemSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Color(0xFF21BC87),
                                  ),
                              ],
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
