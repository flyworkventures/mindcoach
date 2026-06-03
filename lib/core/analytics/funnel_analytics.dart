import 'package:mindcoach/Riverpod/Controllers/ProfileSetupController/profile_setup_controller.dart';
import 'package:mindcoach/View/ProfileSetupView/constants/approach_strings.dart';
import 'package:mindcoach/View/ProfileSetupView/domain/profile_models.dart';
import 'package:mindcoach/View/auth/domain/social_login_provider.dart';

/// PostHog onboarding funnel (HTML spec) — property değerleri ve yardımcılar.
abstract final class FunnelAnalytics {
  static const int profileStepCount = 5;

  static String profileStepName(int step) {
    switch (step) {
      case 1:
        return 'about_you';
      case 2:
        return 'support_area';
      case 3:
        return 'coach_approach';
      case 4:
        return 'available_days';
      case 5:
        return 'available_time';
      default:
        return 'about_you';
    }
  }

  static Map<String, Object> profileStepViewedProps(int step) => {
        'step': step,
        'step_name': profileStepName(step),
      };

  static Map<String, Object> profileStepCompletedProps(
    int step,
    ProfileSetupState state,
  ) {
    final props = <String, Object>{
      'step': step,
      'step_name': profileStepName(step),
    };
    switch (step) {
      case 1:
        props['name_provided'] = state.fullName.trim().isNotEmpty;
        final gender = genderForAnalytics(state.gender);
        if (gender != null) props['gender'] = gender;
      case 2:
        final area = supportAreaForAnalytics(state.supportArea);
        if (area != null) props['support_area'] = area;
      case 3:
        final approach = coachApproachForAnalytics(state.approach);
        if (approach != null) props['coach_approach'] = approach;
      case 4:
        if (state.availableDays.isNotEmpty) {
          props['available_days'] = weekdaysForAnalytics(state.availableDays);
        }
      case 5:
        final slot = timeSlotForAnalytics(state.meetingTime);
        if (slot != null) props['time_slot'] = slot;
    }
    return props;
  }

  static Map<String, Object> profilePersonProperties(ProfileSetupState state) {
    final props = <String, Object>{};
    final gender = genderForAnalytics(state.gender);
    if (gender != null) props['gender'] = gender;
    final area = supportAreaForAnalytics(state.supportArea);
    if (area != null) props['support_area'] = area;
    final approach = coachApproachForAnalytics(state.approach);
    if (approach != null) props['coach_approach'] = approach;
    if (state.availableDays.isNotEmpty) {
      props['available_days'] = weekdaysForAnalytics(state.availableDays);
    }
    final slot = timeSlotForAnalytics(state.meetingTime);
    if (slot != null) props['time_slot'] = slot;
    if (state.fullName.trim().isNotEmpty) {
      props['name'] = state.fullName.trim();
    }
    return props;
  }

  static Map<String, Object> coachMatchesViewedProps(ProfileSetupState state) {
    final props = <String, Object>{};
    final area = supportAreaForAnalytics(state.supportArea);
    if (area != null) props['support_area'] = area;
    if (state.availableDays.isNotEmpty) {
      props['available_days'] = weekdaysForAnalytics(state.availableDays);
    }
    final slot = timeSlotForAnalytics(state.meetingTime);
    if (slot != null) props['time_slot'] = slot;
    return props;
  }

  static String? genderForAnalytics(Gender? gender) {
    if (gender == null) return null;
    return switch (gender) {
      Gender.male => 'male',
      Gender.female => 'female',
      Gender.unknown => 'prefer_not_to_say',
    };
  }

  static String? supportAreaForAnalytics(SupportArea? area) {
    if (area == null) return null;
    return switch (area) {
      SupportArea.individual => 'individual_growth',
      SupportArea.family => 'family',
      SupportArea.career => 'career',
      SupportArea.education => 'education',
      SupportArea.personalDevelopment => 'personal_development',
    };
  }

  static String? coachApproachForAnalytics(ApproachType? approach) {
    if (approach == null) return null;
    return switch (approach) {
      ApproachType.patient => 'supportive',
      ApproachType.supportive => 'supportive',
      ApproachType.convincing => 'convincing',
      ApproachType.energetic => 'energetic',
      ApproachType.humorous => 'humorous',
    };
  }

  static List<String> weekdaysForAnalytics(List<Weekday> days) {
    const map = {
      Weekday.monday: 'mon',
      Weekday.tuesday: 'tue',
      Weekday.wednesday: 'wed',
      Weekday.thursday: 'thu',
      Weekday.friday: 'fri',
      Weekday.saturday: 'sat',
      Weekday.sunday: 'sun',
    };
    return days.map((d) => map[d]!).toList()..sort();
  }

  static String? timeSlotForAnalytics(MeetingTime? time) {
    if (time == null) return null;
    return time.name;
  }

  static String authMethod(SocialLoginProvider provider) {
    return switch (provider) {
      SocialLoginProvider.google => 'google',
      SocialLoginProvider.apple => 'apple',
      SocialLoginProvider.guest => 'guest',
      SocialLoginProvider.facebook => 'facebook',
    };
  }
}
