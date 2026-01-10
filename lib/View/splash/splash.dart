import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/services/auth_service.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';
import 'package:mindcoach/View/chat_screen/chat_notifier.dart';
import 'package:mindcoach/View/Onboard/onboarding_page.dart';
import 'package:mindcoach/View/profile_setup/presentation/pages/profile_setup_page.dart';
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
    // Splash'de tüm veri çekme işlemlerini yap
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('🚀 [SPLASH] App başlatılıyor...');

    try {
      // 1. Session kontrolü
      final authService = ref.read(authServiceProvider);
      final userModel = await authService.checkSession();

      if (userModel != null) {
        debugPrint('✅ [SPLASH] Session geçerli, kullanıcı: ${userModel.id}');

        // 2. Post-login işlemleri (async, non-blocking)
        _handlePostLoginTasks(userModel);

        // 3. Yönlendirme
        final isGuest = userModel.credential == 'guest';
        final hasCompletedProfile = userModel.answerData != null;

        if (isGuest || hasCompletedProfile) {
          // Misafir kullanıcı veya profil tamamlanmış kullanıcı
          debugPrint('✅ [SPLASH] Authenticated kullanıcı - NavbarShell\'e yönlendiriliyor');
          _navigateToAuthenticated();
        } else {
          // Profil tamamlanmamış normal kullanıcı
          debugPrint('⚠️ [SPLASH] Profil tamamlanmamış - ProfileSetup\'a yönlendiriliyor');
          _navigateToProfileSetup();
        }
      } else {
        // Token yok veya geçersiz
        debugPrint('⚠️ [SPLASH] Session geçersiz veya token yok - Onboarding\'e yönlendiriliyor');
        _navigateToOnboarding();
      }
    } catch (e) {
      debugPrint('❌ [SPLASH] Hata: $e');
      _navigateToOnboarding();
    }
  }

  /// Post-login async işlemleri (non-blocking)
  void _handlePostLoginTasks(userModel) {
    Future.microtask(() async {
      try {
        // 1. Notification service register
        _registerUserForNotifications(userModel.id.toString());

        // 2. Chat'leri yeniden yükle
        _refreshChats();

        // 3. Periodic notifications başlat
        _initializePeriodicNotifications();

        debugPrint('✅ [SPLASH] Post-login işlemleri başlatıldı');
      } catch (e) {
        debugPrint('⚠️ [SPLASH] Post-login işlemleri hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Notification service'e kullanıcıyı kaydet (async, non-blocking)
  void _registerUserForNotifications(String userId) {
    Future.microtask(() async {
      try {
        final notificationService = NotificationService();
        await notificationService.registerUser(userId);
        debugPrint('✅ [SPLASH] Kullanıcı notification service\'e kaydedildi: $userId');
      } catch (e) {
        debugPrint('⚠️ [SPLASH] Notification service kayıt hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Chat'leri yeniden yükle (async, non-blocking)
  void _refreshChats() {
    Future.microtask(() {
      try {
        ref.read(chatProvider.notifier).refreshChats();
        debugPrint('✅ [SPLASH] Chat\'ler yeniden yükleme başlatıldı');
      } catch (e) {
        debugPrint('⚠️ [SPLASH] Chat yenileme hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Initialize periodic notifications (async, non-blocking)
  void _initializePeriodicNotifications() {
    Future.microtask(() async {
      try {
        debugPrint('🔄 [SPLASH] Periodic notifications başlatılıyor...');
        final scheduler = PeriodicNotificationScheduler();
        await scheduler.initializeAndSchedule();
        debugPrint('✅ [SPLASH] Periodic notifications initialized');
      } catch (e) {
        debugPrint('❌ [SPLASH] Error initializing periodic notifications (göz ardı edildi): $e');
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

  /// ProfileSetup'a yönlendir
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

  /// Onboarding'e yönlendir
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