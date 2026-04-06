import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/HomeView/home_view.dart';
import 'package:mindcoach/core/routes/page_routes.dart';

import '../calendar_screen/calendar_screen.dart';
import '../chat_screen/presentation/pages/chat_screen.dart';
import '../HomeView/home_screen.dart';
import '../ProfileView/profile_view.dart';
import '../specialists_screen/specialists_screen.dart';
import '../../Services/NotificationsService/in_app_notification_service.dart';
import '../../features/notifications/notification_notifier.dart';
import '../../app/navbar_provider.dart';

class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> with WidgetsBindingObserver {
  final Set<int> _shownNotificationIds = {};
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(()=> ref.read(AllControllers.homeController.notifier).getMotivationText());

    WidgetsBinding.instance.addObserver(this);
     showWelcomeNotification();
    Future.delayed(Duration(seconds: 7)).then((a){
          // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });

    // Set up periodic notification check (every 30 seconds)
    _startNotificationTimer();
     
     
    });
    
  }


void showWelcomeNotification()async{


   InAppNotificationService.showWelcomeNotification(
        context,
        title: 'Hoş Geldiniz! 👋',
        subtitle: 'Merhaba ${ref.read(AllProviders.userProvider)?.username}, MindCoach\'a hoş geldiniz!',
        duration: const Duration(seconds: 4),
      );
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
        _refreshNotifications();
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

  void _checkAndShowNotifications() async{
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
                debugPrint('⏭️ Skipping old notification (${timeDifference.inMinutes} minutes old): ${notification.id}');
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

  AudioPlayer audioPlayer = AudioPlayer();
  await audioPlayer.play(AssetSource('sounds/notification.wav'));
          InAppNotificationService.showAppointmentNotification(
            onTap: () {
                 Navigator.pushNamed(context, PageRoutes.notifications);
            },
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
      debugPrint('✅ Shown $newNotificationsShown new appointment notification(s)');
    }
  }

  static const List<Widget> _pages = [
    HomeView(),
    SpecialistsScreen(),
    CalendarScreen(),
    ChatScreen(),
    ProfileView(),
  ];

  static const List<String> _iconAssets = [
    'assets/svg/home_icon.svg',
    'assets/svg/specialists_icon.svg',
    'assets/svg/calendar_icon.svg',
    'assets/svg/chat_icon.svg',
    'assets/svg/profile_icon.svg',
  ];

  static const List<Size> _iconSizes = [
    Size(20, 20),
    Size(24, 24),
    Size(24, 24),
    Size(24, 24),
    Size(24, 24),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavProvider);
    /*


    // Chat provider'ı watch et - authenticated olduğunda chat'leri yeniden yükle
    ref.listen(chatProvider, (previous, next) {
      // İlk yüklemede veya authenticated olduğunda chat'leri yeniden yükle
      if (previous == null || (previous.chats.isEmpty && next.chats.isEmpty && !next.isLoading)) {
        // Chat'leri yeniden yükle
        Future.microtask(() {
          if (mounted) {
            ref.read(chatProvider.notifier).refreshChats();
          }
        });
      }
    });


    */

    // Listen to notification changes and show new ones ONLY when new notifications are added
    ref.listen<NotificationState>(
      notificationNotifierProvider,
      (previous, next) {
        if (!mounted) return;
        
        // Only check if there are actually new notifications
        if (previous == null) {
          // First load - DON'T show old notifications, only mark them as seen
          // This prevents showing 3-hour-old notifications when app opens
          for (final notification in next.notifications) {
            if (notification.metadata['type'] == 'appointment') {
              // Mark all existing notifications as shown (don't display them)
              _shownNotificationIds.add(notification.id);
            }
          }
          debugPrint('📋 Marked ${next.notifications.length} existing notifications as seen (not showing old ones)');
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
      },
    );

    return Scaffold(
      extendBody: true,
      body: _pages[selectedIndex],
      bottomNavigationBar: _bottomNavBar(selectedIndex),
    );
  }

  Widget _bottomNavBar(int selectedIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_iconAssets.length, (index) {
              final isSelected = selectedIndex == index;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      ref.read(bottomNavProvider.notifier).setTab(index),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SvgPicture.asset(
                      _iconAssets[index],
                      width: _iconSizes[index].width,
                      height: _iconSizes[index].height,
                      colorFilter: ColorFilter.mode(
                        isSelected ? Colors.teal : Colors.grey,
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
    );
  }
}
