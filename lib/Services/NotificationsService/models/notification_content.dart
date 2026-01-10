/// Notification Content Model
/// Stores notification content for different intervals
class NotificationContent {
  final String title;
  final String body;
  final String? payload;

  const NotificationContent({
    required this.title,
    required this.body,
    this.payload,
  });

  /// Default notification contents for different intervals
  static const NotificationContent twoHour = NotificationContent(
    title: 'MindCoach',
    body: 'Biraz durup nefes almak ister misin?',
    payload: 'reminder_2h',
  );

  static const NotificationContent fourHour = NotificationContent(
    title: 'MindCoach',
    body: 'Zihninde kalan bir şey var.',
    payload: 'reminder_4h',
  );

  static const NotificationContent eightHour = NotificationContent(
    title: 'MindCoach',
    body: 'Her şeyi çözmek zorunda değilsin.',
    payload: 'reminder_8h',
  );

  static const NotificationContent twentyFourHour = NotificationContent(
    title: 'MindCoach',
    body: 'Ara vermen sorun değil...',
    payload: 'reminder_24h',
  );

  /// Get content for specific interval
  static NotificationContent forInterval(int hours) {
    switch (hours) {
      case 2:
        return twoHour;
      case 4:
        return fourHour;
      case 8:
        return eightHour;
      case 24:
        return twentyFourHour;
      default:
        return twoHour;
    }
  }
}

