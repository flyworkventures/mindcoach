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

  /// Tüm bildirimleri silme dialog'unu göster
  Future<void> _showDeleteAllDialog(BuildContext context) async {
    final l10n = context.l10n;
    final hasNotifications = ref.read(notificationNotifierProvider).notifications.isNotEmpty;
    
    if (!hasNotifications) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.noNotificationsToDelete,
            style: GoogleFonts.quicksand(),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.deleteAllNotificationsConfirmTitle,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: Text(
            l10n.deleteAllNotificationsConfirmMessage,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.delete,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmed) {
      try {
        await ref.read(notificationNotifierProvider.notifier).deleteAllNotifications();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.allNotificationsDeleted,
                style: GoogleFonts.quicksand(),
              ),
              backgroundColor: const Color(0xFF2BD383),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.errorDeletingNotifications,
                style: GoogleFonts.quicksand(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Silme dialog'unu göster
  Future<bool> _showDeleteDialog(BuildContext context, int notificationId) async {
    final l10n = context.l10n;
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.deleteNotificationConfirmTitle,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: Text(
            l10n.deleteNotificationConfirmMessage,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                // Bildirimi sil
                await ref.read(notificationNotifierProvider.notifier).deleteNotification(notificationId);
              },
              child: Text(
                l10n.delete,
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notificationState = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: Color(0xffF2F5FC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: const BoxDecoration(
               color: Color(0xffF2F5FC)
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
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // More options menu
                  PopupMenuButton<String>(
                    icon: Container(
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
                        Icons.more_horiz,
                        size: 20,
                        color: Color(0xFF434343),
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'delete_all') {
                        await _showDeleteAllDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              context.l10n.deleteAllNotifications,
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                                  return Dismissible(
                                    key: Key('notification_${notification.id}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.only(right: 20.w),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      // Dialog göster ve kullanıcının onayını al
                                      return await _showDeleteDialog(context, notification.id);
                                    },
                                    onDismissed: (direction) {
                                      // Dialog'da onaylandıysa zaten silindi
                                    },
                                    child: _NotificationCard(notification: notification),
                                  );
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
        borderRadius: BorderRadius.circular(24),
        
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 12,
            offset:  Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
  
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
                    fontWeight: FontWeight.w800,
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
               
              ],
            ),
            
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
    );
  }
}

