import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/View/ProfileSetupView/constants/name_gender_strings.dart';
import 'package:mindcoach/View/ProfileSetupView/domain/profile_models.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

// ============================================================================
// 4. EKRAN 1: NAME & GENDER STEP TASARIMI
// ============================================================================

class NameGenderStep extends StatefulWidget {
  final String fullName;
  final ValueChanged<String> onFullNameChanged;
  // Not: Eğer başlangıçta boş gelmesi için Gender'ı nullable (Gender?) yaptıysan
  // buradaki tipleri de ona göre güncellemen gerekebilir.
  final Gender? gender;
  final ValueChanged<Gender> onGenderChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const NameGenderStep({
    super.key,
    required this.fullName,
    required this.onFullNameChanged,
    this.gender,
    required this.onGenderChanged,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  State<NameGenderStep> createState() => _NameGenderStepState();
}

class _NameGenderStepState extends State<NameGenderStep> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
  }

  @override
  void didUpdateWidget(NameGenderStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullName != widget.fullName) {
      _nameController.text = widget.fullName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Metinler Sola Dayalı
        children: [
          // ---------------- Başlık & Alt Başlık ----------------
          Text(
            NameGenderStrings.title(context),
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            NameGenderStrings.subtitle(context),
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF96989C),
            ),
          ),
          const SizedBox(height: 24),

          // ---------------- Name Input ----------------
          Text(
            NameGenderStrings.fullNameLabel(context),
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF96989C),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50.h, // Figma Height
            child: TextFormField(
              controller: _nameController,
              onChanged: widget.onFullNameChanged,
              maxLength: 25,
              cursorColor: const Color(0xFF21BC87),
              decoration: InputDecoration(
                hintText: NameGenderStrings.fullNameHint(context),
                counterText: '',
                hintStyle: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFCACACA),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, // Figma Padding
                  vertical: 10,
                ),
                // Unselected Border: 2px #E2E2E2, Radius: 16px
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E2E2),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E2E2),
                    width: 2,
                  ),
                ),
                // Selected Border: 2px #21BC87
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF21BC87),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ---------------- Gender Selection ----------------
          Text(
            NameGenderStrings.genderLabel(context),
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF96989C),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GenderChip(
                  label: NameGenderStrings.maleLabel(context),
                  icon: Icons.male,
                  isSelected: widget.gender == Gender.male,
                  onTap: () => widget.onGenderChanged(Gender.male),
                ),
              ),
              const SizedBox(width: 12), // Figma Gap: 10-12px
              Expanded(
                child: _GenderChip(
                  label: NameGenderStrings.femaleLabel(context),
                  icon: Icons.female,
                  isSelected: widget.gender == Gender.female,
                  onTap: () => widget.onGenderChanged(Gender.female),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ---------------- Prefer not to mention ----------------
          Center(
            child: GestureDetector(
              onTap: () => widget.onGenderChanged(Gender.unknown),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16,
                ),
                child: Text(
                  NameGenderStrings.noGender(context),
                  style: GoogleFonts.quicksand(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    // Seçiliyse Yeşil (#21BC87), değilse Gri (#96989C)
                    color: widget.gender == Gender.unknown
                        ? const Color(0xFF21BC87)
                        : const Color(0xFF96989C),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

// ---------------- Gender Seçim Butonları Tasarımı ----------------
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50.h, // Figma Height: 50px
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          // Seçiliyse %10 Yeşil Arkaplan, Değilse Beyaz
          color: isSelected
              ? const Color(0xFF21BC87).withOpacity(0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(16), // Figma Radius: 16px
          border: Border.all(
            // Seçiliyse 2px Yeşil, Değilse 2px Gri (#E2E2E2)
            color: isSelected
                ? const Color(0xFF21BC87)
                : const Color(0xFFE2E2E2),
            width: 2, // Figma Border: 2px
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFF21BC87)
                  : const Color(0xFF96989C),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF21BC87)
                      : const Color(0xFF96989C),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
