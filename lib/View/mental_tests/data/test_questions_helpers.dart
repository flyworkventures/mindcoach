import 'dart:math';
import 'package:flutter/widgets.dart';

import '../../../core/models/test_questions_model.dart';
import '../../../l10n/app_localizations.dart';

List<Question> buildDummyQuestionsL10n(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  final allQuestions = [
    Question(1, l10n.stressQ1),
    Question(2, l10n.stressQ2),
    Question(3, l10n.stressQ3),
    Question(4, l10n.stressQ4),
    Question(5, l10n.stressQ5),
    Question(6, l10n.stressQ6),
    Question(7, l10n.stressQ7),
    Question(8, l10n.stressQ8),
    Question(9, l10n.stressQ9),
    Question(10, l10n.stressQ10),
    Question(11, l10n.stressQ11),
    Question(12, l10n.stressQ12),
    Question(13, l10n.stressQ13),
    Question(14, l10n.stressQ14),
    Question(15, l10n.stressQ15),
    Question(16, l10n.stressQ16),
    Question(17, l10n.stressQ17),
    Question(18, l10n.stressQ18),
    Question(19, l10n.stressQ19),
    Question(20, l10n.stressQ20),
    Question(21, l10n.stressQ21),
    Question(22, l10n.stressQ22),
    Question(23, l10n.stressQ23),
    Question(24, l10n.stressQ24),
    Question(25, l10n.stressQ25),
  ];

  allQuestions.shuffle(Random());
  return allQuestions.take(7).toList();
}
