import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

extension OnboardingTexts on AppLocalizations {
  List<String> get onboardingTitles => [
    onboardingTitle1,
    onboardingTitle2,
    onboardingTitle3,
  ];

  List<String> get onboardingDescriptions => [
    onboardingDescription1,
    onboardingDescription2,
    onboardingDescription3,
  ];
}
