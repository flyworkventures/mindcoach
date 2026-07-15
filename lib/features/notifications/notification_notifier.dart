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
  bool _isRefreshing = false;
  DateTime? _lastRefreshAt;
  static const Duration _minRefreshInterval = Duration(seconds: 90);

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

  static List<NotificationModel> _inboxOnly(List<NotificationModel> list) {
    return list.where((n) {
      if (n.type == 'chat_message') return false;
      final trigger = n.metadata['trigger']?.toString();
      if (trigger == 'therapist_message') return false;
      final metaType = n.metadata['type']?.toString();
      if (metaType == 'chat_message') return false;
      return true;
    }).toList();
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
        notifications: _inboxOnly(notifications),
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
  Future<void> refresh({bool force = false}) async {
    final now = DateTime.now();
    final recentlyRefreshed =
        _lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < _minRefreshInterval;

    if (_isRefreshing || (!force && recentlyRefreshed)) return;

    _isRefreshing = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fetched = await notificationRepo.getUserNotifications(
        limit: 50,
        offset: 0,
      );
      final newNotifications = _inboxOnly(fetched);

      // Only update state if notifications actually changed
      final currentIds = state.notifications.map((n) => n.id).toSet();
      final newIds = newNotifications.map((n) => n.id).toSet();

      if (currentIds != newIds ||
          state.notifications.length != newNotifications.length) {
        state = state.copyWith(
          notifications: newNotifications,
          isLoading: false,
        );
      } else {
        // No changes, just update loading state
        state = state.copyWith(isLoading: false);
      }
      _lastRefreshAt = DateTime.now();
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    } finally {
      _isRefreshing = false;
    }
  }

  /// Bildirimi sil
  Future<void> deleteNotification(int id) async {
    try {
      final success = await notificationRepo.deleteNotification(id);
      if (success) {
        // Bildirimi listeden kaldır
        final updatedNotifications = state.notifications
            .where((notification) => notification.id != id)
            .toList();
        state = state.copyWith(notifications: updatedNotifications);
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Tüm bildirimleri sil
  Future<void> deleteAllNotifications() async {
    try {
      final success = await notificationRepo.deleteAllNotifications();
      if (success) {
        // Tüm bildirimleri listeden kaldır
        state = state.copyWith(notifications: []);
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final notificationNotifierProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

