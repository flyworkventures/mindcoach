import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_notification/in_app_notification.dart';


class InAppNotificationService {
  static void showWelcomeNotification(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration duration = const Duration(seconds: 3),
  }) {
    InAppNotification.show(
      child: _WelcomeNotificationCard(
        title: title,
        subtitle: subtitle,
      ),
      context: context,
      duration: duration,
      onTap: () {
      },
    );
  }


  static void showAppointmentNotification(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    InAppNotification.show(
      child: _AppointmentNotificationCard(
        title: title,
        subtitle: subtitle,
      ),
      context: context,
      duration: duration,
      onTap: onTap,
    );
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

  const _AppointmentNotificationCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(top: 20,right: 15,left: 15),
      shape: RoundedRectangleBorder(
        
        borderRadius: BorderRadius.circular(20)
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style:  GoogleFonts.quicksand(
                      color: Color(0xff2BD383),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    
                    style: GoogleFonts.quicksand(
                      color: Colors.black.withOpacity(0.9),
                      fontSize: 14,
                      decoration: TextDecoration.underline
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.arrow_right,color: Colors.black,)
          ],
        ),
      ),
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

