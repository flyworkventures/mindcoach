import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/screen_size_extensions.dart';
import '../constants/name_gender_strings.dart';
import 'package:mindcoach/View/profile_setup/domain/profile_models.dart';

class NameGenderStep extends StatefulWidget {
  final String fullName;
  final ValueChanged<String> onFullNameChanged;
  final Gender gender;
  final ValueChanged<Gender> onGenderChanged;
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const NameGenderStep({
    super.key,
    required this.fullName,
    required this.onFullNameChanged,
    required this.gender,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Center(
          child: Text(
            NameGenderStrings.title(context),
            style: widget.titleStyle,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
            child: Text(
              NameGenderStrings.subtitle(context),
              style: widget.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Text(
            NameGenderStrings.fullNameLabel(context),
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
            child: TextFormField(
              controller: _nameController,
              onChanged: widget.onFullNameChanged,
              cursorColor: Color(0xFF434343),
              decoration: InputDecoration(
                hintText: NameGenderStrings.fullNameHint(context),
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
            NameGenderStrings.genderLabel(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
              _GenderChipNoIcon(
                label: NameGenderStrings.noGender(context),
                isSelected: widget.gender == Gender.unknown,
                onTap: () => widget.onGenderChanged(Gender.unknown),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    ),
    );
  }
}
class _GenderChipNoIcon extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChipNoIcon({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45.h,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? const Color(0xFF2BD383) : const Color(0xFF000000),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF434343),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF434343),
                ),
                overflow: TextOverflow.ellipsis,
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
    );
  }
}