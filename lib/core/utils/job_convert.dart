import 'package:flutter/material.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

class JobConvert {
  final String value;
  final BuildContext context;

  JobConvert(this.value, this.context);

  String call() {
    final l10n = context.l10n;
    switch (value) {
      case 'family_assistant':
        return l10n.jobFamilyAssistant;
      case 'thought_and_habit_guide':
        return l10n.jobThoughtAndHabitGuide;
      case 'adult':
        return l10n.jobAdult;
      case 'child':
        return l10n.jobChild;
      case 'teenage':
        return l10n.jobTeenage;
      case 'personal':
        return l10n.jobPersonal;
      case 'exam_anxiety':
        return l10n.jobExamAnxiety;
      case 'emotional_balance':
        return l10n.jobEmotionalBalance;
      case 'difficult_experiences':
        return l10n.jobDifficultExperiences;
      case 'resilience_empowerment':
        return l10n.jobResilienceEmpowerment;
      default:
        return value;
    }
  }
}
