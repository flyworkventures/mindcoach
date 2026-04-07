import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profile_models.dart';

/// AvailableDaysStrings
/// ------------------------------------------------------------
/// Weekday enum’unu localized label’a çevirir.
/// UI canonical string taşımaz.
class AvailableDaysStrings {
  AvailableDaysStrings._();

  static AppLocalizations _loc(BuildContext context) => AppLocalizations.of(context)!;

  static String title(BuildContext context) => _loc(context).availableDaysTitle;
  static String subtitle(BuildContext context) => _loc(context).availableDaysSubtitle;

  static String dayLabel(BuildContext context, Weekday day) {
    final loc = _loc(context);
    switch (day) {
      case Weekday.monday:
        return loc.dayMonday;
      case Weekday.tuesday:
        return loc.dayTuesday;
      case Weekday.wednesday:
        return loc.dayWednesday;
      case Weekday.thursday:
        return loc.dayThursday;
      case Weekday.friday:
        return loc.dayFriday;
      case Weekday.saturday:
        return loc.daySaturday;
      case Weekday.sunday:
        return loc.daySunday;
    }
  }
}
