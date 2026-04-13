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
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
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
    final hasNotifications = ref
        .read(notificationNotifierProvider)
        .notifications
        .isNotEmpty;

    if (!hasNotifications) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.noNotificationsToDelete,
            style: const TextStyle(fontFamily: 'Geist'),
          ),
        ),
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                l10n.deleteAllNotificationsConfirmTitle,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              content: Text(
                l10n.deleteAllNotificationsConfirmMessage,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed) {
      try {
        await ref
            .read(notificationNotifierProvider.notifier)
            .deleteAllNotifications();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.allNotificationsDeleted,
                style: const TextStyle(fontFamily: 'Geist'),
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
                style: const TextStyle(fontFamily: 'Geist'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Silme dialog'unu göster
  Future<bool> _showDeleteDialog(
    BuildContext context,
    int notificationId,
  ) async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                l10n.deleteNotificationConfirmTitle,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              content: Text(
                l10n.deleteNotificationConfirmMessage,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(true);
                    // Bildirimi sil
                    await ref
                        .read(notificationNotifierProvider.notifier)
                        .deleteNotification(notificationId);
                  },
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notificationState = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: kTextTabBarHeight),
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    l10n.notifications,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  // More options menu
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 24,
                      color: Colors.black,
                    ),
                    color: Colors.white,
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
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
              child:
                  notificationState.isLoading &&
                      notificationState.notifications.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2BD383),
                        ),
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
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(notificationNotifierProvider.notifier)
                                  .refresh();
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
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(notificationNotifierProvider.notifier)
                            .refresh();
                      },
                      color: const Color(0xFF2BD383),
                      backgroundColor: Colors.white,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        itemCount: notificationState.notifications.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          final notification =
                              notificationState.notifications[index];
                          return Dismissible(
                            key: Key('notification_${notification.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20.w),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(
                                  16,
                                ), // Figma ile uyumlu
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              // Dialog göster ve kullanıcının onayını al
                              return await _showDeleteDialog(
                                context,
                                notification.id,
                              );
                            },
                            onDismissed: (direction) {
                              // Dialog'da onaylandıysa zaten silindi
                            },
                            child: _NotificationCard(
                              notification: notification,
                            ),
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

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();

      // Aynı gün içindeyse saati göster (Figma: "18:00")
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return DateFormat('HH:mm').format(date);
      }
      // Dün
      else if (now.difference(date).inDays == 1) {
        return 'Dün';
      }
      // Daha eskiyse
      else {
        return DateFormat('dd MMM', 'tr_TR').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // API'den veya metadata'dan appointment olup olmadığını belirle
    final bool isAppointment = notification.type == 'appointment';

    return Container(
      padding: const EdgeInsets.all(12), // Figma Padding: 10px / 12px
      decoration: BoxDecoration(
        color: isAppointment
            ? const Color(0xFF21BC87).withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAppointment
              ? const Color(0xFF21BC87)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: isAppointment
            ? [
                BoxShadow(
                  color: const Color(0xFF2BD383).withValues(alpha: 0.20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.28, // Line height 18px / Size 14px
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (notification.sentTime != null)
                Text(
                  _formatDate(notification.sentTime),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF96989C),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notification.subtitle,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF96989C),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Sadece randevulara özel tıklanabilir link (Figma Card 3)
          if (isAppointment) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // TODO: Randevu detaylarına yönlendir
              },
              child: const Text(
                'Click to view appointment details', // Localize edebilirsin
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF21BC87),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF21BC87),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
