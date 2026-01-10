import 'package:flutter/material.dart';
import 'package:mindcoach/core/global_constants/month_strings.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/View/specialists_screen/constants/specialists_strings.dart';

String _keyOf(String s) => s.trim().toLowerCase();

String specialistName(BuildContext context, String specialistNameOrKey) {
  final key = _keyOf(specialistNameOrKey);
  switch (key) {
    case 'aura':
      return SpecialistsStrings.auraName(context);
    case 'zen':
      return SpecialistsStrings.zenName(context);
    case 'elara':
      return SpecialistsStrings.elaraName(context);
    case 'orion':
      return SpecialistsStrings.orionName(context);
    case 'cyra':
      return SpecialistsStrings.cyraName(context);
    default:
      return specialistNameOrKey; // fallback
  }
}

String specialistTitle(BuildContext context, String specialistNameOrKey) {
  final key = _keyOf(specialistNameOrKey);
  switch (key) {
    case 'aura':
      return SpecialistsStrings.auraTitle(context);
    case 'zen':
      return SpecialistsStrings.zenTitle(context);
    case 'elara':
      return SpecialistsStrings.elaraTitle(context);
    case 'orion':
      return SpecialistsStrings.orionTitle(context);
    case 'cyra':
      return SpecialistsStrings.cyraTitle(context);
    default:
      return '';
  }
}

String avatarForKey(String specialistNameOrKey) {
  final key = _keyOf(specialistNameOrKey);
  switch (key) {
    case 'aura':
      return 'assets/images/kızıl.png';
    case 'zen':
      return 'assets/images/zen.png';
    case 'elara':
      return 'assets/images/elara.png';
    case 'orion':
      return 'assets/images/orion.png';
    case 'cyra':
      return 'assets/images/cyra.png';
    default:
      return 'assets/images/profile_avatar.jpeg';
  }
}

String relativeLabel(BuildContext context, DateTime dateTime) {
  final l = context.l10n;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

  final diffDays = target.difference(today).inDays;

  if (diffDays == 0) return l.relativeToday;
  if (diffDays == 1) return l.relativeTomorrow;
  if (diffDays == -1) return l.relativeYesterday;

  if (diffDays < -1) {
    final daysAgo = -diffDays;
    final weeks = daysAgo ~/ 7;

    if (weeks >= 1) return l.relativeWeeksAgo(weeks);
    return l.relativeDaysAgo(daysAgo);
  }

  final monthLabel = MonthStrings.name(context, dateTime.month);
  return '$monthLabel ${dateTime.day}';
}
