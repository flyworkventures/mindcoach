// lib/core/utils/time_format_utils.dart
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class TimeFormatUtils {
  TimeFormatUtils._();

  /// Locale'e göre saat formatlar.
  /// - tr, de  -> 24 saat (HH:mm)
  /// - en      -> 12 saat (h:mm a)
  /// İstersen diğer diller için de genişletirsin.
  static String formatTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;

    final bool use24h = lang == 'tr' || lang == 'de';
    final pattern = use24h ? 'HH:mm' : 'h:mm a';

    return DateFormat(pattern, locale.toLanguageTag())
        .format(dateTime.toLocal());
  }

  /// Eğer ilerde tarih + saat birlikte göstermek istersen:
  /// Örn: "25 October, 09:00"
  static String formatDateTimeWithMonth(
      BuildContext context,
      DateTime dateTime, {
        bool includeYear = false,
      }) {
    final locale = Localizations.localeOf(context);
    final lang = locale.languageCode;
    final bool use24h = lang == 'tr' || lang == 'de';
    final timePattern = use24h ? 'HH:mm' : 'h:mm a';

    final datePattern = includeYear ? 'd MMM yyyy' : 'd MMM';
    final pattern = '$datePattern – $timePattern';

    return DateFormat(pattern, locale.toLanguageTag())
        .format(dateTime.toLocal());
  }
}
