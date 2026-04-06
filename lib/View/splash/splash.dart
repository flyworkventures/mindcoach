import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/View/ProfileSetupView/profile_setup_view.dart';
import 'package:mindcoach/core/services/auth_service.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';
import 'package:mindcoach/View/chat_screen/chat_notifier.dart';
import 'package:mindcoach/View/OnboardView/onboarding_page.dart';
import 'package:mindcoach/app/navbar_shell.dart';

class Splash extends ConsumerStatefulWidget {
  const Splash({super.key});

  @override
  ConsumerState<Splash> createState() => _SplashState();
}

class _SplashState extends ConsumerState<Splash> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    _initialized = true;



    try {
      // 1. Session kontrolü
      final authService = ref.read(authServiceProvider);
      final userModel = await authService.checkSession();

      if (userModel != null) {
  


        _handlePostLoginTasks(userModel);


        final isGuest = userModel.credential == 'guest';
        final hasCompletedProfile = userModel.answerData != null;

        if (isGuest || hasCompletedProfile) {

          debugPrint(' Authenticated kullanıcı - NavbarShell\'e yönlendiriliyor');
          _navigateToAuthenticated();
        } else {

          debugPrint(' Profil tamamlanmamış - ProfileSetup\'a yönlendiriliyor');
          _navigateToProfileSetup();
        }
      } else {

        debugPrint(' Session geçersiz veya token yok - Onboarding\'e yönlendiriliyor');
        _navigateToOnboarding();
      }
    } catch (e) {
      debugPrint(' Hata: $e');
      _navigateToOnboarding();
    }
  }


  void _handlePostLoginTasks(userModel) {
    Future.microtask(() async {
      try {

        _registerUserForNotifications(userModel.id.toString());


        _refreshChats();


        _initializePeriodicNotifications();

        debugPrint('✅ [SPLASH] Post-login işlemleri başlatıldı');
      } catch (e) {
        debugPrint('⚠️ [SPLASH] Post-login işlemleri hatası (göz ardı edildi): $e');
      }
    });
  }



  void _registerUserForNotifications(String userId) {
    Future.microtask(() async {
      try {
        final notificationService = NotificationService();
        await notificationService.registerUser(userId);
        debugPrint(' Kullanıcı notification service\'e kaydedildi: $userId');
      } catch (e) {
        debugPrint(' Notification service kayıt hatası (göz ardı edildi): $e');
      }
    });
  }


  void _refreshChats() {
    Future.microtask(() {
      try {
        ref.read(chatProvider.notifier).refreshChats();
        debugPrint(' Chat\'ler yeniden yükleme başlatıldı');
      } catch (e) {
        debugPrint(' Chat yenileme hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Initialize periodic notifications (async, non-blocking)
  void _initializePeriodicNotifications() {
    Future.microtask(() async {
      try {
        debugPrint(' Periodic notifications başlatılıyor...');
        final scheduler = PeriodicNotificationScheduler();
        await scheduler.initializeAndSchedule();
        debugPrint(' Periodic notifications initialized');
      } catch (e) {
        debugPrint(' Error initializing periodic notifications (göz ardı edildi): $e');
      }
    });
  }

  /// NavbarShell'e yönlendir
  void _navigateToAuthenticated() {
    if (!mounted) return;
    Future.microtask(() {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavbarShell()),
        );
      }
    });
  }


  void _navigateToProfileSetup() {
    if (!mounted) return;
    Future.microtask(() {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MindCoachOnboarding()),
        );
      }
    });
  }


  void _navigateToOnboarding() {
    if (!mounted) return;
    Future.microtask(() {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}