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

  /// No description provided for @approachTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like your counselor to approach you?'**
  String get approachTitle;

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
  /// **'A short bio helps others know the real you. Keep it fun and genuine.'**
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

  /// No description provided for @supportAreaTitle.
  ///
  /// In en, this message translates to:
  /// **'In which area would you like to receive support?'**
  String get supportAreaTitle;

  /// No description provided for @supportAreaIndividual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
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

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @meetingTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'What time would you like to meet?'**
  String get meetingTimeTitle;

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
  /// **'(8:00 AM–12:00 PM)'**
  String get meetingTimeMorningRange;

  /// No description provided for @meetingTimeAfternoonRange.
  ///
  /// In en, this message translates to:
  /// **'(12:00 PM–6:00 PM)'**
  String get meetingTimeAfternoonRange;

  /// No description provided for @meetingTimeEveningRange.
  ///
  /// In en, this message translates to:
  /// **'(6:00 PM–9:00 PM)'**
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
