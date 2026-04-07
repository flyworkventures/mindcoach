import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profile_models.dart';

class SupportAreaStrings {
  SupportAreaStrings._();

  static AppLocalizations _loc(BuildContext context) => AppLocalizations.of(context)!;

  static String title(BuildContext context) => _loc(context).supportAreaTitle;
  static String subtitle(BuildContext context) => _loc(context).supportAreaSubtitle;

  static String optionLabel(BuildContext context, SupportArea value) {
    final loc = _loc(context);
    switch (value) {
      case SupportArea.individual:
        return loc.supportAreaIndividual;
      case SupportArea.family:
        return loc.supportAreaFamily;
      case SupportArea.career:
        return loc.supportAreaCareer;
      case SupportArea.education:
        return loc.supportAreaEducation;
      case SupportArea.personalDevelopment:
        return loc.supportAreaPersonalDevelopment;
    }
  }
}
