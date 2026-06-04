import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Repositories/auth_repositories.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/core/routes/page_routes.dart';

class SplashController extends StateNotifier {
  Ref? ref;
  SplashController(this.ref) : super(0);

Future init() async {
    try {
      final authService = AuthRepositories(ref: ref);

      // 1. İşlemleri paralel başlatıyoruz: Hem session kontrolü hem de 2.5 saniye bekleme.
      // Bu sayede session kontrolü çok hızlı bitse bile (örneğin token yoksa),
      // uygulama yönlendirme yapmak için 2.5 saniyenin dolmasını bekleyecek.
      final results = await Future.wait([
        authService.checkSession(),
        Future.delayed(
          const Duration(milliseconds: 2500),
        ), // Minimum bekleme süremiz
      ]);

      // results[0] authService.checkSession()'dan dönen değerdir
      final userModel = results[0];

      final providerModel = ref?.read(AllProviders.userProvider);
      debugPrint("PROVİDER: ${providerModel?.username}");

      if (providerModel != null) {
        await AnalyticsService.instance.capture(
          AnalyticsEvents.sessionRestored,
          properties: {
            // user_id event'e eklenmez (PII); kullanıcı kimliği
            // hemen ardından gelen identifyUser çağrısıyla PostHog'a iletilir.
            'auth_method': providerModel.credential ?? 'unknown',
            'has_completed_profile': providerModel.answerData != null,
          },
        );
        await AnalyticsService.instance.identifyUser(
          userId: providerModel.id,
          credential: providerModel.credential,
          hasCompletedProfile: providerModel.answerData != null,
        );
        _handlePostLoginTasks(userModel);

        final isGuest = providerModel.credential == 'guest';
        final hasCompletedProfile = providerModel.answerData != null;

        if (isGuest || hasCompletedProfile) {
          _navigateToAuthenticated();
        } else {
          _navigateToProfileSetup();
        }
      } else {
        _navigateToOnboarding();
      }
    } catch (e) {
      Logger.errorLog(
        text: "hata $e",
        className: "SplashController",
        functionName: "init",
      );
      _navigateToOnboarding();
    }
  }

  void _registerUserForNotifications(String userId) {
    Future.microtask(() async {
      try {
        final notificationService = NotificationService();
        await notificationService.registerUser(userId);
        Logger.info(
          text: "Kullanıcı notification service'e kaydedildi: $userIdı",
          className: "SplashController",
          functionName: "_registerUserForNotifications",
        );
      } catch (e) {
        Logger.errorLog(
          text: "Notification service kayıt hatası (göz ardı edildi): $e",
          className: "SplashController",
          functionName: "_registerUserForNotifications",
        );
      }
    });
  }

  void _refreshChats() {
    Future.microtask(() {
      try {
        //   ref?.read(chatProvider.notifier).refreshChats();
        Logger.info(
          text: "Chat'ler yeniden yükleme başlatıldı",
          className: "SplashController",
          functionName: "_refreshChats",
        );
      } catch (e) {
        Logger.errorLog(
          text: "Chat yenileme hatası (göz ardı edildi): $e",
          className: "SplashController",
          functionName: "_refreshChats",
        );
      }
    });
  }

  /// Initialize periodic notifications (async, non-blocking)
  void _initializePeriodicNotifications() {
    Future.microtask(() async {
      try {
        final scheduler = PeriodicNotificationScheduler();
        await scheduler.initializeAndSchedule();
        Logger.info(
          text: "Periyodik bildirimler hazırlandı",
          className: "SplashController",
          functionName: "_initializePeriodicNotifications",
        );
      } catch (e) {
        Logger.info(
          text:
              "Error initializing periodic notifications (göz ardı edildi): $e",
          className: "SplashController",
          functionName: "_initializePeriodicNotifications",
        );
      }
    });
  }

  /// BottomNavBar'e yönlendir
  void _navigateToAuthenticated() {
    if (!mounted) return;
    Future.microtask(() {
      if (mounted) {
        Logger.info(
          text: "Authenticated kullanıcı - BottomNavBar'e yönlendiriliyor",
          className: "SplashController",
          functionName: "_navigateToAuthenticated",
        );
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          PageRoutes.navbar,
          (a) => false,
        );
      }
    });
  }

  void _navigateToProfileSetup() async {
    Logger.info(
      text: "Profil tamamnlanmamış. ProfileSetupView'e yönlendiriliyor",
      className: "SplashController",
      functionName: "_navigateToAuthenticated",
    );
    await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      PageRoutes.profileSetup,
      (a) => false,
    );
    //   Navigator.pushAndRemoveUntil(context, newRoute, predicate)
  }

  void _navigateToOnboarding() async {
    Logger.info(
      text: "Onbaording'e yönlendiriliyor",
      className: "SplashController",
      functionName: "_navigateToOnboarding",
    );
    await navigatorKey.currentState?.pushNamedAndRemoveUntil(
      PageRoutes.onboarding,
      (a) => false,
    );
  }

  void _handlePostLoginTasks(userModel) {
    Future.microtask(() async {
      try {
        _registerUserForNotifications(userModel.id.toString());

        _refreshChats();

        _initializePeriodicNotifications();
        Logger.info(
          text: "Post-login işlemleri başlatıldı'",
          className: "SplashController",
          functionName: "_handlePostLoginTasks",
        );
      } catch (e) {
        Logger.errorLog(
          text: "Post-login işlemleri hatası (göz ardı edildi): $e",
          className: "SplashController",
          functionName: "_handlePostLoginTasks",
        );
      }
    });
  }
}
