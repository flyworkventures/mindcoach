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
      // family_assistant 1-12
      case 'explanation_family_assistant_1':
        return l10n.explanationFamilyAssistant1;
      case 'explanation_family_assistant_2':
        return l10n.explanationFamilyAssistant2;
      case 'explanation_family_assistant_3':
        return l10n.explanationFamilyAssistant3;
      case 'explanation_family_assistant_4':
        return l10n.explanationFamilyAssistant4;
      case 'explanation_family_assistant_5':
        return l10n.explanationFamilyAssistant5;
      case 'explanation_family_assistant_6':
        return l10n.explanationFamilyAssistant6;
      case 'explanation_family_assistant_7':
        return l10n.explanationFamilyAssistant7;
      case 'explanation_family_assistant_8':
        return l10n.explanationFamilyAssistant8;
      case 'explanation_family_assistant_9':
        return l10n.explanationFamilyAssistant9;
      case 'explanation_family_assistant_10':
        return l10n.explanationFamilyAssistant10;
      case 'explanation_family_assistant_11':
        return l10n.explanationFamilyAssistant11;
      case 'explanation_family_assistant_12':
        return l10n.explanationFamilyAssistant12;

      // thought_and_habit_guide 1-12
      case 'explanation_thought_and_habit_guide_1':
        return l10n.explanationThoughtAndHabitGuide1;
      case 'explanation_thought_and_habit_guide_2':
        return l10n.explanationThoughtAndHabitGuide2;
      case 'explanation_thought_and_habit_guide_3':
        return l10n.explanationThoughtAndHabitGuide3;
      case 'explanation_thought_and_habit_guide_4':
        return l10n.explanationThoughtAndHabitGuide4;
      case 'explanation_thought_and_habit_guide_5':
        return l10n.explanationThoughtAndHabitGuide5;
      case 'explanation_thought_and_habit_guide_6':
        return l10n.explanationThoughtAndHabitGuide6;
      case 'explanation_thought_and_habit_guide_7':
        return l10n.explanationThoughtAndHabitGuide7;
      case 'explanation_thought_and_habit_guide_8':
        return l10n.explanationThoughtAndHabitGuide8;
      case 'explanation_thought_and_habit_guide_9':
        return l10n.explanationThoughtAndHabitGuide9;
      case 'explanation_thought_and_habit_guide_10':
        return l10n.explanationThoughtAndHabitGuide10;
      case 'explanation_thought_and_habit_guide_11':
        return l10n.explanationThoughtAndHabitGuide11;
      case 'explanation_thought_and_habit_guide_12':
        return l10n.explanationThoughtAndHabitGuide12;

      // adult 1-12
      case 'explanation_adult_1':
        return l10n.explanationAdult1;
      case 'explanation_adult_2':
        return l10n.explanationAdult2;
      case 'explanation_adult_3':
        return l10n.explanationAdult3;
      case 'explanation_adult_4':
        return l10n.explanationAdult4;
      case 'explanation_adult_5':
        return l10n.explanationAdult5;
      case 'explanation_adult_6':
        return l10n.explanationAdult6;
      case 'explanation_adult_7':
        return l10n.explanationAdult7;
      case 'explanation_adult_8':
        return l10n.explanationAdult8;
      case 'explanation_adult_9':
        return l10n.explanationAdult9;
      case 'explanation_adult_10':
        return l10n.explanationAdult10;
      case 'explanation_adult_11':
        return l10n.explanationAdult11;
      case 'explanation_adult_12':
        return l10n.explanationAdult12;

      // child 1-12
      case 'explanation_child_1':
        return l10n.explanationChild1;
      case 'explanation_child_2':
        return l10n.explanationChild2;
      case 'explanation_child_3':
        return l10n.explanationChild3;
      case 'explanation_child_4':
        return l10n.explanationChild4;
      case 'explanation_child_5':
        return l10n.explanationChild5;
      case 'explanation_child_6':
        return l10n.explanationChild6;
      case 'explanation_child_7':
        return l10n.explanationChild7;
      case 'explanation_child_8':
        return l10n.explanationChild8;
      case 'explanation_child_9':
        return l10n.explanationChild9;
      case 'explanation_child_10':
        return l10n.explanationChild10;
      case 'explanation_child_11':
        return l10n.explanationChild11;
      case 'explanation_child_12':
        return l10n.explanationChild12;

      // teenage 1-12
      case 'explanation_teenage_1':
        return l10n.explanationTeenage1;
      case 'explanation_teenage_2':
        return l10n.explanationTeenage2;
      case 'explanation_teenage_3':
        return l10n.explanationTeenage3;
      case 'explanation_teenage_4':
        return l10n.explanationTeenage4;
      case 'explanation_teenage_5':
        return l10n.explanationTeenage5;
      case 'explanation_teenage_6':
        return l10n.explanationTeenage6;
      case 'explanation_teenage_7':
        return l10n.explanationTeenage7;
      case 'explanation_teenage_8':
        return l10n.explanationTeenage8;
      case 'explanation_teenage_9':
        return l10n.explanationTeenage9;
      case 'explanation_teenage_10':
        return l10n.explanationTeenage10;
      case 'explanation_teenage_11':
        return l10n.explanationTeenage11;
      case 'explanation_teenage_12':
        return l10n.explanationTeenage12;

      // personal 1-12
      case 'explanation_personal_1':
        return l10n.explanationPersonal1;
      case 'explanation_personal_2':
        return l10n.explanationPersonal2;
      case 'explanation_personal_3':
        return l10n.explanationPersonal3;
      case 'explanation_personal_4':
        return l10n.explanationPersonal4;
      case 'explanation_personal_5':
        return l10n.explanationPersonal5;
      case 'explanation_personal_6':
        return l10n.explanationPersonal6;
      case 'explanation_personal_7':
        return l10n.explanationPersonal7;
      case 'explanation_personal_8':
        return l10n.explanationPersonal8;
      case 'explanation_personal_9':
        return l10n.explanationPersonal9;
      case 'explanation_personal_10':
        return l10n.explanationPersonal10;
      case 'explanation_personal_11':
        return l10n.explanationPersonal11;
      case 'explanation_personal_12':
        return l10n.explanationPersonal12;

      // exam_anxiety 1-12
      case 'explanation_exam_anxiety_1':
        return l10n.explanationExamAnxiety1;
      case 'explanation_exam_anxiety_2':
        return l10n.explanationExamAnxiety2;
      case 'explanation_exam_anxiety_3':
        return l10n.explanationExamAnxiety3;
      case 'explanation_exam_anxiety_4':
        return l10n.explanationExamAnxiety4;
      case 'explanation_exam_anxiety_5':
        return l10n.explanationExamAnxiety5;
      case 'explanation_exam_anxiety_6':
        return l10n.explanationExamAnxiety6;
      case 'explanation_exam_anxiety_7':
        return l10n.explanationExamAnxiety7;
      case 'explanation_exam_anxiety_8':
        return l10n.explanationExamAnxiety8;
      case 'explanation_exam_anxiety_9':
        return l10n.explanationExamAnxiety9;
      case 'explanation_exam_anxiety_10':
        return l10n.explanationExamAnxiety10;
      case 'explanation_exam_anxiety_11':
        return l10n.explanationExamAnxiety11;
      case 'explanation_exam_anxiety_12':
        return l10n.explanationExamAnxiety12;

      // emotional_balance 1-12
      case 'explanation_emotional_balance_1':
        return l10n.explanationEmotionalBalance1;
      case 'explanation_emotional_balance_2':
        return l10n.explanationEmotionalBalance2;
      case 'explanation_emotional_balance_3':
        return l10n.explanationEmotionalBalance3;
      case 'explanation_emotional_balance_4':
        return l10n.explanationEmotionalBalance4;
      case 'explanation_emotional_balance_5':
        return l10n.explanationEmotionalBalance5;
      case 'explanation_emotional_balance_6':
        return l10n.explanationEmotionalBalance6;
      case 'explanation_emotional_balance_7':
        return l10n.explanationEmotionalBalance7;
      case 'explanation_emotional_balance_8':
        return l10n.explanationEmotionalBalance8;
      case 'explanation_emotional_balance_9':
        return l10n.explanationEmotionalBalance9;
      case 'explanation_emotional_balance_10':
        return l10n.explanationEmotionalBalance10;
      case 'explanation_emotional_balance_11':
        return l10n.explanationEmotionalBalance11;
      case 'explanation_emotional_balance_12':
        return l10n.explanationEmotionalBalance12;

      // difficult_experiences 1-12
      case 'explanation_difficult_experiences_1':
        return l10n.explanationDifficultExperiences1;
      case 'explanation_difficult_experiences_2':
        return l10n.explanationDifficultExperiences2;
      case 'explanation_difficult_experiences_3':
        return l10n.explanationDifficultExperiences3;
      case 'explanation_difficult_experiences_4':
        return l10n.explanationDifficultExperiences4;
      case 'explanation_difficult_experiences_5':
        return l10n.explanationDifficultExperiences5;
      case 'explanation_difficult_experiences_6':
        return l10n.explanationDifficultExperiences6;
      case 'explanation_difficult_experiences_7':
        return l10n.explanationDifficultExperiences7;
      case 'explanation_difficult_experiences_8':
        return l10n.explanationDifficultExperiences8;
      case 'explanation_difficult_experiences_9':
        return l10n.explanationDifficultExperiences9;
      case 'explanation_difficult_experiences_10':
        return l10n.explanationDifficultExperiences10;
      case 'explanation_difficult_experiences_11':
        return l10n.explanationDifficultExperiences11;
      case 'explanation_difficult_experiences_12':
        return l10n.explanationDifficultExperiences12;

      // resilience_empowerment 1-12
      case 'explanation_resilience_empowerment_1':
        return l10n.explanationResilienceEmpowerment1;
      case 'explanation_resilience_empowerment_2':
        return l10n.explanationResilienceEmpowerment2;
      case 'explanation_resilience_empowerment_3':
        return l10n.explanationResilienceEmpowerment3;
      case 'explanation_resilience_empowerment_4':
        return l10n.explanationResilienceEmpowerment4;
      case 'explanation_resilience_empowerment_5':
        return l10n.explanationResilienceEmpowerment5;
      case 'explanation_resilience_empowerment_6':
        return l10n.explanationResilienceEmpowerment6;
      case 'explanation_resilience_empowerment_7':
        return l10n.explanationResilienceEmpowerment7;
      case 'explanation_resilience_empowerment_8':
        return l10n.explanationResilienceEmpowerment8;
      case 'explanation_resilience_empowerment_9':
        return l10n.explanationResilienceEmpowerment9;
      case 'explanation_resilience_empowerment_10':
        return l10n.explanationResilienceEmpowerment10;
      case 'explanation_resilience_empowerment_11':
        return l10n.explanationResilienceEmpowerment11;
      case 'explanation_resilience_empowerment_12':
        return l10n.explanationResilienceEmpowerment12;

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
