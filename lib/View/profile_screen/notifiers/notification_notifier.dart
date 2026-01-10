import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsState {
  final bool enabled;
  const NotificationSettingsState({required this.enabled});

  NotificationSettingsState copyWith({bool? enabled}) =>
      NotificationSettingsState(enabled: enabled ?? this.enabled);
}

class NotificationSettingsNotifier extends Notifier<NotificationSettingsState> {
  @override
  NotificationSettingsState build() =>
      const NotificationSettingsState(enabled: true);

  void setEnabled(bool val) => state = state.copyWith(enabled: val);
  void toggle() => state = state.copyWith(enabled: !state.enabled);
}

final notificationSettingsProvider =
NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  NotificationSettingsNotifier.new,
);
