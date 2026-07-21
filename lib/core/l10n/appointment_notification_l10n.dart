import 'package:flutter/material.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/models/notification_model.dart';

/// Randevu bildirimlerini uygulama dilinde gösterir (backend metnini değil).
class AppointmentNotificationL10n {
  static String? consultantNameFromMetadata(Map<String, dynamic> metadata) {
    final candidates = <dynamic>[
      metadata['consultantName'],
      metadata['specialistName'],
    ];

    final consultantObj = metadata['consultant'];
    if (consultantObj is Map<String, dynamic>) {
      candidates.addAll([
        consultantObj['name'],
        consultantObj['displayName'],
      ]);
    }

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  static bool isAppointmentNotification(NotificationModel notification) {
    final metaType = notification.metadata['type'] as String? ?? '';
    return metaType == 'appointment' ||
        metaType == 'appointment_cancelled' ||
        metaType == 'appointment_reactivated';
  }

  static ({String title, String subtitle}) resolve(
    BuildContext context,
    NotificationModel notification,
  ) {
    if (!isAppointmentNotification(notification)) {
      return (title: notification.title, subtitle: notification.subtitle);
    }

    final metaType = notification.metadata['type'] as String? ?? '';
    final name =
        consultantNameFromMetadata(notification.metadata) ??
        context.l10n.appointmentReminderFallbackName;
    final l10n = context.l10n;

    switch (metaType) {
      case 'appointment':
        return (
          title: l10n.notifAppointmentCreatedTitle,
          subtitle: l10n.notifAppointmentCreatedSubtitle(name),
        );
      case 'appointment_cancelled':
        return (
          title: l10n.notifAppointmentCancelledTitle,
          subtitle: l10n.notifAppointmentCancelledSubtitle,
        );
      case 'appointment_reactivated':
        return (
          title: l10n.notifAppointmentReactivatedTitle,
          subtitle: l10n.notifAppointmentReactivatedSubtitle,
        );
      default:
        return (title: notification.title, subtitle: notification.subtitle);
    }
  }
}
