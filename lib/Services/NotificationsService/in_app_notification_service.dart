import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:in_app_notification/in_app_notification.dart';

/// Bildirim kuyruğu için model
class _NotificationItem {
  final String title;
  final String subtitle;
  final Duration duration;
  final VoidCallback? onTap;
  final bool isAppointment;
  final String? photoUrl;
  final bool isMissed;

  _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    this.onTap,
    required this.isAppointment,
    this.photoUrl,
    this.isMissed = false,
  });
}

class InAppNotificationService {
  // Bildirim kuyruğu
  static final List<_NotificationItem> _notificationQueue = [];
  static bool _isShowingNotification = false;
  static Timer? _currentNotificationTimer;

  /// Bildirim göster (kuyruğa ekle)
  static void _showNextNotification(BuildContext context) async{
    if (_isShowingNotification || _notificationQueue.isEmpty) {
      return;
    }

    _isShowingNotification = true;
    final notification = _notificationQueue.removeAt(0);

    Widget notificationCard;
    if (notification.isAppointment) {
      notificationCard = _AppointmentNotificationCard(
        title: notification.title,
        subtitle: notification.subtitle,
        photoUrl: notification.photoUrl,
        isMissed: notification.isMissed,
      );
    } else {
      notificationCard = _WelcomeNotificationCard(
        title: notification.title,
        subtitle: notification.subtitle,
      );
    }
    final audioPlayer =AudioPlayer();
    await audioPlayer.play(AssetSource("sounds/notification.wav"));
     InAppNotification.show(
      child: notificationCard,
      context: context,
      duration: notification.duration,
      onTap: notification.onTap,
    );

    // Bildirim süresi bittikten sonra bir sonraki bildirimi göster
    _currentNotificationTimer = Timer(notification.duration + const Duration(milliseconds: 300), () {
      _isShowingNotification = false;
      _currentNotificationTimer?.cancel();
      _currentNotificationTimer = null;
      
      // Bir sonraki bildirimi göster (eğer varsa)
      if (_notificationQueue.isNotEmpty && context.mounted) {
        _showNextNotification(context);
      }
    });
  }

  static void showWelcomeNotification(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    _notificationQueue.add(_NotificationItem(
      title: title,
      subtitle: subtitle,
      duration: duration,
      isAppointment: false,
    ));
    
    _showNextNotification(context);
  }

  static void showAppointmentNotification(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
    String? photoUrl,
    bool isMissed = false,
  }) {
    _notificationQueue.add(_NotificationItem(
      title: title,
      subtitle: subtitle,
      duration: duration,
      onTap: onTap,
      isAppointment: true,
      photoUrl: photoUrl,
      isMissed: isMissed,
    ));

    _showNextNotification(context);
  }

  static void showCustomNotification(
    BuildContext context, {
    required Widget child,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    InAppNotification.show(
      child: child,
      context: context,
      duration: duration,
      onTap: onTap,
    );
  }
}


class _AppointmentNotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? photoUrl;
  final bool isMissed;

  const _AppointmentNotificationCard({
    required this.title,
    required this.subtitle,
    this.photoUrl,
    this.isMissed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 14, right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Sol: koç fotoğrafı (varsa)
              if (photoUrl != null && photoUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderIcon(),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Orta: başlık + alt yazı
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF21BC87),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF21BC87),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Sağ: ikon
              if (isMissed)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FBF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF21BC87),
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFE8FBF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.calendar_today_rounded,
          color: Color(0xFF21BC87), size: 24),
    );
  }
}


class _WelcomeNotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WelcomeNotificationCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
     // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30),bottomRight: Radius.circular(30)),
         color: Colors.white
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.waving_hand,
                color: Colors.greenAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

