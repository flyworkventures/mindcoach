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
      default:
        return value;
    }
  }
}
