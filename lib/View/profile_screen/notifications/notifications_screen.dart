import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
                            color: Colors.black.withOpacity(0.05),
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
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
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
                            color: Colors.black.withOpacity(0.05),
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
                                style: GoogleFonts.quicksand(
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
                                child: Text(
                                  'Tekrar Dene',
                                  style: GoogleFonts.quicksand(
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
                                    style: GoogleFonts.quicksand(
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

  IconData _getIconForType(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'system_notification':
        return Icons.notifications;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'appointment':
        return const Color(0xFF2BD383);
      case 'system_notification':
        return const Color(0xFF11998E);
      case 'announcement':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF434343);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Az önce';
          }
          return '${difference.inMinutes} dakika önce';
        }
        return '${difference.inHours} saat önce';
      } else if (difference.inDays == 1) {
        return 'Dün';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} gün önce';
      } else {
        return DateFormat('dd MMM yyyy', 'tr_TR').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: _getIconColorForType(notification.type).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForType(notification.type),
              color: _getIconColorForType(notification.type),
              size: 24,
            ),
          ),
          SizedBox(width: 12.w),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  notification.subtitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notification.sentTime != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    _formatDate(notification.sentTime),
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

