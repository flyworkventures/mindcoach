import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Services/Analytics/analytics_service.dart';
import '../Services/NotificationsService/in_app_notification_service.dart';
import '../core/analytics/analytics_events.dart';
import '../View/HomeView/home_screen.dart';
import '../View/appointments/appointments_notifier.dart';
import '../View/calendar_screen/calendar_screen.dart';
import '../View/chat_screen/chat_notifier.dart';
import '../View/chat_screen/presentation/pages/chat_screen.dart';
import '../View/profile_screen/presentation/profile_screen.dart';
import '../View/specialists_screen/specialists_screen.dart';
import '../core/utils/premium_sync.dart';
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
  Timer? _chatRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // İlk yükleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRealtimeData();
    });

    // Bildirimleri sık ama hafif aralıkla kontrol et (anlık yakın deneyim).
    _startNotificationTimer();
    // Chat: her 60 saniyede bir yenile
    _startChatRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationTimer?.cancel();
    _chatRefreshTimer?.cancel();
    super.dispose();
  }
  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      _refreshRealtimeData();
    });
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Uygulama ön plana gelince bildirim + chat + premium durumunu yenile
    if (state == AppLifecycleState.resumed) {
      _refreshRealtimeData();
      // Premium durumunu backend ile tazele: kullanıcı uygulama açıkken
      // abonelik süresi dolduysa / iptal edildiyse anında yansısın.
      unawaited(syncPremiumFromBackend(ref));
      try {
        ref.read(chatProvider.notifier).refreshChats();
      } catch (e) {
        debugPrint('Chat yenileme hatası (lifecycle): $e');
      }
    }
  }

  void _startChatRefreshTimer() {
    _chatRefreshTimer?.cancel();
    _chatRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        try {
          // Chat API çağrılarını azaltmak için yalnızca Chat tab'ındayken yenile.
          final selectedIndex = ref.read(bottomNavProvider);
          if (selectedIndex == 3) {
            ref.read(chatProvider.notifier).refreshChats();
          }
        } catch (e) {
          debugPrint('Chat yenileme hatası: $e');
        }
      }
    });
  }

  Future<void> _refreshRealtimeData() async {
    if (!mounted) return;

    try {
      // Polling yok; sadece app acilisi/foreground aninda yenilenir.
      await ref.read(notificationNotifierProvider.notifier).refresh(force: true);
    } catch (e) {
      debugPrint('Error refreshing realtime data: $e');
    }
  }

  String _localizedAppointmentDetailsCta(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'tr':
        return 'Randevu detaylarini gormek icin dokun';
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

  String _withCalendarEmoji(String title) {
    final trimmed = title.trimLeft();
    if (trimmed.startsWith('🗓️')) return title;
    return '🗓️ $title';
  }

  String? _extractConsultantPhotoUrl(Map<String, dynamic> metadata) {
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

  void _handleAppointmentNotificationTap() {
    if (!mounted) return;
    // Randevu bildirimi tiklandiginda Takvim sekmesine yonlendir.
    ref.read(bottomNavProvider.notifier).setTab(2);
  }

  void _checkAndShowNotifications() {
    if (!mounted) return;

    final notificationState = ref.read(notificationNotifierProvider);
    final notifications = notificationState.notifications;
    final now = DateTime.now();
    bool shouldRefreshAppointments = false;

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

          // metadata'dan ek bilgileri çek
          final photoUrl = _extractConsultantPhotoUrl(notification.metadata);
          final appointmentType =
              notification.metadata['appointmentType'] as String? ?? '';
          final isMissed =
              appointmentType == 'missed' ||
              notification.title.toLowerCase().contains('not attend') ||
              notification.title.toLowerCase().contains('katılmadın') ||
              notification.title.toLowerCase().contains('katılmadınız');

          // Show the notification
          InAppNotificationService.showAppointmentNotification(
            context,
            title: _withCalendarEmoji(notification.title),
            subtitle: _localizedAppointmentDetailsCta(context),
            duration: const Duration(seconds: 5),
            onTap: _handleAppointmentNotificationTap,
            photoUrl: photoUrl,
            isMissed: isMissed,
          );
          if (!isMissed) {
            shouldRefreshAppointments = true;
          }
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

    if (shouldRefreshAppointments) {
      ref.read(appointmentsProvider.notifier).refresh();
    }
  }

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
    final selectedCalendarDate = ref.watch(selectedCalendarDateProvider);
    final pages = <Widget>[
      const HomeScreen(),
      const SpecialistsScreen(),
      CalendarScreen(initialSelectedDate: selectedCalendarDate),
      const ChatScreen(),
      const ProfileView(),
    ];

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
      body: pages[selectedIndex],
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
                        if (selectedIndex != index) {
                          const tabNames = [
                            'home',
                            'specialists',
                            'calendar',
                            'chat',
                            'profile',
                          ];
                          AnalyticsService.instance.capture(
                            AnalyticsEvents.tabSelected,
                            properties: {
                              'tab_index': index,
                              'tab_name': tabNames[index],
                            },
                          );
                        }
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
