import 'package:flutter/widgets.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

class MonthStrings {
  MonthStrings._();

  /// 1–12 arası ay numarasına göre localized isim döner
  static String name(BuildContext context, int month) {
    final l = context.l10n;

    switch (month) {
      case 1:
        return l.january;
      case 2:
        return l.february;
      case 3:
        return l.march;
      case 4:
        return l.april;
      case 5:
        return l.may;
      case 6:
        return l.june;
      case 7:
        return l.july;
      case 8:
        return l.august;
      case 9:
        return l.september;
      case 10:
        return l.october;
      case 11:
        return l.november;
      case 12:
        return l.december;
      default:
        return month.toString().padLeft(2, '0');
    }
  }

  /// Eğer kısaltma da kullanmak istersen:
  static String shortName(BuildContext context, int month) {
    final l = context.l10n;

    switch (month) {
      case 1:
        return l.januaryShort;
      case 2:
        return l.februaryShort;
      case 3:
        return l.marchShort;
      case 4:
        return l.aprilShort;
      case 5:
        return l.mayShort;
      case 6:
        return l.juneShort;
      case 7:
        return l.julyShort;
      case 8:
        return l.augustShort;
      case 9:
        return l.septemberShort;
      case 10:
        return l.octoberShort;
      case 11:
        return l.novemberShort;
      case 12:
        return l.decemberShort;
      default:
        return month.toString().padLeft(2, '0');
    }
  }

}
