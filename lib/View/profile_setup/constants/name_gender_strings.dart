import 'package:flutter/widgets.dart';
import 'package:mindcoach/l10n/app_localizations.dart';
import '../domain/profile_models.dart'; // Gender enum

class NameGenderStrings {
  NameGenderStrings._();

  static AppLocalizations _loc(BuildContext context) =>
      AppLocalizations.of(context)!;

  static String title(BuildContext context) =>
      _loc(context).nameGenderTitle;

  static String subtitle(BuildContext context) =>
      _loc(context).nameGenderSubtitle;

  static String fullNameLabel(BuildContext context) =>
      _loc(context).nameGenderFullNameLabel;

  static String fullNameHint(BuildContext context) =>
      _loc(context).nameGenderFullNameHint;

  static String genderLabel(BuildContext context) =>
      _loc(context).nameGenderGenderLabel;

  static String maleLabel(BuildContext context) =>
      _loc(context).nameGenderMale;

  static String femaleLabel(BuildContext context) =>
      _loc(context).nameGenderFemale;

  static String preferNotToSayLabel(BuildContext context) =>
      _loc(context).nameGenderPreferNotToSay;

  static String noGender(BuildContext context) =>
      _loc(context).nameGenderPreferNotToSay;

  /// ✅ NEW: enum → localized label
  static String genderLabelFor(BuildContext context, Gender gender) {
    switch (gender) {
      case Gender.male:
        return maleLabel(context);
      case Gender.female:
        return femaleLabel(context);
      case Gender.unknown:
        return noGender(context);
    }
  }
}
