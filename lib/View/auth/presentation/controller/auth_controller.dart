import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';
import 'package:mindcoach/View/chat_screen/chat_notifier.dart';
import 'package:mindcoach/app/navbar_shell.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../models/user_model.dart';
import '../../../ProfileSetupView/profile_setup_view.dart';
import '../../auth_di.dart';
import '../../domain/auth_repository.dart';

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  AuthService get _authService => ref.read(authServiceProvider);

  NavigationService get _navigationService =>
      ref.read(navigationServiceProvider);

  void _navigateAfterLogin(UserModel userModel, BuildContext context) {
    final isGuest = userModel.credential == 'guest';
    final hasCompletedProfile = userModel.answerData != null;

    debugPrint('🔵 [AUTH-CONTROLLER] Login sonrası kontrol:');
    debugPrint('🔵 [AUTH-CONTROLLER] credential: ${userModel.credential}');
    debugPrint('🔵 [AUTH-CONTROLLER] isGuest: $isGuest');
    debugPrint(
      '🔵 [AUTH-CONTROLLER] hasCompletedProfile: $hasCompletedProfile',
    );

    _handlePostLoginTasks(userModel);

    if (isGuest || hasCompletedProfile) {
      // Misafir kullanıcı veya profil tamamlanmış kullanıcı
      debugPrint('✅ [AUTH-CONTROLLER] Authenticated\'a yönlendiriliyor');

      // Hoşgeldiniz bildirimi göster (navigation'dan önce)
      if (context.mounted) {
        _showWelcomeNotificationIfNeeded(context);
      }

      // Direkt BottomNavBar'e yönlendir
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomNavBar()),
        );
        debugPrint('✅ [AUTH-CONTROLLER] BottomNavBar\'e yönlendirildi');
      }
    } else {
      // Profil tamamlanmamış normal kullanıcı
      debugPrint('⚠️ [AUTH-CONTROLLER] ProfileSetup\'a yönlendiriliyor');

      // Direkt ProfileSetup'a yönlendir
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MindCoachOnboarding()),
        );
        debugPrint('✅ [AUTH-CONTROLLER] ProfileSetup\'a yönlendirildi');
      }
    }
  }

  void _showWelcomeNotificationIfNeeded(BuildContext context) {
    final user = ref.read(AllProviders.userProvider);
    if (user != null) {
      final username = user.username ?? 'Kullanıcı';
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

        debugPrint('✅ [AUTH-CONTROLLER] Post-login işlemleri başlatıldı');
      } catch (e) {
        debugPrint(
          '⚠️ [AUTH-CONTROLLER] Post-login işlemleri hatası (göz ardı edildi): $e',
        );
      }
    });
  }

  /// Notification service'e kullanıcıyı kaydet (async, non-blocking)
  void _registerUserForNotifications(String userId) {
    Future.microtask(() async {
      try {
        final notificationService = NotificationService();
        await notificationService.registerUser(userId);
        debugPrint(
          '✅ [AUTH-CONTROLLER] Kullanıcı notification service\'e kaydedildi: $userId',
        );
      } catch (e) {
        debugPrint(
          '⚠️ [AUTH-CONTROLLER] Notification service kayıt hatası (göz ardı edildi): $e',
        );
      }
    });
  }

  /// Chat'leri yeniden yükle (async, non-blocking)
  void _refreshChats() {
    Future.microtask(() {
      try {
        ref.read(chatProvider.notifier).refreshChats();
        debugPrint('✅ [AUTH-CONTROLLER] Chat\'ler yeniden yükleme başlatıldı');
      } catch (e) {
        debugPrint(
          '⚠️ [AUTH-CONTROLLER] Chat yenileme hatası (göz ardı edildi): $e',
        );
      }
    });
  }

  /// Initialize periodic notifications (async, non-blocking)
  void _initializePeriodicNotifications() {
    Future.microtask(() async {
      try {
        debugPrint(
          '🔄 [AUTH-CONTROLLER] Periodic notifications başlatılıyor...',
        );
        final scheduler = PeriodicNotificationScheduler();
        await scheduler.initializeAndSchedule();
        debugPrint('✅ [AUTH-CONTROLLER] Periodic notifications initialized');
      } catch (e) {
        debugPrint(
          '❌ [AUTH-CONTROLLER] Error initializing periodic notifications (göz ardı edildi): $e',
        );
      }
    });
  }

  /// Logout işlemi
  ///
  /// - Repository → Logout API çağrısı
  /// - AuthService → Session temizle
  /// - Direkt Onboarding'e yönlendir

  /// Delete account işlemi
  ///
  /// - Repository → Delete account API çağrısı
  /// - AuthService → Session temizle
  /// - NavigationService → Unauthenticated'a yönlendir
  Future<void> deleteAccount() async {
    debugPrint('🗑️ [AUTH-CONTROLLER] Delete account başlatılıyor...');
    state = const AsyncLoading();
    try {
      // 1. Delete account API çağrısı
      await _repo.deleteAccount();
      debugPrint('✅ [AUTH-CONTROLLER] Delete account API çağrısı tamamlandı');

      // 2. Session'ı temizle
      await _authService.clearSession();
      debugPrint('✅ [AUTH-CONTROLLER] Session temizlendi');

      // 3. Unauthenticated'a yönlendir
      _navigationService.navigateToUnauthenticated();

      state = const AsyncData(null);
      debugPrint('✅ [AUTH-CONTROLLER] Delete account tamamlandı');
    } catch (e, st) {
      debugPrint('❌ [AUTH-CONTROLLER] Delete account hatası: $e');

      // Hata olsa bile session'ı temizle
      await _authService.clearSession();
      _navigationService.navigateToUnauthenticated();

      state = AsyncError(e, st);
    }
  }
}

/// Provider
/// --------
/// UI katmanı bu provider üzerinden controller’a erişir
/// Controller singleton mantığında çalışır
final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
