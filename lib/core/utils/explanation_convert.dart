import 'package:flutter/material.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

/// Backend'den gelen explanation key'lerini (ör: "explanation_family_assistant_1")
/// lokalize edilmiş string'lere çevirir.
class ExplanationConvert {
  final BuildContext context;

  ExplanationConvert(this.context);

  String call(String key) {
    final l10n = context.l10n;
    switch (key) {
      // Per-coach unique explanations
      case 'explanation_family_assistant_1':
        return l10n.explanationFamilyAssistant1;
      case 'explanation_family_assistant_2':
        return l10n.explanationFamilyAssistant2;
      case 'explanation_adult_1':
        return l10n.explanationAdult1;
      case 'explanation_adult_2':
        return l10n.explanationAdult2;
      case 'explanation_teenage_1':
        return l10n.explanationTeenage1;
      case 'explanation_teenage_2':
        return l10n.explanationTeenage2;
      case 'explanation_child_1':
        return l10n.explanationChild1;
      case 'explanation_child_2':
        return l10n.explanationChild2;
      case 'explanation_personal_1':
        return l10n.explanationPersonal1;
      case 'explanation_personal_2':
        return l10n.explanationPersonal2;
      case 'explanation_exam_anxiety_1':
        return l10n.explanationExamAnxiety1;
      case 'explanation_exam_anxiety_2':
        return l10n.explanationExamAnxiety2;
      case 'explanation_emotional_balance_1':
        return l10n.explanationEmotionalBalance1;
      case 'explanation_thought_and_habit_guide_1':
        return l10n.explanationThoughtAndHabitGuide1;
      case 'explanation_difficult_experiences_1':
        return l10n.explanationDifficultExperiences1;
      case 'explanation_resilience_empowerment_1':
        return l10n.explanationResilienceEmpowerment1;

      // Fallback per-type explanations
      case 'explanation_family_assistant':
        return l10n.explanationFamilyAssistant;
      case 'explanation_adult':
        return l10n.explanationAdult;
      case 'explanation_child':
        return l10n.explanationChild;
      case 'explanation_teenage':
        return l10n.explanationTeenage;
      case 'explanation_personal':
        return l10n.explanationPersonal;
      case 'explanation_exam_anxiety':
        return l10n.explanationExamAnxiety;

      default:
        // Eğer key bilinmiyorsa, doğrudan string'i döndür
        return key;
    }
  }
}
