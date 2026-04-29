import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/features/notifications/notification_notifier.dart';
import 'package:mindcoach/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notificationState = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: const BoxDecoration(
               color: Colors.white
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF434343),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    l10n.notifications,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // Refresh button
                  GestureDetector(
                    onTap: () {
                      ref.read(notificationNotifierProvider.notifier).refresh();
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: notificationState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2BD383),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                              size: 20,
                              color: Color(0xFF434343),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: notificationState.isLoading && notificationState.notifications.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2BD383)),
                      ),
                    )
                  : notificationState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Bildirimler yüklenirken bir hata oluştu',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(notificationNotifierProvider.notifier).refresh();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2BD383),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Tekrar Dene',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : notificationState.notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Henüz bildiriminiz yok',
                                    style: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await ref.read(notificationNotifierProvider.notifier).refresh();
                              },
                              color: const Color(0xFF2BD383),
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                                itemCount: notificationState.notifications.length,
                                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                                itemBuilder: (context, index) {
                                  final notification = notificationState.notifications[index];
                                  return _NotificationCard(notification: notification);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  bool get _isAppointment {
    final metaType = notification.metadata['type'] as String? ?? '';
    return metaType == 'appointment' ||
        metaType == 'appointment_cancelled' ||
        metaType == 'appointment_reactivated';
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAppt = _isAppointment;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAppt
            ? const Color(0xFF21BC87).withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAppt ? const Color(0xFF21BC87) : const Color(0xFFE3E3E3),
          width: 1,
        ),
        boxShadow: isAppt
            ? [
                BoxShadow(
                  color: const Color(0xFF2BD383).withValues(alpha: 0.20),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content — fills remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: bold 14px, black
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 18 / 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle: medium 12px; green+underline for appointments, gray for others
                Text(
                  notification.subtitle,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isAppt
                        ? const Color(0xFF21BC87)
                        : const Color(0xFF8C8C8C),
                    height: 14 / 12,
                    decoration: isAppt
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor:
                        isAppt ? const Color(0xFF21BC87) : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Time — HH:mm on the top-right
          if (notification.sentTime != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatTime(notification.sentTime),
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF96989C),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

