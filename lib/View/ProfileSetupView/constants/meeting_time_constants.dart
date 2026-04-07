import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/profile_models.dart';

class MeetingTimeStrings {
  MeetingTimeStrings._();

  static AppLocalizations _loc(BuildContext context) => AppLocalizations.of(context)!;

  static String title(BuildContext context) => _loc(context).meetingTimeTitle;
  static String subtitle(BuildContext context) => _loc(context).meetingTimeSubtitle;

  static String label(BuildContext context, MeetingTime time) {
    final loc = _loc(context);
    switch (time) {
      case MeetingTime.morning:
        return loc.meetingTimeMorning;
      case MeetingTime.afternoon:
        return loc.meetingTimeAfternoon;
      case MeetingTime.evening:
        return loc.meetingTimeEvening;
      case MeetingTime.flexible:
        return loc.meetingTimeFlexible;
    }
  }

  static String range(BuildContext context, MeetingTime time) {
    final loc = _loc(context);
    switch (time) {
      case MeetingTime.morning:
        return loc.meetingTimeMorningRange;
      case MeetingTime.afternoon:
        return loc.meetingTimeAfternoonRange;
      case MeetingTime.evening:
        return loc.meetingTimeEveningRange;
      case MeetingTime.flexible:
        return loc.meetingTimeFlexibleRange;
    }
  }
}
