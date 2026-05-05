import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../core/models/test_questions_model.dart';
import '../../../l10n/app_localizations.dart';

List<Question> buildQuestionsL10n(
  BuildContext context, {
  required String testTitle,
  required int totalQuestions,
  required int seed,
}) {
  final l10n = AppLocalizations.of(context)!;
  final langCode = Localizations.localeOf(context).languageCode;
  final isAnxiety = testTitle == l10n.anxietyScaleTest;

  final stressBase = <String>[
    l10n.stressQ1,
    l10n.stressQ2,
    l10n.stressQ3,
    l10n.stressQ4,
    l10n.stressQ5,
    l10n.stressQ6,
    l10n.stressQ7,
    l10n.stressQ8,
    l10n.stressQ9,
    l10n.stressQ10,
    l10n.stressQ11,
    l10n.stressQ12,
    l10n.stressQ13,
    l10n.stressQ14,
    l10n.stressQ15,
    l10n.stressQ16,
    l10n.stressQ17,
    l10n.stressQ18,
    l10n.stressQ19,
    l10n.stressQ20,
    l10n.stressQ21,
    l10n.stressQ22,
    l10n.stressQ23,
    l10n.stressQ24,
    l10n.stressQ25,
  ];

  final stressTopics = <String>[
    l10n.featureStressManagement,
    l10n.featureLifeBalance,
    l10n.featureSleepImprovement,
    l10n.featureMindfulness,
    l10n.featureEmotionalRegulation,
    l10n.featureEmotionalAwareness,
    l10n.featureRelaxationMethods,
    l10n.featureOverthinking,
    l10n.featureFearManagement,
    l10n.featureEmotionalHealing,
    l10n.featureAnxietySupport,
    l10n.featureLoneliness,
    l10n.featureMotivation,
  ];

  final anxietyBase = <String>[
    l10n.stressQ3,  // I felt nervous or anxious
    l10n.stressQ6,  // I had trouble falling asleep
    l10n.stressQ2,  // I tend to overreact to events
    l10n.stressQ1,  // I had trouble relaxing
    l10n.stressQ7,  // I felt overwhelmed
    l10n.stressQ9,  // I experienced shortness of breath
    l10n.stressQ10, // I had a sense of doom or panic
    l10n.stressQ13, // My heart raced or palpitations
    l10n.stressQ16, // I had negative thoughts
    l10n.stressQ22, // I felt trapped or helpless
    _topicQuestion(langCode, l10n.featureAnxietySupport, anxiety: true),
    _topicQuestion(langCode, l10n.featureOverthinking, anxiety: true),
  ];

  final anxietyTopics = <String>[
    l10n.featureFearManagement,
    l10n.featureEmotionalRegulation,
    l10n.featureEmotionalAwareness,
    l10n.featureMindfulness,
    l10n.featureSleepImprovement,
    l10n.featureDecisionMaking,
    l10n.featureSelfConfidence,
    l10n.featureConfidenceBuilding,
    l10n.featureStressManagement,
    l10n.featureRelaxationMethods,
    l10n.featureEmotionalHealing,
    l10n.featureLoneliness,
    l10n.featureLifeBalance,
  ];

  final stressPool = [
    ...stressBase,
    ...stressTopics.map((topic) => _topicQuestion(langCode, topic)),
  ];
  final anxietyPool = [
    ...anxietyBase,
    ...anxietyTopics.map(
      (topic) => _topicQuestion(langCode, topic, anxiety: true),
    ),
  ];

  final source = isAnxiety ? anxietyPool : stressPool;
  final count = totalQuestions.clamp(1, source.length);
  final shuffled = List<String>.from(source)..shuffle(Random(seed));
  return List.generate(count, (index) => Question(index + 1, shuffled[index]));
}

String _topicQuestion(
  String languageCode,
  String topic, {
  bool anxiety = false,
}) {
  switch (languageCode) {
    case 'tr':
      return anxiety
          ? 'Son bir haftada "$topic" ile ilgili belirgin kaygı yaşadım.'
          : 'Son bir haftada "$topic" konusunda zorlandığımı hissettim.';
    case 'de':
      return anxiety
          ? 'In der letzten Woche habe ich deutliche Angst in Bezug auf "$topic" gespurt.'
          : 'In der letzten Woche hatte ich Schwierigkeiten im Bereich "$topic".';
    case 'es':
      return anxiety
          ? 'En la ultima semana senti ansiedad notable relacionada con "$topic".'
          : 'En la ultima semana senti dificultades en el area de "$topic".';
    case 'fr':
      return anxiety
          ? 'Au cours de la derniere semaine, j\'ai ressenti une anxiete marquee liee a "$topic".'
          : 'Au cours de la derniere semaine, j\'ai eu des difficultes concernant "$topic".';
    case 'hi':
      return anxiety
          ? 'Pichhle hafte maine "$topic" se judi spasht chinta mehsoos ki.'
          : 'Pichhle hafte mujhe "$topic" ke mamle mein mushkil mehsoos hui.';
    case 'it':
      return anxiety
          ? 'Nell\'ultima settimana ho provato ansia evidente legata a "$topic".'
          : 'Nell\'ultima settimana ho avuto difficolta nell\'area "$topic".';
    case 'ja':
      return anxiety
          ? 'この1週間で「$topic」に関して強い不安を感じました。'
          : 'この1週間で「$topic」に関して負担を感じました。';
    case 'ko':
      return anxiety
          ? '지난 일주일 동안 "$topic"와 관련된 불안을 뚜렷하게 느꼈습니다.'
          : '지난 일주일 동안 "$topic" 영역에서 어려움을 느꼈습니다.';
    case 'pt':
      return anxiety
          ? 'Na ultima semana senti ansiedade significativa relacionada a "$topic".'
          : 'Na ultima semana senti dificuldade na area de "$topic".';
    case 'ru':
      return anxiety
          ? 'За последнюю неделю я испытывал(а) выраженную тревогу, связанную с "$topic".'
          : 'За последнюю неделю я чувствовал(а) трудности в области "$topic".';
    case 'zh':
      return anxiety
          ? '在过去一周里，我在"$topic"方面感到明显焦虑。'
          : '在过去一周里，我在"$topic"方面感到吃力。';
    default:
      return anxiety
          ? 'Over the past week, I felt clear anxiety related to "$topic".'
          : 'Over the past week, I felt challenged in "$topic".';
  }
}
