import 'package:flutter/widgets.dart';
import '../../../l10n/app_localizations.dart';

List<String> buildAnswerOptionsL10n(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    l10n.never,
    l10n.sometimes,
    l10n.often,
    l10n.always,
  ];
}
