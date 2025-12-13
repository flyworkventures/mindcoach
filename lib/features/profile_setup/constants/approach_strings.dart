// Örnek konum: lib/features/profile_setup/constants/approach_strings.dart

import 'package:flutter/widgets.dart';
import 'package:mindcoach/l10n/app_localizations.dart';

import '../../../../l10n/app_localizations.dart';

/// Uzmanın yaklaşım tipi için enum
enum ApproachType {
  patient,
  supportive,
  convincing,
  energetic,
  humorous,
}

class ApproachStrings {
  ApproachStrings._();

  /// Varsayılan yaklaşım (Supportive)
  static ApproachType get defaultApproach => ApproachType.supportive;

  /// Başlık metni
  static String title(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return loc.approachTitle;
    // l10n'da: "approachTitle": "How would you like the specialist to approach you?"
    // TR: "Uzmanın sana nasıl yaklaşmasını istersin?"
  }

  /// Listede gözükecek yaklaşım etiketleri
  static String label(BuildContext context, ApproachType type) {
    final loc = AppLocalizations.of(context)!;

    switch (type) {
      case ApproachType.patient:
        return loc.approachPatient;
    // "approachPatient": "Patient" / "Sabırlı"
      case ApproachType.supportive:
        return loc.approachSupportive;
    // "approachSupportive": "Supportive" / "Destekleyici"
      case ApproachType.convincing:
        return loc.approachConvincing;
    // "approachConvincing": "Convincing" / "İkna edici"
      case ApproachType.energetic:
        return loc.approachEnergetic;
    // "approachEnergetic": "Energetic" / "Enerjik"
      case ApproachType.humorous:
        return loc.approachHumorous;
    // "approachHumorous": "Humorous" / "Esprili"
    }
  }
}
