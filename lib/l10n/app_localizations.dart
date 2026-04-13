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

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Feeling overwhelmed?'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Talk to a certified coach in minutes — whenever you need it.'**
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
  /// **'Find the right coach for you.'**
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
  /// **'Find My Coaches'**
  String get findMyCoaches;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to find your coach and start your journey. Takes 2 minutes.'**
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
  /// **'How should your coach approach you?'**
  String get approachTitle;

  /// No description provided for @approachSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us match your personality to the right coach'**
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
  /// **'So your coach can get to know the real you'**
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
  /// **'We\'ll only show coaches who specialise in this'**
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
  /// **'So we only show coaches free when you are'**
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
  /// **'Coaches with matching slots will be highlighted'**
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

  /// First rule: evaluate your last week, bold part between **
  ///
  /// In en, this message translates to:
  /// **'Evaluate your **last week**.'**
  String get testRule1;

  /// Second rule: recommended frequency of the test
  ///
  /// In en, this message translates to:
  /// **'It is recommended that you take the test **once a week**.'**
  String get testRule2;

  /// Third rule: user can continue later
  ///
  /// In en, this message translates to:
  /// **'If you stop the test halfway through, **you can continue from where you left off.**'**
  String get testRule3;

  /// Legal/medical disclaimer for mental health test
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
  /// **'Development Coach'**
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
  /// **'Thought and Habit Coach'**
  String get jobThoughtAndHabitGuide;

  /// No description provided for @jobFamilyAssistant.
  ///
  /// In en, this message translates to:
  /// **'Family Coach'**
  String get jobFamilyAssistant;

  /// No description provided for @jobAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult Coach'**
  String get jobAdult;

  /// No description provided for @jobChild.
  ///
  /// In en, this message translates to:
  /// **'Child Coach'**
  String get jobChild;

  /// No description provided for @jobTeenage.
  ///
  /// In en, this message translates to:
  /// **'Teen Coach'**
  String get jobTeenage;

  /// No description provided for @jobPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal Coach'**
  String get jobPersonal;

  /// No description provided for @jobExamAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Exam Anxiety Coach'**
  String get jobExamAnxiety;

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
  /// **'A family coach who helps you navigate through family dynamics, resolve conflicts, strengthen parent-child bonds, and build a more harmonious home environment. Whether you\'re dealing with communication breakdowns, boundary issues, or major life transitions like divorce, your coach provides a safe space to explore solutions together.'**
  String get explanationFamilyAssistant;

  /// No description provided for @explanationAdult.
  ///
  /// In en, this message translates to:
  /// **'A personal development coach designed for adults who want to take control of their lives. From managing daily stress and building self-confidence to making important career decisions and finding life balance, your coach supports you with practical strategies tailored to your unique challenges and goals.'**
  String get explanationAdult;

  /// No description provided for @explanationChild.
  ///
  /// In en, this message translates to:
  /// **'A gentle and supportive coach specially trained to help children express their emotions, build social skills, and adapt to school life. Using age-appropriate techniques, your coach helps kids overcome fears, improve focus, and develop healthy friendships in a safe and encouraging environment.'**
  String get explanationChild;

  /// No description provided for @explanationTeenage.
  ///
  /// In en, this message translates to:
  /// **'A coach who truly understands the teenage experience. From identity exploration and peer pressure to academic stress and digital wellbeing, your coach helps teens build self-esteem, manage emotions, and plan for the future while maintaining healthy communication with parents.'**
  String get explanationTeenage;

  /// No description provided for @explanationPersonal.
  ///
  /// In en, this message translates to:
  /// **'A compassionate personal coach focused on your inner wellbeing. Whether you\'re struggling with loneliness, anxiety, grief, or simply overthinking, your coach guides you through mindfulness practices, emotional healing techniques, and self-discovery exercises to help you find peace and clarity.'**
  String get explanationPersonal;

  /// No description provided for @explanationExamAnxiety.
  ///
  /// In en, this message translates to:
  /// **'A specialized coach who helps students conquer exam anxiety and unlock their true academic potential. Through proven study techniques, relaxation methods, and confidence-building exercises, your coach transforms test stress into focused preparation and calm performance.'**
  String get explanationExamAnxiety;

  /// No description provided for @explanationFamilyAssistant1.
  ///
  /// In en, this message translates to:
  /// **'A dedicated family coach specializing in resolving deep-rooted family conflicts and rebuilding strained relationships. With expertise in parenting challenges, communication skills, and setting healthy boundaries, this coach helps families navigate difficult transitions like divorce while guiding children through behavioral changes — all within a safe, judgment-free space.'**
  String get explanationFamilyAssistant1;

  /// No description provided for @explanationFamilyAssistant2.
  ///
  /// In en, this message translates to:
  /// **'A warm and empathetic family coach focused on strengthening the bonds that matter most. Specializing in effective parenting strategies, open communication, and relationship repair, this coach helps families heal after difficult periods like separation or divorce, while supporting children\'s emotional and behavioral development toward lasting harmony.'**
  String get explanationFamilyAssistant2;

  /// No description provided for @explanationAdult1.
  ///
  /// In en, this message translates to:
  /// **'A results-driven coach for adults seeking meaningful change. With a focus on stress management, achieving life balance, and career guidance, this coach helps you regulate your emotions, make confident decisions, and unlock sustainable personal growth through practical, goal-oriented strategies.'**
  String get explanationAdult1;

  /// No description provided for @explanationAdult2.
  ///
  /// In en, this message translates to:
  /// **'A holistic development coach empowering adults to reach their full potential. From building unshakable self-confidence and managing stress to finding career direction and daily motivation, this coach combines emotional regulation techniques with actionable life strategies to create lasting positive change.'**
  String get explanationAdult2;

  /// No description provided for @explanationTeenage1.
  ///
  /// In en, this message translates to:
  /// **'A coach who deeply understands the unique challenges of adolescence. From navigating identity development and resisting peer pressure to managing academic stress and building healthy digital habits, this coach helps teens strengthen their self-esteem, control anger, plan their future, and communicate openly with their parents.'**
  String get explanationTeenage1;

  /// No description provided for @explanationTeenage2.
  ///
  /// In en, this message translates to:
  /// **'An empathetic guide through the turbulent teenage years. Specializing in identity exploration, academic pressure, and digital wellbeing, this coach empowers teens to develop resilience against peer influence, manage anger constructively, build long-term goals, and maintain healthy parent-teen relationships.'**
  String get explanationTeenage2;

  /// No description provided for @explanationChild1.
  ///
  /// In en, this message translates to:
  /// **'A nurturing coach designed to support children through their most formative years. Using gentle, age-appropriate methods, this coach helps kids develop emotional awareness, build social skills, adapt to school life, express themselves freely, overcome fears, form meaningful friendships, improve focus, and develop positive behavioral patterns.'**
  String get explanationChild1;

  /// No description provided for @explanationChild2.
  ///
  /// In en, this message translates to:
  /// **'A caring and patient coach dedicated to helping children thrive. With a focus on emotional intelligence, social development, and school adaptation, this coach creates a safe environment where kids learn to express their feelings, conquer fears, build lasting friendships, strengthen concentration, and receive the behavioral support they need to grow confidently.'**
  String get explanationChild2;

  /// No description provided for @explanationPersonal1.
  ///
  /// In en, this message translates to:
  /// **'A deeply compassionate coach focused on your emotional wellbeing and inner peace. Whether you\'re experiencing loneliness, anxiety, grief, or restless nights, this coach guides you through mindfulness practices, emotional healing processes, and self-discovery journeys to help you break free from overthinking and find lasting clarity.'**
  String get explanationPersonal1;

  /// No description provided for @explanationPersonal2.
  ///
  /// In en, this message translates to:
  /// **'A supportive and intuitive personal coach who helps you reconnect with yourself. Specializing in anxiety management, mindfulness techniques, and sleep improvement, this coach gently guides you through patterns of overthinking and emotional distress toward genuine healing and a renewed sense of inner calm.'**
  String get explanationPersonal2;

  /// No description provided for @explanationExamAnxiety1.
  ///
  /// In en, this message translates to:
  /// **'A focused and methodical coach who transforms exam stress into confident performance. Specializing in time management, handling performance pressure, and building deep concentration, this coach equips students with practical relaxation methods, structured exam preparation techniques, and confidence-building strategies for academic success.'**
  String get explanationExamAnxiety1;

  /// No description provided for @explanationExamAnxiety2.
  ///
  /// In en, this message translates to:
  /// **'A specialized academic coach dedicated to helping students overcome test anxiety and study smarter. Through proven study techniques, effective time management, and performance pressure resilience, this coach builds deep concentration skills, structured exam preparation habits, and lasting confidence for every test day.'**
  String get explanationExamAnxiety2;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterCoachingArea.
  ///
  /// In en, this message translates to:
  /// **'Coaching Area'**
  String get filterCoachingArea;

  /// No description provided for @filterExpertise.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get filterExpertise;

  /// No description provided for @filterSelectCoachingArea.
  ///
  /// In en, this message translates to:
  /// **'Select Coaching Area'**
  String get filterSelectCoachingArea;

  /// No description provided for @filterSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get filterSave;

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
