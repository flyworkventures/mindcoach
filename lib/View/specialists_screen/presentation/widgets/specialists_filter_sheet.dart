import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

class SpecialistsFilterSheet extends StatefulWidget {
  const SpecialistsFilterSheet({
    super.key,
    required this.initial,
    required this.availableJobs,
    required this.onSave,
  });

  final Set<String> initial;
  final List<String> availableJobs;
  final Function(Set<String>) onSave;

  static Future<void> show(
    BuildContext context, {
    required Set<String> initial,
    required List<String> availableJobs,
    required Function(Set<String>) onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SpecialistsFilterSheet(
        initial: initial,
        availableJobs: availableJobs,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SpecialistsFilterSheet> createState() => _SpecialistsFilterSheetState();
}

class _SpecialistsFilterSheetState extends State<SpecialistsFilterSheet> {
  late Set<String> _selectedJobs;

  @override
  void initState() {
    super.initState();
    _selectedJobs = {...widget.initial};
  }
  
  // Job'u görüntülenebilir formata çevir
  String _formatJobName(BuildContext context, String job) {
    final l10n = context.l10n;
    // Eğer job zaten "Coach" içeriyorsa direkt döndür
    if (job.toLowerCase().contains('coach')) {
      return job;
    }
    // Localization kullanarak job ismini al
    switch (job) {
      case 'thought_and_habit_guide':
        return l10n.jobThoughtAndHabitGuide;
      case 'family_assistant':
        return l10n.jobFamilyAssistant;
      default:
        return job;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            
            // Filtre seçenekleri
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: widget.availableJobs.map((job) {
                  final isSelected = _selectedJobs.contains(job);
                  return _FilterChip(
                    label: _formatJobName(context, job),
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedJobs.remove(job);
                        } else {
                          _selectedJobs.add(job);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            
            // Save butonu
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: ElevatedButton(
                
                onPressed: () {
                  widget.onSave(_selectedJobs);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 0,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    Colors.transparent,
                  ),
                ),
                child: Container(
                  height: 45.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2BD383), Color(0xFF11998E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(40.w),
                  ),
                
                  child: Center(
                    child: Text(
                      context.l10n.save,
                      style: GoogleFonts.quicksand(
                        fontSize: 16.w,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.w),
        child: Container(
          height: 26.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black12 : Colors.white,
            borderRadius: BorderRadius.circular(20.w),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.black,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 12.w,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
