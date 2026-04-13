import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Services/NotificationsService/in_app_notification_service.dart';
import '../View/HomeView/home_screen.dart';
import '../View/calendar_screen/calendar_screen.dart';
import '../View/chat_screen/presentation/pages/chat_screen.dart';
import '../View/profile_screen/presentation/profile_screen.dart';
import '../View/specialists_screen/specialists_screen.dart';
import '../features/notifications/notification_notifier.dart';
import 'navbar_provider.dart';

class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});

  @override
  ConsumerState<BottomNavBar> createState() => _NavbarShellState();
}

class _NavbarShellState extends ConsumerState<BottomNavBar>
    with WidgetsBindingObserver {
  final Set<int> _shownNotificationIds = {};
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });

    // Set up periodic notification check (every 30 seconds)
    _startNotificationTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app comes to foreground, refresh notifications
    if (state == AppLifecycleState.resumed) {
      _refreshNotifications();
    }
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        //   _refreshNotifications();
      }
    });
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;

    try {
      // Refresh notifications - ref.listen will automatically trigger _checkAndShowNotifications
      // if there are new notifications
      await ref.read(notificationNotifierProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    }
  }

  void _checkAndShowNotifications() {
    if (!mounted) return;

    final notificationState = ref.read(notificationNotifierProvider);
    final notifications = notificationState.notifications;
    final now = DateTime.now();

    // Show only new notifications that haven't been shown yet AND are recent (within last 10 minutes)
    int newNotificationsShown = 0;
    for (final notification in notifications) {
      if (!_shownNotificationIds.contains(notification.id)) {
        // Check if it's an appointment notification
        if (notification.metadata['type'] == 'appointment') {
          // Check if notification is recent (within last 10 minutes)
          if (notification.sentTime != null) {
            try {
              final sentTime = DateTime.parse(notification.sentTime!);
              final timeDifference = now.difference(sentTime);

              // Only show notifications created within the last 10 minutes
              if (timeDifference.inMinutes > 10) {
                // Too old, mark as shown but don't display
                _shownNotificationIds.add(notification.id);
                debugPrint(
                  '⏭️ Skipping old notification (${timeDifference.inMinutes} minutes old): ${notification.id}',
                );
                continue;
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing notification sentTime: $e');
              // If we can't parse the time, skip it
              _shownNotificationIds.add(notification.id);
              continue;
            }
          } else {
            // No sentTime, skip it
            _shownNotificationIds.add(notification.id);
            continue;
          }

          // Show the notification
          InAppNotificationService.showAppointmentNotification(
            context,
            title: notification.title,
            subtitle: notification.subtitle,
            duration: const Duration(seconds: 4),
          );
          _shownNotificationIds.add(notification.id);
          newNotificationsShown++;
        }
      }
    }

    if (newNotificationsShown > 0) {
      debugPrint(
        '✅ Shown $newNotificationsShown new appointment notification(s)',
      );
    }
  }

  static const List<Widget> _pages = [
    HomeScreen(),
    SpecialistsScreen(),
    CalendarScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  static const List<String> _iconAssets = [
    'assets/icons/ic_home.svg',
    'assets/icons/ic_coaches.svg',
    'assets/icons/ic_calander.svg',
    'assets/icons/ic_chat.svg',
    'assets/icons/ic_profile.svg',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavProvider);

    // Listen to notification changes and show new ones ONLY when new notifications are added
    ref.listen<NotificationState>(notificationNotifierProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;

      // Only check if there are actually new notifications
      if (previous == null) {
        // First load - DON'T show old notifications, only mark them as seen
        for (final notification in next.notifications) {
          if (notification.metadata['type'] == 'appointment') {
            _shownNotificationIds.add(notification.id);
          }
        }
      } else {
        // Check if new notifications were added (by comparing IDs)
        final previousIds = previous.notifications.map((n) => n.id).toSet();
        final nextIds = next.notifications.map((n) => n.id).toSet();
        final newIds = nextIds.difference(previousIds);

        // Only show notifications if there are actually new ones
        if (newIds.isNotEmpty) {
          _checkAndShowNotifications();
        }
      }
    });

    return Scaffold(
      extendBody: true, // Sayfa içeriğinin navbar altına kadar inmesini sağlar
      backgroundColor: Colors.white,
      body: _pages[selectedIndex],
      bottomNavigationBar: _bottomNavBar(selectedIndex),
    );
  }

  Widget _bottomNavBar(int selectedIndex) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // Sabit height kaldırıldı. Yüksekliği içindeki ikon + padding belirleyecek.
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Color(0xFFE8E8E8), // 0.5px border
                width: 0.5,
              ),
            ),
          ),
          // SafeArea alt kısımdaki çentik/home indicator boşluğunu otomatik verir
          child: SafeArea(
            child: Padding(
              // Üstteki gereksiz boşluğu almak için top: 6 (veya 4) verebilirsin.
              // Alt boşluk bottom: 6 ile dengelendi.
              padding: const EdgeInsets.only(top: 6, left: 10, right: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_iconAssets.length, (index) {
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        ref.read(bottomNavProvider.notifier).setTab(index);
                      },
                      child: Center(
                        child: SvgPicture.asset(
                          _iconAssets[index],
                          width: 44, // İkonlar istediğin gibi 44x44
                          height: 44,
                          colorFilter: ColorFilter.mode(
                            isSelected
                                ? const Color(0xFF21BC87)
                                : const Color(0xFF898989),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
