import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';

/// Notification Preferences Model
/// Manages user preferences for periodic notifications
class NotificationPreferences {
  final LocalDbService _localDbService = LocalDbService();

  // Notification IDs for different intervals
  static const int id2Hours = 1001;
  static const int id4Hours = 1002;
  static const int id8Hours = 1003;
  static const int id24Hours = 1004;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final enabled = await _localDbService.getBool(key: LocalDbKeys.notificationsEnabled);
    return enabled ?? true; // Default: enabled
  }

  /// Set notifications enabled/disabled
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _localDbService.setBool(key: LocalDbKeys.notificationsEnabled, value: enabled);
  }

  /// Check if specific interval notification is enabled
  Future<bool> isIntervalEnabled(int hours) async {
    final key = _getIntervalKey(hours);
    final enabled = await _localDbService.getBool(key: key);
    return enabled ?? true; // Default: enabled
  }

  /// Set specific interval notification enabled/disabled
  Future<void> setIntervalEnabled(int hours, bool enabled) async {
    final key = _getIntervalKey(hours);
    await _localDbService.setBool(key: key, value: enabled);
  }

  /// Get notification start time (when user first enabled notifications)
  Future<DateTime?> getStartTime() async {
    final timestamp = await _localDbService.getInt(key: LocalDbKeys.notificationStartTime);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Set notification start time
  Future<void> setStartTime(DateTime time) async {
    await _localDbService.setInt(
      key: LocalDbKeys.notificationStartTime,
      value: time.millisecondsSinceEpoch,
    );
  }

  /// Get key for interval preference
  String _getIntervalKey(int hours) {
    switch (hours) {
      case 2:
        return LocalDbKeys.notification2Hours;
      case 4:
        return LocalDbKeys.notification4Hours;
      case 8:
        return LocalDbKeys.notification8Hours;
      case 24:
        return LocalDbKeys.notification24Hours;
      default:
        return LocalDbKeys.notification2Hours;
    }
  }

  /// Get notification ID for interval
  static int getIdForInterval(int hours) {
    switch (hours) {
      case 2:
        return id2Hours;
      case 4:
        return id4Hours;
      case 8:
        return id8Hours;
      case 24:
        return id24Hours;
      default:
        return id2Hours;
    }
  }
}

