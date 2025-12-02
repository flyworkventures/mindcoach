import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Understand Yourself Better'**
  String get onboardingTitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Bring Order to Your Mind'**
  String get onboardingTitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'A Guide Always Within Reach'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDescription1.
  ///
  /// In en, this message translates to:
  /// **'Mind Coach helps you clarify your thoughts, explore your inner world, and navigate life with greater awareness. Take charge of your own journey with confidence.'**
  String get onboardingDescription1;

  /// No description provided for @onboardingDescription2.
  ///
  /// In en, this message translates to:
  /// **'Stress, overthinking, hesitation, or scattered ideas… Mind Coach turns them into clear insights tailored to you. Discover the power of a focused and organized mind.'**
  String get onboardingDescription2;

  /// No description provided for @onboardingDescription3.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts, ask questions, and explore new perspectives anytime. Mind Coach supports your growth and helps you move forward with clarity and ease.'**
  String get onboardingDescription3;

  /// No description provided for @onboardingTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing up for swipe, you agree to our '**
  String get onboardingTermsPrefix;

  /// No description provided for @onboardingTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get onboardingTermsOfService;

  /// No description provided for @onboardingTermsMiddle.
  ///
  /// In en, this message translates to:
  /// **'. Learn how we process your data in our '**
  String get onboardingTermsMiddle;

  /// No description provided for @onboardingPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onboardingPrivacyPolicy;

  /// No description provided for @onboardingTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get onboardingTermsAnd;

  /// No description provided for @onboardingCookiesPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cookies Policy'**
  String get onboardingCookiesPolicy;

  /// No description provided for @onboardingTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get onboardingTermsSuffix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
