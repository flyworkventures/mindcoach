import '../../../l10n/app_localizations.dart';

/// OnboardingTexts
/// ------------------------------------------------------------
/// Onboarding ekranındaki title/description alanlarını
/// liste halinde kullanmak için extension.
///
/// Not:
/// - ARB key'leri değişmez.
/// - Yeni slide eklenirse burada listeye eklenir.
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
