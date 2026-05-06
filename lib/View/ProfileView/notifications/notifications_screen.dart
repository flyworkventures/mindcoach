import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mindcoach/View/appointments/appointments_notifier.dart';
import 'package:mindcoach/app/navbar_provider.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/widgets/future_progress_dialog.dart';
import 'package:mindcoach/features/notifications/notification_notifier.dart';
import 'package:mindcoach/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _localizedLoadErrorText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'tr':
        return 'Bildirimler yuklenirken bir hata olustu';
      case 'de':
        return 'Beim Laden der Benachrichtigungen ist ein Fehler aufgetreten';
      case 'es':
        return 'Se produjo un error al cargar las notificaciones';
      case 'fr':
        return 'Une erreur s\'est produite lors du chargement des notifications';
      case 'hi':
        return 'Notifications load karte waqt ek hata hua';
      case 'it':
        return 'Si e verificato un errore durante il caricamento delle notifiche';
      case 'ja':
        return '通知の読み込み中にエラーが発生しました';
      case 'ko':
        return '알림을 불러오는 중 오류가 발생했습니다';
      case 'pt':
        return 'Ocorreu um erro ao carregar as notificacoes';
      case 'ru':
        return 'Произошла ошибка при загрузке уведомлений';
      case 'zh':
        return '加载通知时发生错误';
      default:
        return 'An error occurred while loading notifications';
    }
  }

  String _localizedRetryText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'tr':
        return 'Tekrar dene';
      case 'de':
        return 'Erneut versuchen';
      case 'es':
        return 'Intentar de nuevo';
      case 'fr':
        return 'Reessayer';
      case 'hi':
        return 'Dobara koshish karein';
      case 'it':
        return 'Riprova';
      case 'ja':
        return '再試行';
      case 'ko':
        return '다시 시도';
      case 'pt':
        return 'Tentar novamente';
      case 'ru':
        return 'Повторить';
      case 'zh':
        return '重试';
      default:
        return 'Try Again';
    }
  }

  String _localizedEmptyNotificationsText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'tr':
        return 'Henuz bildiriminiz yok';
      case 'de':
        return 'Sie haben noch keine Benachrichtigungen';
      case 'es':
        return 'Aun no tienes notificaciones';
      case 'fr':
        return 'Vous n\'avez pas encore de notifications';
      case 'hi':
        return 'Aapke paas abhi koi notification nahi hai';
      case 'it':
        return 'Non hai ancora notifiche';
      case 'ja':
        return 'まだ通知はありません';
      case 'ko':
        return '아직 알림이 없습니다';
      case 'pt':
        return 'Voce ainda nao tem notificacoes';
      case 'ru':
        return 'У вас пока нет уведомлений';
      case 'zh':
        return '您还没有通知';
      default:
        return 'You have no notifications yet';
    }
  }

  @override
  void initState() {
    super.initState();
    // Refresh notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).refresh(force: true);
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
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: SvgPicture.asset('assets/icons/ic_bakc.svg'),
                    ),
                  ),
                  SizedBox(width: 4.w),
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
                            _localizedLoadErrorText(context),
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
                                  .refresh(force: true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2BD383),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _localizedRetryText(context),
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
                            _localizedEmptyNotificationsText(context),
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
                            .refresh(force: true);
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
                            onDismissed: (direction) async {
                              await ref
                                  .read(notificationNotifierProvider.notifier)
                                  .deleteNotification(notification.id);
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

class _NotificationCard extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  String _localizedAppointmentDetailsCta(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'tr':
        return 'Randevu detaylarini görmek için dokun';
      case 'de':
        return 'Tippen, um Termindetails anzuzeigen';
      case 'es':
        return 'Toca para ver los detalles de la cita';
      case 'fr':
        return 'Touchez pour voir les details du rendez-vous';
      case 'hi':
        return 'Appointment details dekhne ke liye tap karein';
      case 'it':
        return 'Tocca per vedere i dettagli dell\'appuntamento';
      case 'ja':
        return '予定の詳細を見るにはタップしてください';
      case 'ko':
        return '예약 세부 정보를 보려면 탭하세요';
      case 'pt':
        return 'Toque para ver os detalhes do agendamento';
      case 'ru':
        return 'Нажмите, чтобы посмотреть детали встречи';
      case 'zh':
        return '点击查看预约详情';
      default:
        return 'Tap to view appointment details';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();

      // Aynı gün içindeyse saati göster (Figma: "16:00")
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

  String? _extractPhotoUrl(Map<String, dynamic> metadata) {
    final candidates = <dynamic>[
      metadata['photoUrl'],
      metadata['consultantPhotoUrl'],
      metadata['consultant_photo_url'],
      metadata['consultantPhoto'],
      metadata['guidePhotoUrl'],
    ];

    final consultantObj = metadata['consultant'];
    if (consultantObj is Map<String, dynamic>) {
      candidates.addAll([
        consultantObj['photoURL'],
        consultantObj['photoUrl'],
        consultantObj['avatar'],
      ]);
    }

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  AppointmentInfo? _findAppointmentById(WidgetRef ref, int appointmentId) {
    final map = ref.read(appointmentsProvider).appointments;
    for (final infos in map.values) {
      for (final info in infos) {
        if (info.appointmentId == appointmentId) return info;
      }
    }
    return null;
  }

  Future<void> _openAppointmentWithLoading(
    BuildContext context,
    WidgetRef ref,
    int? appointmentId,
  ) async {
    if (appointmentId == null) return;
    await context.runWithProgressDialog(() async {
      await ref.read(appointmentsProvider.notifier).refresh();
      if (!context.mounted) return;
      final info = _findAppointmentById(ref, appointmentId);
      if (info == null) return;
      final appointmentDate = info.appointmentDateTime;
      if (appointmentDate == null) return;
      ref
          .read(selectedCalendarDateProvider.notifier)
          .setDate(appointmentDate);
      ref.read(bottomNavProvider.notifier).setTab(2);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }, message: context.l10n.pleaseWait);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metaType = notification.metadata['type'] as String? ?? '';
    final bool isAppointment =
        metaType == 'appointment' ||
        metaType == 'appointment_cancelled' ||
        metaType == 'appointment_reactivated';

    // ----------------------------------------------------
    // RANDEVU (APPOINTMENT) BİLDİRİMİ İÇİN ÖZEL TASARIM
    // ----------------------------------------------------
    if (isAppointment) {
      final photoUrl = _extractPhotoUrl(notification.metadata);
      final appointmentIdRaw = notification.metadata['appointmentId'];
      final appointmentId = appointmentIdRaw is int
          ? appointmentIdRaw
          : int.tryParse(appointmentIdRaw?.toString() ?? '');

      return GestureDetector(
        onTap: () => _openAppointmentWithLoading(context, ref, appointmentId),
        child: Container(
          padding: const EdgeInsets.all(10), // Figma Padding: 10px
          decoration: BoxDecoration(
            color: const Color(0xFF21BC87).withValues(alpha: 0.10), // %10 Yeşil
            borderRadius: BorderRadius.circular(16), // Figma Radius: 16px
            border: Border.all(
              color: const Color(
                0xFF21BC87,
              ).withValues(alpha: 0.5), // 1px Yeşil Border
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    memCacheWidth: 120,
                    memCacheHeight: 120,
                    placeholder: (_, _) => const SizedBox(
                      width: 60,
                      height: 60,
                      child: ColoredBox(color: Color(0x1421BC87)),
                    ),
                    errorWidget: (_, _, _) => const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF21BC87),
                      size: 28,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF21BC87),
                  size: 28,
                ),
              const SizedBox(width: 10),
              Expanded(
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
                              height: 18 / 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (notification.sentTime != null)
                          Text(
                            _formatDate(notification.sentTime),
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF96989C),
                            ),
                          ),
                      ],
                    ),
                    if (notification.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _localizedAppointmentDetailsCta(context),
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF21BC87),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF21BC87),
                        height: 14 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------
    // STANDART (DİĞER) BİLDİRİMLER İÇİN TASARIM
    // ----------------------------------------------------
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
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
                    height: 1.28,
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
          if (notification.subtitle.isNotEmpty)
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
        ],
      ),
    );
  }
}
