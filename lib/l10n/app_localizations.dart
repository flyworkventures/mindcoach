import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

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
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @relaxingSound.
  ///
  /// In en, this message translates to:
  /// **'Relaxing Sound'**
  String get relaxingSound;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @premiumHeadlinePart1.
  ///
  /// In en, this message translates to:
  /// **'A space just to be '**
  String get premiumHeadlinePart1;

  /// No description provided for @premiumHeadlineHighlight.
  ///
  /// In en, this message translates to:
  /// **'understood'**
  String get premiumHeadlineHighlight;

  /// No description provided for @premiumHeadlinePart2.
  ///
  /// In en, this message translates to:
  /// **',\nwithout judgment.'**
  String get premiumHeadlinePart2;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thousands have taken this step. Now it\'s your turn — 3 days completely free.'**
  String get premiumSubtitle;

  /// No description provided for @premiumFeature1.
  ///
  /// In en, this message translates to:
  /// **'24/7 unlimited access'**
  String get premiumFeature1;

  /// No description provided for @premiumFeature2.
  ///
  /// In en, this message translates to:
  /// **'Priority connection'**
  String get premiumFeature2;

  /// No description provided for @premiumFeature3.
  ///
  /// In en, this message translates to:
  /// **'Advanced AI tailored for you'**
  String get premiumFeature3;

  /// No description provided for @premiumAnnualDiscount.
  ///
  /// In en, this message translates to:
  /// **'40% off on annual plan'**
  String get premiumAnnualDiscount;

  /// No description provided for @premiumCta.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get premiumCta;

  /// No description provided for @premiumPrice.
  ///
  /// In en, this message translates to:
  /// **'\$3.99'**
  String get premiumPrice;

  /// No description provided for @premiumPricePeriod.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get premiumPricePeriod;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Feeling overwhelmed?'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Talk to a certified guide in minutes — whenever you need it.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Talk your way.'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Text, voice, or video'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Find the right guide for you.'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Get matched based on your goals, schedule and preferences.'**
  String get onboardingDesc3;

  /// No description provided for @swipeToContinue.
  ///
  /// In en, this message translates to:
  /// **'Swipe to continue'**
  String get swipeToContinue;

  /// No description provided for @onboardingTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By signing up for MindCoach, you agree to our '**
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

  /// No description provided for @nameGenderStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself'**
  String get nameGenderStepTitle;

  /// No description provided for @nameGenderStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A short bio helps others know the real you. Keep it fun and genuine.'**
  String get nameGenderStepSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @findMyCoaches.
  ///
  /// In en, this message translates to:
  /// **'Find My Guides'**
  String get findMyCoaches;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find your guide and start your journey. Takes 2 minutes.'**
  String get loginSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @dataPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Your data is never shared with third parties. You can delete your account at any time.'**
  String get dataPrivacyNotice;

  /// No description provided for @approachTitle.
  ///
  /// In en, this message translates to:
  /// **'How should your guide approach you?'**
  String get approachTitle;

  /// No description provided for @approachSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us match your personality to the right guide'**
  String get approachSubtitle;

  /// No description provided for @approachPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get approachPatient;

  /// No description provided for @approachSupportive.
  ///
  /// In en, this message translates to:
  /// **'Supportive'**
  String get approachSupportive;

  /// No description provided for @approachConvincing.
  ///
  /// In en, this message translates to:
  /// **'Convincing'**
  String get approachConvincing;

  /// No description provided for @approachEnergetic.
  ///
  /// In en, this message translates to:
  /// **'Energetic'**
  String get approachEnergetic;

  /// No description provided for @approachHumorous.
  ///
  /// In en, this message translates to:
  /// **'Humorous'**
  String get approachHumorous;

  /// No description provided for @dobTitle.
  ///
  /// In en, this message translates to:
  /// **'When were you born?'**
  String get dobTitle;

  /// No description provided for @dobSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We personalize the experience based on your age.'**
  String get dobSubtitle;

  /// No description provided for @dobDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dobDayLabel;

  /// No description provided for @dobMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get dobMonthLabel;

  /// No description provided for @dobYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get dobYearLabel;

  /// No description provided for @dobErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid date of birth.'**
  String get dobErrorInvalid;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @januaryShort.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get januaryShort;

  /// No description provided for @februaryShort.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get februaryShort;

  /// No description provided for @marchShort.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get marchShort;

  /// No description provided for @aprilShort.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get aprilShort;

  /// No description provided for @mayShort.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayShort;

  /// No description provided for @juneShort.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get juneShort;

  /// No description provided for @julyShort.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get julyShort;

  /// No description provided for @augustShort.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get augustShort;

  /// No description provided for @septemberShort.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get septemberShort;

  /// No description provided for @octoberShort.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get octoberShort;

  /// No description provided for @novemberShort.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get novemberShort;

  /// No description provided for @decemberShort.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get decemberShort;

  /// No description provided for @nameGenderTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself'**
  String get nameGenderTitle;

  /// No description provided for @nameGenderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'So your guide can get to know the real you'**
  String get nameGenderSubtitle;

  /// No description provided for @nameGenderFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get nameGenderFullNameLabel;

  /// No description provided for @nameGenderFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get nameGenderFullNameHint;

  /// No description provided for @nameGenderGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get nameGenderGenderLabel;

  /// No description provided for @nameGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get nameGenderMale;

  /// No description provided for @nameGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get nameGenderFemale;

  /// No description provided for @nameGenderPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get nameGenderPreferNotToSay;

  /// No description provided for @supportAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'What area would you like support with?'**
  String get supportAreaTitle;

  /// No description provided for @supportAreaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll only show guides who specialise in this'**
  String get supportAreaSubtitle;

  /// No description provided for @supportAreaIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual Growth'**
  String get supportAreaIndividual;

  /// No description provided for @supportAreaFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get supportAreaFamily;

  /// No description provided for @supportAreaCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get supportAreaCareer;

  /// No description provided for @supportAreaEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get supportAreaEducation;

  /// No description provided for @supportAreaPersonalDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Personal Development'**
  String get supportAreaPersonalDevelopment;

  /// No description provided for @availableDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Which days are you available?'**
  String get availableDaysTitle;

  /// No description provided for @availableDaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'So we only show guides free when you are'**
  String get availableDaysSubtitle;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySunday;

  /// No description provided for @meetingTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'What time works best for you?'**
  String get meetingTimeTitle;

  /// No description provided for @meetingTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guides with matching slots will be highlighted'**
  String get meetingTimeSubtitle;

  /// No description provided for @meetingTimeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get meetingTimeMorning;

  /// No description provided for @meetingTimeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get meetingTimeAfternoon;

  /// No description provided for @meetingTimeEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get meetingTimeEvening;

  /// No description provided for @meetingTimeFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get meetingTimeFlexible;

  /// No description provided for @meetingTimeMorningRange.
  ///
  /// In en, this message translates to:
  /// **'08:00 - 12:00'**
  String get meetingTimeMorningRange;

  /// No description provided for @meetingTimeAfternoonRange.
  ///
  /// In en, this message translates to:
  /// **'12:00 - 16:00'**
  String get meetingTimeAfternoonRange;

  /// No description provided for @meetingTimeEveningRange.
  ///
  /// In en, this message translates to:
  /// **'16:00 - 21:00'**
  String get meetingTimeEveningRange;

  /// No description provided for @meetingTimeFlexibleRange.
  ///
  /// In en, this message translates to:
  /// **''**
  String get meetingTimeFlexibleRange;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Account has been created'**
  String get successTitle;

  /// No description provided for @successSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully created. Enjoy the app.'**
  String get successSubtitle;

  /// No description provided for @topicFeelingGood.
  ///
  /// In en, this message translates to:
  /// **'Feeling Good'**
  String get topicFeelingGood;

  /// No description provided for @appointmentDescription.
  ///
  /// In en, this message translates to:
  /// **'You have a meeting with {name} about {topic}.'**
  String appointmentDescription(String name, String topic);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hi;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @howAreYouFeelIngToday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howAreYouFeelIngToday;

  /// No description provided for @getStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start'**
  String get getStart;

  /// No description provided for @onboardingQuote1.
  ///
  /// In en, this message translates to:
  /// **'Your only limits are the ones you set yourself.'**
  String get onboardingQuote1;

  /// No description provided for @onboardingQuote2.
  ///
  /// In en, this message translates to:
  /// **'Take a deep breath and start your journey.'**
  String get onboardingQuote2;

  /// No description provided for @onboardingQuote3.
  ///
  /// In en, this message translates to:
  /// **'The quieter you become, the more you are able to hear.'**
  String get onboardingQuote3;

  /// No description provided for @someoneWantsToTalkToYou.
  ///
  /// In en, this message translates to:
  /// **'Someone wants to talk to you.'**
  String get someoneWantsToTalkToYou;

  /// No description provided for @startTalking.
  ///
  /// In en, this message translates to:
  /// **'Start Talking'**
  String get startTalking;

  /// No description provided for @moodTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get moodTerrible;

  /// No description provided for @moodBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodBad;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get moodStressed;

  /// No description provided for @moodTrackerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A small check-in goes a long way'**
  String get moodTrackerSubtitle;

  /// No description provided for @moodDescCalm.
  ///
  /// In en, this message translates to:
  /// **'This peace in your mind is your greatest strength. Enjoy this moment and stay balanced.'**
  String get moodDescCalm;

  /// No description provided for @moodDescHappy.
  ///
  /// In en, this message translates to:
  /// **'Your positive energy is contagious! Keep spreading joy and embracing this wonderful feeling.'**
  String get moodDescHappy;

  /// No description provided for @moodDescNeutral.
  ///
  /// In en, this message translates to:
  /// **'A steady state of mind is perfectly fine. Take a moment to check in with yourself.'**
  String get moodDescNeutral;

  /// No description provided for @moodDescTired.
  ///
  /// In en, this message translates to:
  /// **'Your body is telling you to rest. Take a break and recharge — you deserve it.'**
  String get moodDescTired;

  /// No description provided for @moodDescStressed.
  ///
  /// In en, this message translates to:
  /// **'Take a deep breath. Remember, it\'s okay to slow down and take things one step at a time.'**
  String get moodDescStressed;

  /// No description provided for @todaysSessions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sessions'**
  String get todaysSessions;

  /// No description provided for @makeAnAppointment.
  ///
  /// In en, this message translates to:
  /// **'Make an Appointment'**
  String get makeAnAppointment;

  /// No description provided for @timeToTrackMood.
  ///
  /// In en, this message translates to:
  /// **'It\'s time to track your mood'**
  String get timeToTrackMood;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @timeRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Time remaining until the next meeting begins.'**
  String get timeRemainingTitle;

  /// No description provided for @upcomingMeetingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Meeting'**
  String get upcomingMeetingTitle;

  /// No description provided for @noUpcomingMeetings.
  ///
  /// In en, this message translates to:
  /// **'You have no upcoming meetings.'**
  String get noUpcomingMeetings;

  /// No description provided for @takeTheTestNow.
  ///
  /// In en, this message translates to:
  /// **'Take the Test Now'**
  String get takeTheTestNow;

  /// No description provided for @testDescription.
  ///
  /// In en, this message translates to:
  /// **'Assess your mental state and learn more about yourself.'**
  String get testDescription;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get premiumPlan;

  /// No description provided for @premiumDescription.
  ///
  /// In en, this message translates to:
  /// **'Unlock your AI chatbot & get all premium features.'**
  String get premiumDescription;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @areYouStressed.
  ///
  /// In en, this message translates to:
  /// **'Are You Stressed?'**
  String get areYouStressed;

  /// No description provided for @areYouAnxious.
  ///
  /// In en, this message translates to:
  /// **'Are You Anxious'**
  String get areYouAnxious;

  /// Shows the number of questions for adult mode.
  ///
  /// In en, this message translates to:
  /// **'{questionNumber} Questions for Adults'**
  String questionsForAdults(int questionNumber);

  /// No description provided for @statusAssessmentTest.
  ///
  /// In en, this message translates to:
  /// **'Status Assessment Test'**
  String get statusAssessmentTest;

  /// No description provided for @stressScaleTest.
  ///
  /// In en, this message translates to:
  /// **'Stress Scale Test'**
  String get stressScaleTest;

  /// No description provided for @anxietyScaleTest.
  ///
  /// In en, this message translates to:
  /// **'Anxiety Scale Test'**
  String get anxietyScaleTest;

  /// Primary button label to start the mental test
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @testRule1.
  ///
  /// In en, this message translates to:
  /// **'Evaluate your **last week**.'**
  String get testRule1;

  /// No description provided for @testRule2.
  ///
  /// In en, this message translates to:
  /// **'It is recommended that you take the test **once a week**.'**
  String get testRule2;

  /// No description provided for @testRule3.
  ///
  /// In en, this message translates to:
  /// **'If you stop the test halfway through, **you can continue from where you left off.**'**
  String get testRule3;

  /// No description provided for @testDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'The results of this test provide insight into individual mental health but do not replace a diagnosis or recommendation as discussed with a mental health professional.'**
  String get testDisclaimer;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @sometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes and occasionally'**
  String get sometimes;

  /// No description provided for @often.
  ///
  /// In en, this message translates to:
  /// **'Quite often'**
  String get often;

  /// No description provided for @always.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get always;

  /// No description provided for @stressQ1.
  ///
  /// In en, this message translates to:
  /// **'I had trouble relaxing and letting go.'**
  String get stressQ1;

  /// No description provided for @stressQ2.
  ///
  /// In en, this message translates to:
  /// **'I tend to overreact to events.'**
  String get stressQ2;

  /// No description provided for @stressQ3.
  ///
  /// In en, this message translates to:
  /// **'I felt nervous or anxious.'**
  String get stressQ3;

  /// No description provided for @stressQ4.
  ///
  /// In en, this message translates to:
  /// **'I had difficulty managing my things and tasks.'**
  String get stressQ4;

  /// No description provided for @stressQ5.
  ///
  /// In en, this message translates to:
  /// **'I had difficulty and occasionally ignored my feelings.'**
  String get stressQ5;

  /// No description provided for @stressQ6.
  ///
  /// In en, this message translates to:
  /// **'I had trouble falling asleep or staying asleep.'**
  String get stressQ6;

  /// No description provided for @stressQ7.
  ///
  /// In en, this message translates to:
  /// **'I felt overwhelmed by responsibilities.'**
  String get stressQ7;

  /// No description provided for @stressQ8.
  ///
  /// In en, this message translates to:
  /// **'I felt scared without good reason.'**
  String get stressQ8;

  /// No description provided for @stressQ9.
  ///
  /// In en, this message translates to:
  /// **'I experienced shortness of breath even without physical activity.'**
  String get stressQ9;

  /// No description provided for @stressQ10.
  ///
  /// In en, this message translates to:
  /// **'I had a sense of doom or panic.'**
  String get stressQ10;

  /// No description provided for @stressQ11.
  ///
  /// In en, this message translates to:
  /// **'I struggled to concentrate on work or daily activities.'**
  String get stressQ11;

  /// No description provided for @stressQ12.
  ///
  /// In en, this message translates to:
  /// **'I felt isolated or disconnected from others.'**
  String get stressQ12;

  /// No description provided for @stressQ13.
  ///
  /// In en, this message translates to:
  /// **'My heart raced or I felt palpitations.'**
  String get stressQ13;

  /// No description provided for @stressQ14.
  ///
  /// In en, this message translates to:
  /// **'I felt irritable or had difficulty controlling my temper.'**
  String get stressQ14;

  /// No description provided for @stressQ15.
  ///
  /// In en, this message translates to:
  /// **'I experienced physical tension in my neck, shoulders, or jaw.'**
  String get stressQ15;

  /// No description provided for @stressQ16.
  ///
  /// In en, this message translates to:
  /// **'I had negative thoughts about myself.'**
  String get stressQ16;

  /// No description provided for @stressQ17.
  ///
  /// In en, this message translates to:
  /// **'I felt overwhelmed by everyday situations.'**
  String get stressQ17;

  /// No description provided for @stressQ18.
  ///
  /// In en, this message translates to:
  /// **'I had difficulty making decisions.'**
  String get stressQ18;

  /// No description provided for @stressQ19.
  ///
  /// In en, this message translates to:
  /// **'I felt exhausted even after rest.'**
  String get stressQ19;

  /// No description provided for @stressQ20.
  ///
  /// In en, this message translates to:
  /// **'I experienced changes in appetite.'**
  String get stressQ20;

  /// No description provided for @stressQ21.
  ///
  /// In en, this message translates to:
  /// **'I had difficulty maintaining relationships.'**
  String get stressQ21;

  /// No description provided for @stressQ22.
  ///
  /// In en, this message translates to:
  /// **'I felt trapped or helpless.'**
  String get stressQ22;

  /// No description provided for @stressQ23.
  ///
  /// In en, this message translates to:
  /// **'I had frequent headaches or body aches.'**
  String get stressQ23;

  /// No description provided for @stressQ24.
  ///
  /// In en, this message translates to:
  /// **'I struggled to enjoy activities I usually like.'**
  String get stressQ24;

  /// No description provided for @stressQ25.
  ///
  /// In en, this message translates to:
  /// **'I felt time slipping away from me or losing track of it.'**
  String get stressQ25;

  /// No description provided for @stressScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Stress scale test'**
  String get stressScaleTitle;

  /// No description provided for @yourStressLevelPrefix.
  ///
  /// In en, this message translates to:
  /// **'Your stress level: '**
  String get yourStressLevelPrefix;

  /// No description provided for @stressLevelLow.
  ///
  /// In en, this message translates to:
  /// **'Low stress'**
  String get stressLevelLow;

  /// No description provided for @stressLevelLowDescription.
  ///
  /// In en, this message translates to:
  /// **'Your current stress level is low. You manage daily challenges well.'**
  String get stressLevelLowDescription;

  /// No description provided for @stressLevelModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate stress'**
  String get stressLevelModerate;

  /// No description provided for @stressLevelModerateDescription.
  ///
  /// In en, this message translates to:
  /// **'Your stress level is moderate. It is manageable, but requires attention.'**
  String get stressLevelModerateDescription;

  /// No description provided for @stressLevelHigh.
  ///
  /// In en, this message translates to:
  /// **'High stress'**
  String get stressLevelHigh;

  /// No description provided for @stressLevelHighDescription.
  ///
  /// In en, this message translates to:
  /// **'Your stress level is high. You need to slow down and listen to your body.'**
  String get stressLevelHighDescription;

  /// No description provided for @stressAnalysisIntro.
  ///
  /// In en, this message translates to:
  /// **'Thank you for completing the test. Your results indicate that there are some factors in your daily life that may be challenging you and causing fatigue.'**
  String get stressAnalysisIntro;

  /// No description provided for @stressAnalysisP1Part1.
  ///
  /// In en, this message translates to:
  /// **'While this level isn\'t a '**
  String get stressAnalysisP1Part1;

  /// No description provided for @stressAnalysisP1Bold1.
  ///
  /// In en, this message translates to:
  /// **'\'high alert\', '**
  String get stressAnalysisP1Bold1;

  /// No description provided for @stressAnalysisP1Part2.
  ///
  /// In en, this message translates to:
  /// **'it\'s your body and mind\'s way of saying, '**
  String get stressAnalysisP1Part2;

  /// No description provided for @stressAnalysisP1Bold2.
  ///
  /// In en, this message translates to:
  /// **'\'I need you to slow down and listen to me.\''**
  String get stressAnalysisP1Bold2;

  /// No description provided for @stressAnalysisP2Part1.
  ///
  /// In en, this message translates to:
  /// **'Moderate stress is very common in today\'s fast-paced world, and it is '**
  String get stressAnalysisP2Part1;

  /// No description provided for @stressAnalysisP2Bold1.
  ///
  /// In en, this message translates to:
  /// **'manageable. '**
  String get stressAnalysisP2Bold1;

  /// No description provided for @stressAnalysisP2Part2.
  ///
  /// In en, this message translates to:
  /// **'You can see this result as an opportunity to '**
  String get stressAnalysisP2Part2;

  /// No description provided for @stressAnalysisP2Bold2.
  ///
  /// In en, this message translates to:
  /// **'manage your stress before it leads to burnout.'**
  String get stressAnalysisP2Bold2;

  /// No description provided for @stressAnalysisRemember.
  ///
  /// In en, this message translates to:
  /// **'Remember, this test is an awareness tool, not a medical diagnosis. Taking time for yourself is the first step toward feeling better.'**
  String get stressAnalysisRemember;

  /// No description provided for @testResult.
  ///
  /// In en, this message translates to:
  /// **'Test result'**
  String get testResult;

  /// No description provided for @mentalTest.
  ///
  /// In en, this message translates to:
  /// **'Mental Test'**
  String get mentalTest;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @specialistsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentors'**
  String get specialistsScreenTitle;

  /// No description provided for @specialistAuraName.
  ///
  /// In en, this message translates to:
  /// **'Aura'**
  String get specialistAuraName;

  /// No description provided for @specialistAuraTitle.
  ///
  /// In en, this message translates to:
  /// **'Individual Mentorship'**
  String get specialistAuraTitle;

  /// No description provided for @specialistAuraDescription.
  ///
  /// In en, this message translates to:
  /// **'Personalized guidance for your self-growth journey.'**
  String get specialistAuraDescription;

  /// No description provided for @specialistZenName.
  ///
  /// In en, this message translates to:
  /// **'Zen'**
  String get specialistZenName;

  /// No description provided for @specialistZenTitle.
  ///
  /// In en, this message translates to:
  /// **'Relationship Advisor'**
  String get specialistZenTitle;

  /// No description provided for @specialistZenDescription.
  ///
  /// In en, this message translates to:
  /// **'Helping you build healthy and balanced relationships.'**
  String get specialistZenDescription;

  /// No description provided for @specialistElaraName.
  ///
  /// In en, this message translates to:
  /// **'Elara'**
  String get specialistElaraName;

  /// No description provided for @specialistElaraTitle.
  ///
  /// In en, this message translates to:
  /// **'Development Guide'**
  String get specialistElaraTitle;

  /// No description provided for @specialistElaraDescription.
  ///
  /// In en, this message translates to:
  /// **'Supports your personal growth and long-term goals.'**
  String get specialistElaraDescription;

  /// No description provided for @specialistOrionName.
  ///
  /// In en, this message translates to:
  /// **'Orion'**
  String get specialistOrionName;

  /// No description provided for @specialistOrionTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Behavior Guide'**
  String get specialistOrionTitle;

  /// No description provided for @specialistOrionDescription.
  ///
  /// In en, this message translates to:
  /// **'Improving your communication skills and social confidence.'**
  String get specialistOrionDescription;

  /// No description provided for @specialistCyraName.
  ///
  /// In en, this message translates to:
  /// **'Cyra'**
  String get specialistCyraName;

  /// No description provided for @specialistCyraTitle.
  ///
  /// In en, this message translates to:
  /// **'Academic Mentor'**
  String get specialistCyraTitle;

  /// No description provided for @specialistCyraDescription.
  ///
  /// In en, this message translates to:
  /// **'Helps with focus, study habits and academic planning.'**
  String get specialistCyraDescription;

  /// No description provided for @chatScreenGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String chatScreenGreeting(String name);

  /// No description provided for @chatScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatScreenTitle;

  /// No description provided for @chatLastFromYouPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: '**
  String get chatLastFromYouPrefix;

  /// No description provided for @chatDeleteToast.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name} has been deleted.'**
  String chatDeleteToast(String name);

  /// No description provided for @askMentor.
  ///
  /// In en, this message translates to:
  /// **'Ask, {name}'**
  String askMentor(String name);

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @enterYourAge.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get enterYourAge;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get profileSaved;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @deleteAccountWhyLeaving.
  ///
  /// In en, this message translates to:
  /// **'We don\'t want you to go, but we understand.'**
  String get deleteAccountWhyLeaving;

  /// No description provided for @deleteAccountImproveQuestion.
  ///
  /// In en, this message translates to:
  /// **'To help us improve the MindCoach experience, could you tell us why you\'re leaving?'**
  String get deleteAccountImproveQuestion;

  /// No description provided for @deleteReasonNotRealistic.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t find the AI characters realistic.'**
  String get deleteReasonNotRealistic;

  /// No description provided for @deleteReasonTechnicalIssues.
  ///
  /// In en, this message translates to:
  /// **'I\'m experiencing technical issues with video chats.'**
  String get deleteReasonTechnicalIssues;

  /// No description provided for @deleteReasonPrice.
  ///
  /// In en, this message translates to:
  /// **'The subscription prices are above my expectations.'**
  String get deleteReasonPrice;

  /// No description provided for @deleteReasonNoCharacters.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t find the type of characters I was looking for.'**
  String get deleteReasonNoCharacters;

  /// No description provided for @deleteReasonShortTry.
  ///
  /// In en, this message translates to:
  /// **'I just wanted to try it for a short while.'**
  String get deleteReasonShortTry;

  /// No description provided for @deleteReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get deleteReasonOther;

  /// No description provided for @messageOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get messageOptionalLabel;

  /// No description provided for @specialOffer.
  ///
  /// In en, this message translates to:
  /// **'Special offer'**
  String get specialOffer;

  /// No description provided for @specialOfferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Before you go, take a look at the offer we\'ve prepared for you.'**
  String get specialOfferSubtitle;

  /// No description provided for @switchTo1MonthPlan.
  ///
  /// In en, this message translates to:
  /// **'Switch to 1-Month Plan'**
  String get switchTo1MonthPlan;

  /// No description provided for @monthlyPlanPrice.
  ///
  /// In en, this message translates to:
  /// **'\$79/month, cancel anytime'**
  String get monthlyPlanPrice;

  /// No description provided for @noLongTermCommitment.
  ///
  /// In en, this message translates to:
  /// **'No long-term commitment. Stay connected with our community on a month-to-month basis.'**
  String get noLongTermCommitment;

  /// No description provided for @whatYouKeep.
  ///
  /// In en, this message translates to:
  /// **'What you\'ll keep:'**
  String get whatYouKeep;

  /// No description provided for @featureAllCharacters.
  ///
  /// In en, this message translates to:
  /// **'Access all characters'**
  String get featureAllCharacters;

  /// No description provided for @featureUnlimitedVideoCalls.
  ///
  /// In en, this message translates to:
  /// **'Unlimited video calls'**
  String get featureUnlimitedVideoCalls;

  /// No description provided for @featureUnlimitedCharacterEditing.
  ///
  /// In en, this message translates to:
  /// **'Unlimited character editing'**
  String get featureUnlimitedCharacterEditing;

  /// No description provided for @switchToMonthlyPlan.
  ///
  /// In en, this message translates to:
  /// **'Switch to Monthly Plan'**
  String get switchToMonthlyPlan;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @finalOfferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We really don\'t want to see you go. Here\'s what you\'ll lose:'**
  String get finalOfferSubtitle;

  /// No description provided for @featureUnlimitedCharacterAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited character access'**
  String get featureUnlimitedCharacterAccess;

  /// No description provided for @featureUnlimitedVideoCallAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited video call access'**
  String get featureUnlimitedVideoCallAccess;

  /// No description provided for @featureUnlimitedCharacterEditingAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlimited character editing access'**
  String get featureUnlimitedCharacterEditingAccess;

  /// No description provided for @stayAnd60Off.
  ///
  /// In en, this message translates to:
  /// **'Stay and get 50% off for 1 month'**
  String get stayAnd60Off;

  /// No description provided for @bestOfferPrice.
  ///
  /// In en, this message translates to:
  /// **'Our best offer ever. Just \$1.49/month'**
  String get bestOfferPrice;

  /// No description provided for @accept60OffAndStay.
  ///
  /// In en, this message translates to:
  /// **'Accept 50% Off & Stay'**
  String get accept60OffAndStay;

  /// No description provided for @sadToSeeYouGo.
  ///
  /// In en, this message translates to:
  /// **'We\'re sad to see you go'**
  String get sadToSeeYouGo;

  /// No description provided for @membershipCancelledInfo.
  ///
  /// In en, this message translates to:
  /// **'Your membership has been cancelled. You\'ll have access until the end of your current billing period.'**
  String get membershipCancelledInfo;

  /// No description provided for @changeYourMind.
  ///
  /// In en, this message translates to:
  /// **'Change your mind?'**
  String get changeYourMind;

  /// No description provided for @reactivateInfo.
  ///
  /// In en, this message translates to:
  /// **'You can reactivate your membership anytime to keep your benefits.'**
  String get reactivateInfo;

  /// No description provided for @waitReactivate.
  ///
  /// In en, this message translates to:
  /// **'Wait, I want to reactivate →'**
  String get waitReactivate;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @shareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share with Friends'**
  String get shareWithFriends;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get appointments;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the profile?'**
  String get areYouSureDelete;

  /// No description provided for @deleteNotificationConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Notification'**
  String get deleteNotificationConfirmTitle;

  /// No description provided for @deleteNotificationConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get deleteNotificationConfirmMessage;

  /// No description provided for @deleteAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAllNotifications;

  /// No description provided for @deleteAllNotificationsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Notifications'**
  String get deleteAllNotificationsConfirmTitle;

  /// No description provided for @deleteAllNotificationsConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications?'**
  String get deleteAllNotificationsConfirmMessage;

  /// No description provided for @allNotificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted successfully'**
  String get allNotificationsDeleted;

  /// No description provided for @noNotificationsToDelete.
  ///
  /// In en, this message translates to:
  /// **'No notifications to delete'**
  String get noNotificationsToDelete;

  /// No description provided for @errorDeletingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error deleting notifications'**
  String get errorDeletingNotifications;

  /// No description provided for @invitePeople.
  ///
  /// In en, this message translates to:
  /// **'Invite People'**
  String get invitePeople;

  /// No description provided for @copyLinkInviteFriend.
  ///
  /// In en, this message translates to:
  /// **'Copy the link to invite your friends'**
  String get copyLinkInviteFriend;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get relativeToday;

  /// No description provided for @relativeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get relativeTomorrow;

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get relativeYesterday;

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String relativeDaysAgo(int count);

  /// No description provided for @relativeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String relativeWeeksAgo(int count);

  /// No description provided for @numberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Question {currentQuestion} of {totalQuestion}'**
  String numberOfQuestions(int currentQuestion, int totalQuestion);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @enterFullNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name.'**
  String get enterFullNamePrompt;

  /// No description provided for @meetingStarted.
  ///
  /// In en, this message translates to:
  /// **'Meeting Started'**
  String get meetingStarted;

  /// No description provided for @selectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected Date'**
  String get selectedDate;

  /// No description provided for @newChatStarted.
  ///
  /// In en, this message translates to:
  /// **'New Chat Started'**
  String get newChatStarted;

  /// No description provided for @startNewMeeting.
  ///
  /// In en, this message translates to:
  /// **'Start a new meeting'**
  String get startNewMeeting;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @jobThoughtAndHabitGuide.
  ///
  /// In en, this message translates to:
  /// **'Thought and Habit Guide'**
  String get jobThoughtAndHabitGuide;

  /// No description provided for @jobFamilyAssistant.
  ///
  /// In en, this message translates to:
  /// **'Family Guide'**
  String get jobFamilyAssistant;

  /// No description provided for @jobAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult Guide'**
  String get jobAdult;

  /// No description provided for @jobChild.
  ///
  /// In en, this message translates to:
  /// **'Child Guide'**
  String get jobChild;

  /// No description provided for @jobTeenage.
  ///
  /// In en, this message translates to:
  /// **'Teen Guide'**
  String get jobTeenage;

  /// No description provided for @jobPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Guide'**
  String get jobPersonal;

  /// No description provided for @jobExamAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Exam Anxiety Guide'**
  String get jobExamAnxiety;

  /// No description provided for @jobEmotionalBalance.
  ///
  /// In en, this message translates to:
  /// **'Emotional Balance Guide'**
  String get jobEmotionalBalance;

  /// No description provided for @jobDifficultExperiences.
  ///
  /// In en, this message translates to:
  /// **'Difficult Experiences Guide'**
  String get jobDifficultExperiences;

  /// No description provided for @jobResilienceEmpowerment.
  ///
  /// In en, this message translates to:
  /// **'Resilience & Empowerment Guide'**
  String get jobResilienceEmpowerment;

  /// No description provided for @noSpecialistsFound.
  ///
  /// In en, this message translates to:
  /// **'No specialists found'**
  String get noSpecialistsFound;

  /// No description provided for @featureFamilyConflicts.
  ///
  /// In en, this message translates to:
  /// **'Family Conflicts'**
  String get featureFamilyConflicts;

  /// No description provided for @featureParenting.
  ///
  /// In en, this message translates to:
  /// **'Parenting'**
  String get featureParenting;

  /// No description provided for @featureCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get featureCommunication;

  /// No description provided for @featureBoundaries.
  ///
  /// In en, this message translates to:
  /// **'Boundaries'**
  String get featureBoundaries;

  /// No description provided for @featureRelationshipRepair.
  ///
  /// In en, this message translates to:
  /// **'Relationship Repair'**
  String get featureRelationshipRepair;

  /// No description provided for @featureDivorceSupport.
  ///
  /// In en, this message translates to:
  /// **'Divorce Support'**
  String get featureDivorceSupport;

  /// No description provided for @featureChildBehavior.
  ///
  /// In en, this message translates to:
  /// **'Child Behavior'**
  String get featureChildBehavior;

  /// No description provided for @featureFamilyHarmony.
  ///
  /// In en, this message translates to:
  /// **'Family Harmony'**
  String get featureFamilyHarmony;

  /// No description provided for @featureStressManagement.
  ///
  /// In en, this message translates to:
  /// **'Stress Management'**
  String get featureStressManagement;

  /// No description provided for @featureSelfConfidence.
  ///
  /// In en, this message translates to:
  /// **'Self-Confidence'**
  String get featureSelfConfidence;

  /// No description provided for @featureLifeBalance.
  ///
  /// In en, this message translates to:
  /// **'Life Balance'**
  String get featureLifeBalance;

  /// No description provided for @featureCareerGuidance.
  ///
  /// In en, this message translates to:
  /// **'Career Guidance'**
  String get featureCareerGuidance;

  /// No description provided for @featureEmotionalRegulation.
  ///
  /// In en, this message translates to:
  /// **'Emotional Regulation'**
  String get featureEmotionalRegulation;

  /// No description provided for @featureDecisionMaking.
  ///
  /// In en, this message translates to:
  /// **'Decision Making'**
  String get featureDecisionMaking;

  /// No description provided for @featureMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get featureMotivation;

  /// No description provided for @featurePersonalGrowth.
  ///
  /// In en, this message translates to:
  /// **'Personal Growth'**
  String get featurePersonalGrowth;

  /// No description provided for @featureEmotionalAwareness.
  ///
  /// In en, this message translates to:
  /// **'Emotional Awareness'**
  String get featureEmotionalAwareness;

  /// No description provided for @featureSocialSkills.
  ///
  /// In en, this message translates to:
  /// **'Social Skills'**
  String get featureSocialSkills;

  /// No description provided for @featureSchoolAdaptation.
  ///
  /// In en, this message translates to:
  /// **'School Adaptation'**
  String get featureSchoolAdaptation;

  /// No description provided for @featureSelfExpression.
  ///
  /// In en, this message translates to:
  /// **'Self-Expression'**
  String get featureSelfExpression;

  /// No description provided for @featureFearManagement.
  ///
  /// In en, this message translates to:
  /// **'Fear Management'**
  String get featureFearManagement;

  /// No description provided for @featureFriendshipBuilding.
  ///
  /// In en, this message translates to:
  /// **'Friendship Building'**
  String get featureFriendshipBuilding;

  /// No description provided for @featureFocusAttention.
  ///
  /// In en, this message translates to:
  /// **'Focus & Attention'**
  String get featureFocusAttention;

  /// No description provided for @featureBehavioralSupport.
  ///
  /// In en, this message translates to:
  /// **'Behavioral Support'**
  String get featureBehavioralSupport;

  /// No description provided for @featureIdentityDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Identity Development'**
  String get featureIdentityDevelopment;

  /// No description provided for @featurePeerPressure.
  ///
  /// In en, this message translates to:
  /// **'Peer Pressure'**
  String get featurePeerPressure;

  /// No description provided for @featureAcademicStress.
  ///
  /// In en, this message translates to:
  /// **'Academic Stress'**
  String get featureAcademicStress;

  /// No description provided for @featureSelfEsteem.
  ///
  /// In en, this message translates to:
  /// **'Self-Esteem'**
  String get featureSelfEsteem;

  /// No description provided for @featureDigitalWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Digital Wellbeing'**
  String get featureDigitalWellbeing;

  /// No description provided for @featureAngerManagement.
  ///
  /// In en, this message translates to:
  /// **'Anger Management'**
  String get featureAngerManagement;

  /// No description provided for @featureFuturePlanning.
  ///
  /// In en, this message translates to:
  /// **'Future Planning'**
  String get featureFuturePlanning;

  /// No description provided for @featureParentCommunication.
  ///
  /// In en, this message translates to:
  /// **'Parent Communication'**
  String get featureParentCommunication;

  /// No description provided for @featureLoneliness.
  ///
  /// In en, this message translates to:
  /// **'Loneliness'**
  String get featureLoneliness;

  /// No description provided for @featureAnxietySupport.
  ///
  /// In en, this message translates to:
  /// **'Anxiety Support'**
  String get featureAnxietySupport;

  /// No description provided for @featureGriefProcessing.
  ///
  /// In en, this message translates to:
  /// **'Grief Processing'**
  String get featureGriefProcessing;

  /// No description provided for @featureMindfulness.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness'**
  String get featureMindfulness;

  /// No description provided for @featureSleepImprovement.
  ///
  /// In en, this message translates to:
  /// **'Sleep Improvement'**
  String get featureSleepImprovement;

  /// No description provided for @featureOverthinking.
  ///
  /// In en, this message translates to:
  /// **'Overthinking'**
  String get featureOverthinking;

  /// No description provided for @featureSelfDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Self-Discovery'**
  String get featureSelfDiscovery;

  /// No description provided for @featureEmotionalHealing.
  ///
  /// In en, this message translates to:
  /// **'Emotional Healing'**
  String get featureEmotionalHealing;

  /// No description provided for @featureTestAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Test Anxiety'**
  String get featureTestAnxiety;

  /// No description provided for @featureStudyTechniques.
  ///
  /// In en, this message translates to:
  /// **'Study Techniques'**
  String get featureStudyTechniques;

  /// No description provided for @featureTimeManagement.
  ///
  /// In en, this message translates to:
  /// **'Time Management'**
  String get featureTimeManagement;

  /// No description provided for @featurePerformancePressure.
  ///
  /// In en, this message translates to:
  /// **'Performance Pressure'**
  String get featurePerformancePressure;

  /// No description provided for @featureConcentration.
  ///
  /// In en, this message translates to:
  /// **'Concentration'**
  String get featureConcentration;

  /// No description provided for @featureRelaxationMethods.
  ///
  /// In en, this message translates to:
  /// **'Relaxation Methods'**
  String get featureRelaxationMethods;

  /// No description provided for @featureExamPreparation.
  ///
  /// In en, this message translates to:
  /// **'Exam Preparation'**
  String get featureExamPreparation;

  /// No description provided for @featureConfidenceBuilding.
  ///
  /// In en, this message translates to:
  /// **'Confidence Building'**
  String get featureConfidenceBuilding;

  /// No description provided for @explanationFamilyAssistant.
  ///
  /// In en, this message translates to:
  /// **'A family guide who helps you navigate through family dynamics, resolve conflicts, strengthen parent-child bonds, and build a more harmonious home environment.'**
  String get explanationFamilyAssistant;

  /// No description provided for @explanationAdult.
  ///
  /// In en, this message translates to:
  /// **'A personal development guide for adults who want to take control of their lives — from managing daily stress and building self-confidence to finding life balance.'**
  String get explanationAdult;

  /// No description provided for @explanationChild.
  ///
  /// In en, this message translates to:
  /// **'A gentle and supportive guide trained to help children express their emotions, build social skills, and adapt to school life using age-appropriate techniques.'**
  String get explanationChild;

  /// No description provided for @explanationTeenage.
  ///
  /// In en, this message translates to:
  /// **'A guide who understands the teenage experience — from identity exploration and peer pressure to academic stress and digital wellbeing.'**
  String get explanationTeenage;

  /// No description provided for @explanationPersonal.
  ///
  /// In en, this message translates to:
  /// **'A compassionate personal guide focused on inner wellbeing. Guides you through mindfulness, emotional healing, and self-discovery to find peace and clarity.'**
  String get explanationPersonal;

  /// No description provided for @explanationExamAnxiety.
  ///
  /// In en, this message translates to:
  /// **'A specialized guide who helps students conquer exam anxiety through proven study techniques, relaxation methods, and confidence-building exercises.'**
  String get explanationExamAnxiety;

  /// No description provided for @explanationFamilyAssistant1.
  ///
  /// In en, this message translates to:
  /// **'A dedicated family guide specializing in resolving deep-rooted family conflicts and rebuilding strained relationships. Helps families navigate difficult transitions like divorce while guiding children through behavioral changes.'**
  String get explanationFamilyAssistant1;

  /// No description provided for @explanationFamilyAssistant2.
  ///
  /// In en, this message translates to:
  /// **'A warm and empathetic family guide focused on strengthening the bonds that matter most. Helps families heal after difficult periods while supporting children\'s emotional and behavioral development.'**
  String get explanationFamilyAssistant2;

  /// No description provided for @explanationAdult1.
  ///
  /// In en, this message translates to:
  /// **'A results-driven guide for adults seeking meaningful change. Focuses on stress management, life balance, and career guidance through practical, goal-oriented strategies.'**
  String get explanationAdult1;

  /// No description provided for @explanationAdult2.
  ///
  /// In en, this message translates to:
  /// **'A holistic development guide empowering adults to reach their full potential — from building self-confidence and managing stress to finding career direction and daily motivation.'**
  String get explanationAdult2;

  /// No description provided for @explanationTeenage1.
  ///
  /// In en, this message translates to:
  /// **'A guide who deeply understands adolescence. Helps teens strengthen self-esteem, control anger, plan their future, and communicate openly with their parents.'**
  String get explanationTeenage1;

  /// No description provided for @explanationTeenage2.
  ///
  /// In en, this message translates to:
  /// **'An empathetic guide through the turbulent teenage years. Empowers teens to develop resilience, manage anger constructively, and maintain healthy parent-teen relationships.'**
  String get explanationTeenage2;

  /// No description provided for @explanationChild1.
  ///
  /// In en, this message translates to:
  /// **'A nurturing guide for children\'s most formative years. Helps kids develop emotional awareness, build social skills, adapt to school, overcome fears, and improve focus.'**
  String get explanationChild1;

  /// No description provided for @explanationChild2.
  ///
  /// In en, this message translates to:
  /// **'A caring and patient guide dedicated to helping children thrive — creating a safe environment where kids learn to express feelings, build friendships, and grow confidently.'**
  String get explanationChild2;

  /// No description provided for @explanationPersonal1.
  ///
  /// In en, this message translates to:
  /// **'A deeply compassionate guide focused on emotional wellbeing. Guides you through mindfulness, emotional healing, and self-discovery to break free from overthinking.'**
  String get explanationPersonal1;

  /// No description provided for @explanationPersonal2.
  ///
  /// In en, this message translates to:
  /// **'A supportive personal guide who helps you reconnect with yourself. Specializes in anxiety management, mindfulness, and sleep improvement toward genuine inner calm.'**
  String get explanationPersonal2;

  /// No description provided for @explanationExamAnxiety1.
  ///
  /// In en, this message translates to:
  /// **'A focused guide who transforms exam stress into confident performance. Equips students with time management, relaxation methods, and confidence-building strategies.'**
  String get explanationExamAnxiety1;

  /// No description provided for @explanationExamAnxiety2.
  ///
  /// In en, this message translates to:
  /// **'A specialized academic guide dedicated to helping students overcome test anxiety and study smarter through proven techniques and structured exam preparation.'**
  String get explanationExamAnxiety2;

  /// No description provided for @explanationEmotionalBalance1.
  ///
  /// In en, this message translates to:
  /// **'A warm and intuitive guide who specializes in emotional regulation, helping you recognize and process your feelings with compassion. Supports you in building emotional resilience, inner calm, and authentic connection with yourself and others.'**
  String get explanationEmotionalBalance1;

  /// No description provided for @explanationThoughtAndHabitGuide1.
  ///
  /// In en, this message translates to:
  /// **'A transformative guide focused on reshaping your mindset and daily habits. Helps you break limiting thought patterns, build empowering routines, and create lasting positive change through evidence-based techniques.'**
  String get explanationThoughtAndHabitGuide1;

  /// No description provided for @explanationDifficultExperiences1.
  ///
  /// In en, this message translates to:
  /// **'A compassionate and experienced guide who walks alongside you through life\'s most challenging moments — grief, trauma, loss, and uncertainty. Helps you process difficult emotions, find meaning in hardship, and rebuild with renewed strength.'**
  String get explanationDifficultExperiences1;

  /// No description provided for @explanationResilienceEmpowerment1.
  ///
  /// In en, this message translates to:
  /// **'A motivating and strength-focused guide dedicated to helping you discover your inner power. Guides you through challenges, setbacks, and transitions — building the resilience and confidence to face whatever life brings.'**
  String get explanationResilienceEmpowerment1;

  /// No description provided for @explanationFamilyAssistant3.
  ///
  /// In en, this message translates to:
  /// **'An experienced family guide who helps repair strained relationships and rebuild trust between parents and children with empathy and patience.'**
  String get explanationFamilyAssistant3;

  /// No description provided for @explanationFamilyAssistant4.
  ///
  /// In en, this message translates to:
  /// **'A solution-focused family guide who helps you set healthy boundaries, improve communication, and create a peaceful home environment.'**
  String get explanationFamilyAssistant4;

  /// No description provided for @explanationFamilyAssistant5.
  ///
  /// In en, this message translates to:
  /// **'A wise and patient guide for families navigating divorce, separation, or major life transitions with compassion and clarity.'**
  String get explanationFamilyAssistant5;

  /// No description provided for @explanationFamilyAssistant6.
  ///
  /// In en, this message translates to:
  /// **'A nurturing guide who supports children through behavioral challenges while equipping parents with practical, evidence-based strategies.'**
  String get explanationFamilyAssistant6;

  /// No description provided for @explanationFamilyAssistant7.
  ///
  /// In en, this message translates to:
  /// **'A holistic family guide who integrates emotional, communicational, and structural approaches to bring lasting harmony to your home.'**
  String get explanationFamilyAssistant7;

  /// No description provided for @explanationFamilyAssistant8.
  ///
  /// In en, this message translates to:
  /// **'A warm and empowering guide who helps families heal from past wounds and build stronger, more resilient bonds.'**
  String get explanationFamilyAssistant8;

  /// No description provided for @explanationFamilyAssistant9.
  ///
  /// In en, this message translates to:
  /// **'A pragmatic family guide focused on day-to-day parenting solutions, conflict resolution, and consistent routines.'**
  String get explanationFamilyAssistant9;

  /// No description provided for @explanationFamilyAssistant10.
  ///
  /// In en, this message translates to:
  /// **'A compassionate guide for blended families, step-parents, and unique household structures seeking balance and connection.'**
  String get explanationFamilyAssistant10;

  /// No description provided for @explanationFamilyAssistant11.
  ///
  /// In en, this message translates to:
  /// **'A gentle and skilled guide who helps families process grief, loss, and major change while preserving emotional safety for everyone.'**
  String get explanationFamilyAssistant11;

  /// No description provided for @explanationFamilyAssistant12.
  ///
  /// In en, this message translates to:
  /// **'A long-term focused guide invested in cultivating deeply connected, emotionally healthy families across generations.'**
  String get explanationFamilyAssistant12;

  /// No description provided for @explanationThoughtAndHabitGuide2.
  ///
  /// In en, this message translates to:
  /// **'A practical guide who helps you identify and reshape limiting thought patterns through evidence-based cognitive techniques.'**
  String get explanationThoughtAndHabitGuide2;

  /// No description provided for @explanationThoughtAndHabitGuide3.
  ///
  /// In en, this message translates to:
  /// **'A patient mentor specializing in habit formation — helping you build small daily routines that compound into lasting change.'**
  String get explanationThoughtAndHabitGuide3;

  /// No description provided for @explanationThoughtAndHabitGuide4.
  ///
  /// In en, this message translates to:
  /// **'A focused guide who turns negative self-talk into balanced, constructive thinking through mindful awareness practices.'**
  String get explanationThoughtAndHabitGuide4;

  /// No description provided for @explanationThoughtAndHabitGuide5.
  ///
  /// In en, this message translates to:
  /// **'A motivating guide who pairs mindset shifts with actionable habits for measurable personal growth.'**
  String get explanationThoughtAndHabitGuide5;

  /// No description provided for @explanationThoughtAndHabitGuide6.
  ///
  /// In en, this message translates to:
  /// **'A reflective guide who helps you uncover the core beliefs driving your behaviors — and rewrite them with intention.'**
  String get explanationThoughtAndHabitGuide6;

  /// No description provided for @explanationThoughtAndHabitGuide7.
  ///
  /// In en, this message translates to:
  /// **'An empowering guide focused on breaking cycles of overthinking and replacing them with grounded, present-moment awareness.'**
  String get explanationThoughtAndHabitGuide7;

  /// No description provided for @explanationThoughtAndHabitGuide8.
  ///
  /// In en, this message translates to:
  /// **'A structured coach who helps you build morning routines, deep-work habits, and recovery rituals that transform your life.'**
  String get explanationThoughtAndHabitGuide8;

  /// No description provided for @explanationThoughtAndHabitGuide9.
  ///
  /// In en, this message translates to:
  /// **'A compassionate guide who supports you in dropping perfectionism and embracing progress over performance.'**
  String get explanationThoughtAndHabitGuide9;

  /// No description provided for @explanationThoughtAndHabitGuide10.
  ///
  /// In en, this message translates to:
  /// **'A solution-oriented guide who untangles mental loops and creates clear, sustainable paths forward.'**
  String get explanationThoughtAndHabitGuide10;

  /// No description provided for @explanationThoughtAndHabitGuide11.
  ///
  /// In en, this message translates to:
  /// **'A wise mentor for those wanting to align their daily habits with their deepest values and long-term vision.'**
  String get explanationThoughtAndHabitGuide11;

  /// No description provided for @explanationThoughtAndHabitGuide12.
  ///
  /// In en, this message translates to:
  /// **'A grounded guide who helps you build a calmer, clearer, more intentional inner life through thought and habit work.'**
  String get explanationThoughtAndHabitGuide12;

  /// No description provided for @explanationAdult3.
  ///
  /// In en, this message translates to:
  /// **'A practical, results-driven guide for adults navigating career transitions and life-balance challenges.'**
  String get explanationAdult3;

  /// No description provided for @explanationAdult4.
  ///
  /// In en, this message translates to:
  /// **'An empowering guide who helps adults rediscover purpose, motivation, and clarity in their daily lives.'**
  String get explanationAdult4;

  /// No description provided for @explanationAdult5.
  ///
  /// In en, this message translates to:
  /// **'A wise mentor for adults seeking deeper self-understanding, emotional regulation, and meaningful personal growth.'**
  String get explanationAdult5;

  /// No description provided for @explanationAdult6.
  ///
  /// In en, this message translates to:
  /// **'A focused guide who supports adults through high-pressure careers, decision fatigue, and burnout recovery.'**
  String get explanationAdult6;

  /// No description provided for @explanationAdult7.
  ///
  /// In en, this message translates to:
  /// **'A grounded guide for adults wanting to manage stress, build self-confidence, and live with intention.'**
  String get explanationAdult7;

  /// No description provided for @explanationAdult8.
  ///
  /// In en, this message translates to:
  /// **'A holistic guide who integrates mental, emotional, and practical strategies for adult well-being.'**
  String get explanationAdult8;

  /// No description provided for @explanationAdult9.
  ///
  /// In en, this message translates to:
  /// **'A compassionate guide for adults navigating midlife questions, identity shifts, or starting fresh chapters.'**
  String get explanationAdult9;

  /// No description provided for @explanationAdult10.
  ///
  /// In en, this message translates to:
  /// **'A skilled motivator helping adults turn intentions into action through accountability and structured progress.'**
  String get explanationAdult10;

  /// No description provided for @explanationAdult11.
  ///
  /// In en, this message translates to:
  /// **'A reflective guide for adults seeking work–life balance, healthy boundaries, and authentic relationships.'**
  String get explanationAdult11;

  /// No description provided for @explanationAdult12.
  ///
  /// In en, this message translates to:
  /// **'A long-term partner in growth — supporting adults through career, relationships, and personal evolution.'**
  String get explanationAdult12;

  /// No description provided for @explanationChild3.
  ///
  /// In en, this message translates to:
  /// **'A playful and gentle guide who helps children identify and name their emotions through age-appropriate stories and exercises.'**
  String get explanationChild3;

  /// No description provided for @explanationChild4.
  ///
  /// In en, this message translates to:
  /// **'A patient guide skilled at supporting shy or anxious children to express themselves and build social confidence.'**
  String get explanationChild4;

  /// No description provided for @explanationChild5.
  ///
  /// In en, this message translates to:
  /// **'A creative guide who uses imaginative play to help kids process feelings and overcome fears safely.'**
  String get explanationChild5;

  /// No description provided for @explanationChild6.
  ///
  /// In en, this message translates to:
  /// **'A nurturing guide for children adapting to school, new environments, or family changes.'**
  String get explanationChild6;

  /// No description provided for @explanationChild7.
  ///
  /// In en, this message translates to:
  /// **'An encouraging guide who builds children\'s focus, self-control, and behavioral awareness through positive reinforcement.'**
  String get explanationChild7;

  /// No description provided for @explanationChild8.
  ///
  /// In en, this message translates to:
  /// **'A warm and joyful guide who helps children build healthy friendships and navigate social challenges.'**
  String get explanationChild8;

  /// No description provided for @explanationChild9.
  ///
  /// In en, this message translates to:
  /// **'A skilled guide for children dealing with behavioral struggles, sensory needs, or attention difficulties.'**
  String get explanationChild9;

  /// No description provided for @explanationChild10.
  ///
  /// In en, this message translates to:
  /// **'A reassuring guide for children experiencing fears, nightmares, or anxiety — helping them feel safe and understood.'**
  String get explanationChild10;

  /// No description provided for @explanationChild11.
  ///
  /// In en, this message translates to:
  /// **'A creative storytelling guide who helps children process big feelings and tough situations gently.'**
  String get explanationChild11;

  /// No description provided for @explanationChild12.
  ///
  /// In en, this message translates to:
  /// **'A long-term developmental guide who supports children\'s emotional, social, and cognitive growth holistically.'**
  String get explanationChild12;

  /// No description provided for @explanationTeenage3.
  ///
  /// In en, this message translates to:
  /// **'A relatable guide who speaks the language of teens — supporting identity exploration and building real self-confidence.'**
  String get explanationTeenage3;

  /// No description provided for @explanationTeenage4.
  ///
  /// In en, this message translates to:
  /// **'A non-judgmental guide for teens facing peer pressure, social drama, or identity questions.'**
  String get explanationTeenage4;

  /// No description provided for @explanationTeenage5.
  ///
  /// In en, this message translates to:
  /// **'A focused academic-life guide who helps teens balance schoolwork, social life, and self-care without burnout.'**
  String get explanationTeenage5;

  /// No description provided for @explanationTeenage6.
  ///
  /// In en, this message translates to:
  /// **'A digital-wellness aware guide who helps teens build healthy boundaries with social media and screens.'**
  String get explanationTeenage6;

  /// No description provided for @explanationTeenage7.
  ///
  /// In en, this message translates to:
  /// **'An empowering guide for teens learning to manage anger, frustration, and big emotions constructively.'**
  String get explanationTeenage7;

  /// No description provided for @explanationTeenage8.
  ///
  /// In en, this message translates to:
  /// **'A practical guide who helps teens plan their future — college, career, gap years — with curiosity and clarity.'**
  String get explanationTeenage8;

  /// No description provided for @explanationTeenage9.
  ///
  /// In en, this message translates to:
  /// **'A patient mediator who helps improve parent-teen communication and rebuild trust at home.'**
  String get explanationTeenage9;

  /// No description provided for @explanationTeenage10.
  ///
  /// In en, this message translates to:
  /// **'A confidence-building guide who supports teens facing body image, self-esteem, or identity struggles.'**
  String get explanationTeenage10;

  /// No description provided for @explanationTeenage11.
  ///
  /// In en, this message translates to:
  /// **'A compassionate guide for teens navigating loneliness, anxiety, or feeling misunderstood.'**
  String get explanationTeenage11;

  /// No description provided for @explanationTeenage12.
  ///
  /// In en, this message translates to:
  /// **'A holistic teen guide focused on long-term emotional health, resilience, and authentic self-expression.'**
  String get explanationTeenage12;

  /// No description provided for @explanationPersonal3.
  ///
  /// In en, this message translates to:
  /// **'A reflective guide for those seeking deeper self-understanding through journaling, mindfulness, and inner work.'**
  String get explanationPersonal3;

  /// No description provided for @explanationPersonal4.
  ///
  /// In en, this message translates to:
  /// **'A calming guide who helps you move through anxiety with grounded, evidence-based techniques.'**
  String get explanationPersonal4;

  /// No description provided for @explanationPersonal5.
  ///
  /// In en, this message translates to:
  /// **'A compassionate companion for those processing grief, loss, or major life transitions.'**
  String get explanationPersonal5;

  /// No description provided for @explanationPersonal6.
  ///
  /// In en, this message translates to:
  /// **'A mindful guide who teaches breathing, meditation, and presence practices for daily inner peace.'**
  String get explanationPersonal6;

  /// No description provided for @explanationPersonal7.
  ///
  /// In en, this message translates to:
  /// **'A sleep and recovery focused guide who helps you build restful nights and energized days.'**
  String get explanationPersonal7;

  /// No description provided for @explanationPersonal8.
  ///
  /// In en, this message translates to:
  /// **'A thoughtful guide for those caught in cycles of overthinking, helping you find mental clarity and ease.'**
  String get explanationPersonal8;

  /// No description provided for @explanationPersonal9.
  ///
  /// In en, this message translates to:
  /// **'An exploratory guide who supports your journey of self-discovery — finding meaning, values, and direction.'**
  String get explanationPersonal9;

  /// No description provided for @explanationPersonal10.
  ///
  /// In en, this message translates to:
  /// **'A healing-focused guide for those carrying emotional wounds, helping you process and release with care.'**
  String get explanationPersonal10;

  /// No description provided for @explanationPersonal11.
  ///
  /// In en, this message translates to:
  /// **'A gentle guide for those feeling lonely or disconnected, offering presence, perspective, and warm support.'**
  String get explanationPersonal11;

  /// No description provided for @explanationPersonal12.
  ///
  /// In en, this message translates to:
  /// **'A long-term inner-life guide supporting your ongoing emotional growth, healing, and self-mastery.'**
  String get explanationPersonal12;

  /// No description provided for @explanationExamAnxiety3.
  ///
  /// In en, this message translates to:
  /// **'A calming guide who helps students transform exam panic into focused, confident performance.'**
  String get explanationExamAnxiety3;

  /// No description provided for @explanationExamAnxiety4.
  ///
  /// In en, this message translates to:
  /// **'A study-skills expert who teaches efficient techniques, memory tools, and active recall strategies.'**
  String get explanationExamAnxiety4;

  /// No description provided for @explanationExamAnxiety5.
  ///
  /// In en, this message translates to:
  /// **'A practical time-management coach who helps students plan study schedules and stick to them.'**
  String get explanationExamAnxiety5;

  /// No description provided for @explanationExamAnxiety6.
  ///
  /// In en, this message translates to:
  /// **'A pressure-relief guide who teaches breathing, grounding, and visualization to reduce performance anxiety.'**
  String get explanationExamAnxiety6;

  /// No description provided for @explanationExamAnxiety7.
  ///
  /// In en, this message translates to:
  /// **'A focus-building guide for students struggling with concentration, distraction, or procrastination.'**
  String get explanationExamAnxiety7;

  /// No description provided for @explanationExamAnxiety8.
  ///
  /// In en, this message translates to:
  /// **'A relaxation-focused guide who teaches sustainable strategies for staying calm under academic pressure.'**
  String get explanationExamAnxiety8;

  /// No description provided for @explanationExamAnxiety9.
  ///
  /// In en, this message translates to:
  /// **'A structured exam-prep guide who walks students through proven preparation frameworks step by step.'**
  String get explanationExamAnxiety9;

  /// No description provided for @explanationExamAnxiety10.
  ///
  /// In en, this message translates to:
  /// **'A confidence-building guide who helps students believe in their abilities and trust their preparation.'**
  String get explanationExamAnxiety10;

  /// No description provided for @explanationExamAnxiety11.
  ///
  /// In en, this message translates to:
  /// **'An encouraging guide for students battling self-doubt before high-stakes tests like university entrance.'**
  String get explanationExamAnxiety11;

  /// No description provided for @explanationExamAnxiety12.
  ///
  /// In en, this message translates to:
  /// **'A long-term academic wellness guide who builds resilience for years of school challenges, not just one exam.'**
  String get explanationExamAnxiety12;

  /// No description provided for @explanationEmotionalBalance2.
  ///
  /// In en, this message translates to:
  /// **'A calming guide who teaches you to recognize, name, and regulate emotions with practical mindfulness tools.'**
  String get explanationEmotionalBalance2;

  /// No description provided for @explanationEmotionalBalance3.
  ///
  /// In en, this message translates to:
  /// **'A grounded guide for those feeling overwhelmed — helping restore inner steadiness and clarity.'**
  String get explanationEmotionalBalance3;

  /// No description provided for @explanationEmotionalBalance4.
  ///
  /// In en, this message translates to:
  /// **'A wise guide who supports you through emotional ups and downs with patience and proven techniques.'**
  String get explanationEmotionalBalance4;

  /// No description provided for @explanationEmotionalBalance5.
  ///
  /// In en, this message translates to:
  /// **'A compassionate guide for those who feel everything deeply — channeling sensitivity into strength.'**
  String get explanationEmotionalBalance5;

  /// No description provided for @explanationEmotionalBalance6.
  ///
  /// In en, this message translates to:
  /// **'A mindful guide focused on building emotional resilience through daily awareness practices.'**
  String get explanationEmotionalBalance6;

  /// No description provided for @explanationEmotionalBalance7.
  ///
  /// In en, this message translates to:
  /// **'A reflective guide who helps you process unspoken feelings and reconnect with your authentic self.'**
  String get explanationEmotionalBalance7;

  /// No description provided for @explanationEmotionalBalance8.
  ///
  /// In en, this message translates to:
  /// **'A balanced guide who teaches healthy ways to express anger, sadness, fear, and joy without suppression.'**
  String get explanationEmotionalBalance8;

  /// No description provided for @explanationEmotionalBalance9.
  ///
  /// In en, this message translates to:
  /// **'A self-discovery guide who supports you in understanding the patterns behind your emotional reactions.'**
  String get explanationEmotionalBalance9;

  /// No description provided for @explanationEmotionalBalance10.
  ///
  /// In en, this message translates to:
  /// **'A peaceful guide who helps you move from emotional chaos to centered calm, one practice at a time.'**
  String get explanationEmotionalBalance10;

  /// No description provided for @explanationEmotionalBalance11.
  ///
  /// In en, this message translates to:
  /// **'An anxiety-aware guide who pairs emotional regulation with practical tools for everyday challenges.'**
  String get explanationEmotionalBalance11;

  /// No description provided for @explanationEmotionalBalance12.
  ///
  /// In en, this message translates to:
  /// **'A long-term inner-balance guide supporting your emotional well-being through life\'s seasons.'**
  String get explanationEmotionalBalance12;

  /// No description provided for @explanationDifficultExperiences2.
  ///
  /// In en, this message translates to:
  /// **'A compassionate guide who walks beside you through grief, trauma, and life\'s hardest chapters with patience and care.'**
  String get explanationDifficultExperiences2;

  /// No description provided for @explanationDifficultExperiences3.
  ///
  /// In en, this message translates to:
  /// **'A trauma-informed guide who helps you process painful experiences safely, at your own pace.'**
  String get explanationDifficultExperiences3;

  /// No description provided for @explanationDifficultExperiences4.
  ///
  /// In en, this message translates to:
  /// **'A gentle guide for those mourning a loss — offering presence, perspective, and tools for healing.'**
  String get explanationDifficultExperiences4;

  /// No description provided for @explanationDifficultExperiences5.
  ///
  /// In en, this message translates to:
  /// **'An anxiety-aware guide who helps you find ground when life feels uncertain or overwhelming.'**
  String get explanationDifficultExperiences5;

  /// No description provided for @explanationDifficultExperiences6.
  ///
  /// In en, this message translates to:
  /// **'A warm guide for those feeling alone in their pain — reminding you that healing happens in connection.'**
  String get explanationDifficultExperiences6;

  /// No description provided for @explanationDifficultExperiences7.
  ///
  /// In en, this message translates to:
  /// **'A confidence-rebuilding guide for those whose self-worth has been shaken by hardship.'**
  String get explanationDifficultExperiences7;

  /// No description provided for @explanationDifficultExperiences8.
  ///
  /// In en, this message translates to:
  /// **'A skilled guide who helps regulate intense emotions that arise during and after difficult experiences.'**
  String get explanationDifficultExperiences8;

  /// No description provided for @explanationDifficultExperiences9.
  ///
  /// In en, this message translates to:
  /// **'A mindful guide who teaches presence as an antidote to spiraling thoughts about the past.'**
  String get explanationDifficultExperiences9;

  /// No description provided for @explanationDifficultExperiences10.
  ///
  /// In en, this message translates to:
  /// **'A self-discovery guide for those rebuilding identity and meaning after major life upheavals.'**
  String get explanationDifficultExperiences10;

  /// No description provided for @explanationDifficultExperiences11.
  ///
  /// In en, this message translates to:
  /// **'A patient guide who supports long-term emotional healing without rushing or shortcutting the process.'**
  String get explanationDifficultExperiences11;

  /// No description provided for @explanationDifficultExperiences12.
  ///
  /// In en, this message translates to:
  /// **'A resilience-building guide who helps you find strength, meaning, and renewed hope through hardship.'**
  String get explanationDifficultExperiences12;

  /// No description provided for @explanationResilienceEmpowerment2.
  ///
  /// In en, this message translates to:
  /// **'A motivating guide who helps you build unshakable self-confidence and trust in your abilities.'**
  String get explanationResilienceEmpowerment2;

  /// No description provided for @explanationResilienceEmpowerment3.
  ///
  /// In en, this message translates to:
  /// **'A growth-focused guide who turns setbacks into stepping stones and obstacles into opportunities.'**
  String get explanationResilienceEmpowerment3;

  /// No description provided for @explanationResilienceEmpowerment4.
  ///
  /// In en, this message translates to:
  /// **'A self-discovery guide who helps you uncover hidden strengths and align with your authentic power.'**
  String get explanationResilienceEmpowerment4;

  /// No description provided for @explanationResilienceEmpowerment5.
  ///
  /// In en, this message translates to:
  /// **'A clarity-building guide for those facing big decisions — helping you trust yourself and act with confidence.'**
  String get explanationResilienceEmpowerment5;

  /// No description provided for @explanationResilienceEmpowerment6.
  ///
  /// In en, this message translates to:
  /// **'A mindful guide who pairs presence with empowerment, helping you respond — not react — to life\'s challenges.'**
  String get explanationResilienceEmpowerment6;

  /// No description provided for @explanationResilienceEmpowerment7.
  ///
  /// In en, this message translates to:
  /// **'A self-esteem focused guide who helps you replace harsh self-criticism with genuine self-respect.'**
  String get explanationResilienceEmpowerment7;

  /// No description provided for @explanationResilienceEmpowerment8.
  ///
  /// In en, this message translates to:
  /// **'A confidence-building guide for those stepping into new roles, careers, or chapters of life.'**
  String get explanationResilienceEmpowerment8;

  /// No description provided for @explanationResilienceEmpowerment9.
  ///
  /// In en, this message translates to:
  /// **'A practical guide who helps you bounce back stronger from disappointment, rejection, or failure.'**
  String get explanationResilienceEmpowerment9;

  /// No description provided for @explanationResilienceEmpowerment10.
  ///
  /// In en, this message translates to:
  /// **'An empowering long-term guide invested in helping you build lasting strength, courage, and self-trust.'**
  String get explanationResilienceEmpowerment10;

  /// No description provided for @explanationResilienceEmpowerment11.
  ///
  /// In en, this message translates to:
  /// **'A wise mentor who helps you stand tall in your truth, set firm boundaries, and protect your energy.'**
  String get explanationResilienceEmpowerment11;

  /// No description provided for @explanationResilienceEmpowerment12.
  ///
  /// In en, this message translates to:
  /// **'A holistic resilience guide who supports your ongoing journey of growth, courage, and self-empowerment.'**
  String get explanationResilienceEmpowerment12;

  /// No description provided for @roleMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get roleMale;

  /// No description provided for @roleFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get roleFemale;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterCoachingArea.
  ///
  /// In en, this message translates to:
  /// **'Guidance Area'**
  String get filterCoachingArea;

  /// No description provided for @filterExpertise.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get filterExpertise;

  /// No description provided for @filterSelectCoachingArea.
  ///
  /// In en, this message translates to:
  /// **'Select Guidance Area'**
  String get filterSelectCoachingArea;

  /// No description provided for @filterSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get filterSave;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @coachDetailInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get coachDetailInformation;

  /// No description provided for @coachDetailUnlimitedMemory.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get coachDetailUnlimitedMemory;

  /// No description provided for @coachDetailMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get coachDetailMemory;

  /// No description provided for @coachDetailMultilingual.
  ///
  /// In en, this message translates to:
  /// **'Multilingual'**
  String get coachDetailMultilingual;

  /// No description provided for @coachDetailLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get coachDetailLanguage;

  /// No description provided for @coachDetailAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get coachDetailAvailability;

  /// No description provided for @coachDetailAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get coachDetailAppointment;

  /// No description provided for @coachDetailStartVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Start Video Call'**
  String get coachDetailStartVideoCall;

  /// No description provided for @coachDetailOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get coachDetailOnline;

  /// No description provided for @coachDetailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get coachDetailVerified;

  /// No description provided for @coachDetailCreateAppointment.
  ///
  /// In en, this message translates to:
  /// **'Create an appointment'**
  String get coachDetailCreateAppointment;

  /// No description provided for @searchSoundHint.
  ///
  /// In en, this message translates to:
  /// **'Search sounds, moods, vibes..'**
  String get searchSoundHint;

  /// No description provided for @featuredForYou.
  ///
  /// In en, this message translates to:
  /// **'Featured For You'**
  String get featuredForYou;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @soundCategoryFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get soundCategoryFocus;

  /// No description provided for @soundCategorySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get soundCategorySleep;

  /// No description provided for @soundCategoryMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get soundCategoryMeditation;

  /// No description provided for @soundCategoryRelax.
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get soundCategoryRelax;

  /// No description provided for @soundDeepWorkFlow.
  ///
  /// In en, this message translates to:
  /// **'Deep Work Flow'**
  String get soundDeepWorkFlow;

  /// No description provided for @soundDeepWorkFlowSub.
  ///
  /// In en, this message translates to:
  /// **'Enhance your productivity'**
  String get soundDeepWorkFlowSub;

  /// No description provided for @soundBinauralBeats.
  ///
  /// In en, this message translates to:
  /// **'Binaural Beats'**
  String get soundBinauralBeats;

  /// No description provided for @soundBinauralBeatsSub.
  ///
  /// In en, this message translates to:
  /// **'Tune your brainwaves'**
  String get soundBinauralBeatsSub;

  /// No description provided for @soundLibraryAmbience.
  ///
  /// In en, this message translates to:
  /// **'Library Ambience'**
  String get soundLibraryAmbience;

  /// No description provided for @soundLibraryAmbienceSub.
  ///
  /// In en, this message translates to:
  /// **'Quiet study atmosphere'**
  String get soundLibraryAmbienceSub;

  /// No description provided for @soundRainOnWindow.
  ///
  /// In en, this message translates to:
  /// **'Rain on Window'**
  String get soundRainOnWindow;

  /// No description provided for @soundRainOnWindowSub.
  ///
  /// In en, this message translates to:
  /// **'Drift into peaceful sleep'**
  String get soundRainOnWindowSub;

  /// No description provided for @soundOceanWaves.
  ///
  /// In en, this message translates to:
  /// **'Ocean Waves'**
  String get soundOceanWaves;

  /// No description provided for @soundOceanWavesSub.
  ///
  /// In en, this message translates to:
  /// **'Rhythmic waves to calm you'**
  String get soundOceanWavesSub;

  /// No description provided for @soundDeepSpaceDrone.
  ///
  /// In en, this message translates to:
  /// **'Deep Space Drone'**
  String get soundDeepSpaceDrone;

  /// No description provided for @soundDeepSpaceDroneSub.
  ///
  /// In en, this message translates to:
  /// **'Cosmic ambient journey'**
  String get soundDeepSpaceDroneSub;

  /// No description provided for @soundTibetanBowls.
  ///
  /// In en, this message translates to:
  /// **'Tibetan Bowls'**
  String get soundTibetanBowls;

  /// No description provided for @soundTibetanBowlsSub.
  ///
  /// In en, this message translates to:
  /// **'Ancient healing vibrations'**
  String get soundTibetanBowlsSub;

  /// No description provided for @soundForestBirds.
  ///
  /// In en, this message translates to:
  /// **'Forest Birds'**
  String get soundForestBirds;

  /// No description provided for @soundForestBirdsSub.
  ///
  /// In en, this message translates to:
  /// **'Nature\'s morning melody'**
  String get soundForestBirdsSub;

  /// No description provided for @soundMorningZen.
  ///
  /// In en, this message translates to:
  /// **'Morning Zen'**
  String get soundMorningZen;

  /// No description provided for @soundMorningZenSub.
  ///
  /// In en, this message translates to:
  /// **'Start your day mindfully'**
  String get soundMorningZenSub;

  /// No description provided for @soundFireplaceCrackle.
  ///
  /// In en, this message translates to:
  /// **'Fireplace Crackle'**
  String get soundFireplaceCrackle;

  /// No description provided for @soundFireplaceCrackleSub.
  ///
  /// In en, this message translates to:
  /// **'Warm and cozy vibes'**
  String get soundFireplaceCrackleSub;

  /// No description provided for @soundGentleStream.
  ///
  /// In en, this message translates to:
  /// **'Gentle Stream'**
  String get soundGentleStream;

  /// No description provided for @soundGentleStreamSub.
  ///
  /// In en, this message translates to:
  /// **'Flowing water serenity'**
  String get soundGentleStreamSub;

  /// No description provided for @soundSoftPiano.
  ///
  /// In en, this message translates to:
  /// **'Soft Piano'**
  String get soundSoftPiano;

  /// No description provided for @soundSoftPianoSub.
  ///
  /// In en, this message translates to:
  /// **'Delicate melodies to unwind'**
  String get soundSoftPianoSub;

  /// No description provided for @quickMessage.
  ///
  /// In en, this message translates to:
  /// **'Quick Message'**
  String get quickMessage;

  /// No description provided for @chatMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessage;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get chatHistory;

  /// No description provided for @noChatHistory.
  ///
  /// In en, this message translates to:
  /// **'No chat history yet'**
  String get noChatHistory;

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get calling;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @coachesTitle.
  ///
  /// In en, this message translates to:
  /// **'Guides'**
  String get coachesTitle;

  /// No description provided for @searchAtMindcoach.
  ///
  /// In en, this message translates to:
  /// **'Search at MindCoach'**
  String get searchAtMindcoach;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noResultsFound(String query);

  /// No description provided for @premiumTryFree.
  ///
  /// In en, this message translates to:
  /// **'Try MindCoach Premium\nfree for 1 week'**
  String get premiumTryFree;

  /// No description provided for @premiumUnlimitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited access and take advantage of opportunities'**
  String get premiumUnlimitedAccess;

  /// No description provided for @premiumFeatureSkipAds.
  ///
  /// In en, this message translates to:
  /// **'Skip Ads'**
  String get premiumFeatureSkipAds;

  /// No description provided for @premiumFeatureUnlimitedCharacters.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Character Selection'**
  String get premiumFeatureUnlimitedCharacters;

  /// No description provided for @premiumFeatureExpandedMemory.
  ///
  /// In en, this message translates to:
  /// **'Expanded memory and context'**
  String get premiumFeatureExpandedMemory;

  /// No description provided for @premiumFeatureAdvancedReasoning.
  ///
  /// In en, this message translates to:
  /// **'With advanced reasoning capabilities'**
  String get premiumFeatureAdvancedReasoning;

  /// No description provided for @premiumStartTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 1 week free trial'**
  String get premiumStartTrial;

  /// No description provided for @premiumBillingNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be charged \$8.99/month after your 7 day free trial. You can cancel anytime.'**
  String get premiumBillingNote;

  /// No description provided for @premiumRestorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get premiumRestorePurchase;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @premiumSaveBadge.
  ///
  /// In en, this message translates to:
  /// **'SAVE 17%'**
  String get premiumSaveBadge;

  /// No description provided for @premiumPlanAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get premiumPlanAnnual;

  /// No description provided for @premiumPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premiumPlanMonthly;

  /// No description provided for @premiumPlanPerYearAfterTrial.
  ///
  /// In en, this message translates to:
  /// **'per year after 7 days trial'**
  String get premiumPlanPerYearAfterTrial;

  /// No description provided for @goodbyeTitle.
  ///
  /// In en, this message translates to:
  /// **'We Miss You '**
  String get goodbyeTitle;

  /// No description provided for @goodbyeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re sorry you deleted your account.\nWe hope to see you again...'**
  String get goodbyeSubtitle;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @profileFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profileFromGallery;

  /// No description provided for @profileFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get profileFromCamera;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'You are about to log out'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See you again soon! We\'ll miss your breathing exercises.'**
  String get logoutDialogSubtitle;

  /// No description provided for @sectionAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get sectionAccountSettings;

  /// No description provided for @sectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get sectionGeneral;

  /// No description provided for @menuItemPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get menuItemPremium;

  /// No description provided for @menuItemRateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get menuItemRateUs;

  /// No description provided for @premiumBadge.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get premiumBadge;

  /// No description provided for @premiumStatusActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get premiumStatusActive;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get linkCopied;

  /// No description provided for @shareFriend.
  ///
  /// In en, this message translates to:
  /// **'Share Friend'**
  String get shareFriend;

  /// No description provided for @errorMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent'**
  String get errorMessageFailed;

  /// No description provided for @errorImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Image could not be sent'**
  String get errorImageFailed;

  /// No description provided for @errorVoiceFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Voice file not found'**
  String get errorVoiceFileNotFound;

  /// No description provided for @errorVoiceMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice message could not be sent'**
  String get errorVoiceMessageFailed;

  /// No description provided for @errorVoiceNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Voice file could not be played'**
  String get errorVoiceNotPlayed;

  /// No description provided for @errorVoiceMessageNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Voice message could not be played'**
  String get errorVoiceMessageNotPlayed;

  /// No description provided for @errorRecordingStart.
  ///
  /// In en, this message translates to:
  /// **'Recording could not be started'**
  String get errorRecordingStart;

  /// No description provided for @errorRecordingStop.
  ///
  /// In en, this message translates to:
  /// **'Recording could not be stopped'**
  String get errorRecordingStop;

  /// No description provided for @errorMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get errorMicrophonePermission;

  /// No description provided for @errorRecordingTooShort.
  ///
  /// In en, this message translates to:
  /// **'Recording too short, please record longer'**
  String get errorRecordingTooShort;

  /// No description provided for @errorAppointmentDateNotFound.
  ///
  /// In en, this message translates to:
  /// **'Appointment date not found'**
  String get errorAppointmentDateNotFound;

  /// No description provided for @errorAppointmentExpired.
  ///
  /// In en, this message translates to:
  /// **'Appointment time has passed'**
  String get errorAppointmentExpired;

  /// No description provided for @errorAppointmentNotYet.
  ///
  /// In en, this message translates to:
  /// **'Session hasn\'t started yet'**
  String get errorAppointmentNotYet;

  /// No description provided for @errorConsultantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Consultant not found'**
  String get errorConsultantNotFound;

  /// No description provided for @errorConsultantsNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Consultant list could not be loaded'**
  String get errorConsultantsNotLoaded;

  /// No description provided for @errorConsultantLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Consultant could not be loaded'**
  String get errorConsultantLoadFailed;

  /// No description provided for @errorOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get errorOperationFailed;

  /// No description provided for @errorPhotoUpload.
  ///
  /// In en, this message translates to:
  /// **'Profile photo could not be uploaded'**
  String get errorPhotoUpload;

  /// No description provided for @errorGeneral.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneral;

  /// No description provided for @recordingStatus.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recordingStatus;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @messageOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Write your message if you have any.'**
  String get messageOptionalHint;

  /// No description provided for @findCoachMatchedFor.
  ///
  /// In en, this message translates to:
  /// **'{count} guides matched for {area}'**
  String findCoachMatchedFor(int count, String area);

  /// No description provided for @findCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your guide'**
  String get findCoachTitle;

  /// No description provided for @findCoachSwipeToBrowse.
  ///
  /// In en, this message translates to:
  /// **'Swipe to browse - {schedule}'**
  String findCoachSwipeToBrowse(String schedule);

  /// No description provided for @findCoachYearsExperience.
  ///
  /// In en, this message translates to:
  /// **'{count} yrs experience'**
  String findCoachYearsExperience(int count);

  /// No description provided for @findCoachSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get findCoachSkip;

  /// No description provided for @findCoachBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get findCoachBook;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Take a moment for yourself.'**
  String get splashTagline;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @trialEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get trialEndedTitle;

  /// No description provided for @trialEndedMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the 1-minute trial limit. Sign in to keep talking with your guide.'**
  String get trialEndedMessage;

  /// No description provided for @trialEndedAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get trialEndedAction;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @noCompletedAppointments.
  ///
  /// In en, this message translates to:
  /// **'No completed appointments'**
  String get noCompletedAppointments;

  /// No description provided for @videoCallStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get videoCallStatusConnecting;

  /// No description provided for @videoCallStatusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get videoCallStatusListening;

  /// No description provided for @videoCallStatusMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get videoCallStatusMuted;

  /// No description provided for @videoCallStatusThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get videoCallStatusThinking;

  /// No description provided for @videoCallStatusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get videoCallStatusSpeaking;

  /// No description provided for @videoCallStatusError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get videoCallStatusError;

  /// No description provided for @videoCallEncrypted.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encrypted'**
  String get videoCallEncrypted;

  /// No description provided for @videoCallTurnCamera.
  ///
  /// In en, this message translates to:
  /// **'Turn Camera'**
  String get videoCallTurnCamera;

  /// No description provided for @videoCallEndButton.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get videoCallEndButton;

  /// No description provided for @videoCallMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get videoCallMute;

  /// No description provided for @videoCallEndDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end the call?'**
  String get videoCallEndDialogTitle;

  /// No description provided for @videoCallEndDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get videoCallEndDialogCancel;

  /// No description provided for @videoCallEndDialogEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get videoCallEndDialogEnd;

  /// No description provided for @videoCallRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Conversation'**
  String get videoCallRateTitle;

  /// No description provided for @videoCallRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluate the video call'**
  String get videoCallRateSubtitle;

  /// No description provided for @premiumStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get premiumStatusInactive;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

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
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
