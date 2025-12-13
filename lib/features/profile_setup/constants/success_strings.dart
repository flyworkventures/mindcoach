import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';

class SuccessStrings {
  SuccessStrings._();

  static AppLocalizations _loc(BuildContext context) =>
      AppLocalizations.of(context)!;

  static String title(BuildContext context) =>
      _loc(context).successTitle;

  static String subtitle(BuildContext context) =>
      _loc(context).successSubtitle;
}
