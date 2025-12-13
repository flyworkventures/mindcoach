import 'package:flutter/widgets.dart';

import '../../../core/models/test_questions_model.dart';
import '../../../l10n/app_localizations.dart';

List<Question> buildDummyQuestionsL10n(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return [
    Question(1, l10n.stressQ1),
    Question(2, l10n.stressQ2),
    Question(3, l10n.stressQ3),
    Question(4, l10n.stressQ4),
    Question(5, l10n.stressQ5),
    Question(6, l10n.stressQ6),
    Question(7, l10n.stressQ7),
  ];
}
