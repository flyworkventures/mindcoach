import 'package:flutter/widgets.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import '../../../core/models/appointment_info.dart';

class HomeStrings {
  HomeStrings._();

  static String topicLabel(BuildContext context, String topicKey) {
    final l = context.l10n;
    switch (topicKey) {
      case 'feelingGood':
        return l.topicFeelingGood;
      default:
        return topicKey;
    }
  }

  static String localizedSpecialistName(BuildContext context, String rawName) {
    final l = context.l10n;
    switch (rawName) {
      case 'aura':
        return l.specialistAuraName;
      case 'zen':
        return l.specialistZenName;
      case 'elara':
        return l.specialistElaraName;
      case 'orion':
        return l.specialistOrionName;
      case 'cyra':
        return l.specialistCyraName;
      default:
        return rawName;
    }
  }

  static String appointmentDescription(BuildContext context, AppointmentInfo info) {
    final l = context.l10n;
    final topicText = topicLabel(context, info.topicKey);
    final name = localizedSpecialistName(context, info.specialistName);

    return l.appointmentDescription(name, topicText);
  }
}
