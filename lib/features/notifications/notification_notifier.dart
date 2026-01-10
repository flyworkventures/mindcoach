import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/repo/notification_repo.dart';
import 'package:mindcoach/models/notification_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    required this.notifications,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  NotificationRepo? _notificationRepo;

  NotificationRepo get notificationRepo {
    _notificationRepo ??= NotificationRepo(ref);
    return _notificationRepo!;
  }

  @override
  NotificationState build() {
    // Load notifications when notifier is initialized
    Future(() {
      if (ref.mounted) {
        loadNotifications();
      }
    });
    return NotificationState(notifications: []);
  }

  /// Load notifications from API
  Future<void> loadNotifications({int limit = 50, int offset = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await notificationRepo.getUserNotifications(
        limit: limit,
        offset: offset,
      );
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh notifications
  /// Only updates state if there are actual changes
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newNotifications = await notificationRepo.getUserNotifications(
        limit: 50,
        offset: 0,
      );
      
      // Only update state if notifications actually changed
      final currentIds = state.notifications.map((n) => n.id).toSet();
      final newIds = newNotifications.map((n) => n.id).toSet();
      
      if (currentIds != newIds || state.notifications.length != newNotifications.length) {
        state = state.copyWith(
          notifications: newNotifications,
          isLoading: false,
        );
      } else {
        // No changes, just update loading state
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

