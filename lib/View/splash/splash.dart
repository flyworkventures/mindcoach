import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';
import 'package:mindcoach/Services/RevenueCatService/revenuecat_service.dart';
import 'package:mindcoach/View/OnboardView/onboarding_page.dart';
import 'package:mindcoach/View/ProfileSetupView/profile_setup_view.dart';
import 'package:mindcoach/View/chat_screen/chat_notifier.dart';
import 'package:mindcoach/app/navbar_shell.dart';
import 'package:mindcoach/core/services/auth_service.dart';

import '../../Services/NotificationsService/local_notification_service.dart';

class Splash extends ConsumerStatefulWidget {
  const Splash({super.key});

  @override
  ConsumerState<Splash> createState() => _SplashState();
}

class _SplashState extends ConsumerState<Splash>
    with SingleTickerProviderStateMixin {
  bool _initialized = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ─── Auth check & yönlendirme ───────────────────────────────────

  Future<void> _initializeApp() async {
    if (_initialized) return;
    _initialized = true;

    // Kronometreyi başlat
    final stopwatch = Stopwatch()..start();

    // 1. Hem Auth kontrolünü hem de harici servis kurulumlarını aynı anda (paralel) başlat
    final results = await Future.wait([_checkAuth(), _initExternalServices()]);

    final route = results[0] as _SplashRoute;

    // 2. Kronometreyi kontrol et.
    // İşlemler ne kadar sürerse sürsün, toplam süreyi en az 2500 milisaniyeye (2.5 saniye) tamamla.
    final elapsed = stopwatch.elapsedMilliseconds;
    final remainingTime = 2500 - elapsed;

    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }

    stopwatch.stop();

    if (!mounted) return;

    // 3. Yönlendirmeyi yap
    switch (route) {
      case _SplashRoute.authenticated:
        _navigateToAuthenticated();
        break;
      case _SplashRoute.profileSetup:
        _navigateToProfileSetup();
        break;
      case _SplashRoute.onboarding:
        _navigateToOnboarding();
        break;
    }
  }

  // main.dart'tan taşıdığımız servis başlatma işlemleri
  Future<void> _initExternalServices() async {
    try {
      await RevenuecatService().initializeRevenueCat();
    } catch (e) {
      debugPrint('RevenueCat başlatma hatası: $e');
    }

    try {
      final notificationService = NotificationService();
      await notificationService.initiializeOnesignal();
    } catch (e) {
      debugPrint('OneSignal başlatma hatası: $e');
    }

    try {
      final localNotificationService = LocalNotificationService();
      await localNotificationService.initialize();
    } catch (e) {
      debugPrint('LocalNotification başlatma hatası: $e');
    }
  }

  Future<_SplashRoute> _checkAuth() async {
    try {
      final authService = ref.read(authServiceProvider);
      final userModel = await authService.checkSession();

      if (userModel != null) {
        _handlePostLoginTasks(userModel);

        final isGuest = userModel.credential == 'guest';
        final hasCompletedProfile = userModel.answerData != null;

        if (isGuest || hasCompletedProfile) {
          debugPrint(
            ' Authenticated kullanıcı - NavbarShell\'e yönlendiriliyor',
          );
          return _SplashRoute.authenticated;
        } else {
          debugPrint(' Profil tamamlanmamış - ProfileSetup\'a yönlendiriliyor');
          return _SplashRoute.profileSetup;
        }
      } else {
        debugPrint(
          ' Session geçersiz veya token yok - Onboarding\'e yönlendiriliyor',
        );
        return _SplashRoute.onboarding;
      }
    } catch (e) {
      debugPrint(' Hata: $e');
      return _SplashRoute.onboarding;
    }
  }

  // ─── Post-login görevleri ───────────────────────────────────────

  void _handlePostLoginTasks(dynamic userModel) {
    Future.microtask(() async {
      try {
        _registerUserForNotifications(userModel.id.toString());
        _refreshChats();
        _initializePeriodicNotifications();
        debugPrint('✅ [SPLASH] Post-login işlemleri başlatıldı');
      } catch (e) {
        debugPrint(
          '⚠️ [SPLASH] Post-login işlemleri hatası (göz ardı edildi): $e',
        );
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

  void _initializePeriodicNotifications() {
    Future.microtask(() async {
      try {
        debugPrint(' Periodic notifications başlatılıyor...');
        final scheduler = PeriodicNotificationScheduler();
        await scheduler.initializeAndSchedule();
        debugPrint(' Periodic notifications initialized');
      } catch (e) {
        debugPrint(
          ' Error initializing periodic notifications (göz ardı edildi): $e',
        );
      }
    });
  }

  // ─── Navigation ─────────────────────────────────────────────────

  void _navigateToAuthenticated() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const BottomNavBar()));
  }

  void _navigateToProfileSetup() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MindCoachOnboarding()),
    );
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  // ─── UI ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2BD383), // üst – açık yeşil
              Color(0xFF1FA86A), // alt – koyu yeşil
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // ── "mindcoach" logo text ──
              Positioned(
                top: MediaQuery.of(context).size.height * 0.12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'mindcoach',
                    style: GoogleFonts.quicksand(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),

              // ── Lyra karakter (ortada, biraz aşağıda) ──
              Positioned(
                bottom: -5,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/chars/char2_nobg.png',
                    height: MediaQuery.of(context).size.height * 0.85,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ── "Take a moment for yourself." text ──
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Take a moment for yourself.',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SplashRoute { authenticated, profileSetup, onboarding }
