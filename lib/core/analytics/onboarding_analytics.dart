/// Onboarding carousel slide metadata (mindcoach_posthog_events.html).
abstract final class OnboardingAnalytics {
  static const List<String> slideNames = [
    'feeling_overwhelmed',
    'talk_your_way',
    'find_the_right_coach',
  ];

  /// 1-based slide number for PostHog.
  static int slideNumber(int index) => index + 1;

  static String slideName(int index) {
    if (index >= 0 && index < slideNames.length) {
      return slideNames[index];
    }
    return 'unknown';
  }
}
