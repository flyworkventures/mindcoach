import 'package:flutter/widgets.dart';
import 'package:mindcoach/l10n/app_localizations.dart';

import '../../../../core/utils/context_l10n_extensions.dart';

class DobStrings {
  DobStrings._();


  /// Yıl aralığı
  static const int minYear = 1920;

  static int maxYear() {
    final now = DateTime.now();
    return now.year - 18;
  }

  /// Varsayılan seçilecek yıl (örneğin 25 yaş civarı)
  static int defaultYear() {
    final now = DateTime.now();
    final year = now.year - 25;
    final max = maxYear();
    if (year > max) return max;
    if (year < minYear) return minYear;
    return year;
  }



  static String title(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.dobTitle;
  }

  static String subtitle(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.dobSubtitle;
  }

  static String dayLabel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.dobDayLabel;
  }

  static String monthLabel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.dobMonthLabel;
  }

  static String yearLabel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.dobYearLabel;
  }

  static String errorInvalid(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.dobErrorInvalid;
  }
}
