import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Services/NotificationsService/in_app_notification_service.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';
import 'package:mindcoach/View/chat_screen/chat_notifier.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/routes/page_routes.dart';
import '../../../../app/navbar_shell.dart';
import '../../../../View/profile_setup/presentation/pages/profile_setup_page.dart';
import '../../../../View/Onboard/onboarding_page.dart';
import '../../../../models/user_model.dart';
import '../../auth_di.dart';
import '../../domain/social_login_provider.dart';
import '../../domain/auth_repository.dart';

/// AuthController
/// ----------------
/// - UI ile domain/data katmanı arasında köprü görevi görür
/// - UI, auth işlemlerini **doğrudan repository veya datasource üzerinden yapmaz**
/// - AsyncValue kullanarak loading / error / success durumlarını yönetir
///
/// ⚠️ ÖNEMLİ:
/// - Bu controller, **auth’un nasıl yapıldığını bilmez**
/// - Google / Apple / Fake / N8N farkı burada yoktur
/// - Yarın N8NAuthDataSource geldiğinde:
///     → Sadece data layer değişir
///     → Controller ve UI birebir aynı kalır
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    // Başlangıçta herhangi bir işlem yok
    // UI bu state’i dinleyerek loading/error gösterebilir
    return const AsyncData(null);
  }

  /// Repository erişimi
  /// Controller, concrete implementation bilmez
  /// (Fake mi, N8N mi → auth_di karar verir)
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  
  /// Auth Service - Session yönetimi için
  AuthService get _authService => ref.read(authServiceProvider);
  
  /// Navigation Service - Navigation yönetimi için
  NavigationService get _navigationService => ref.read(navigationServiceProvider);

  /// Sosyal login işlemi
  ///
  /// Akış:
  /// 1) UI login çağırır
  /// 2) Repository → DataSource (token ve user bilgisi kaydedilir, UserProvider güncellenir)
  /// 3) UserProvider'dan user bilgisini al
  /// 4) Kullanıcıyı uygun ekrana yönlendir
  ///
  /// UI tarafı sadece state ve AppStatus değişimini izler
  Future<void> login(SocialLoginProvider provider, BuildContext context) async {
    state = const AsyncLoading();
    try {
      debugPrint('🚀 [AUTH-CONTROLLER] Login başlatılıyor: ${provider.name}');
      
      // 1. Login işlemi (token ve user bilgisi kaydedilir, UserProvider güncellenir)
      await _repo.loginWithSocial(provider);
      debugPrint('✅ [AUTH-CONTROLLER] Login API çağrısı tamamlandı');

      // 2. UserProvider'dan user bilgisini al (login response'unda zaten set edildi)
      // Birkaç kez deneme yap (UserProvider güncellemesi async olabilir)
      UserModel? userModel;
      for (int i = 0; i < 5; i++) {
        userModel = ref.read(userProvider);
        if (userModel != null) {
          debugPrint('✅ [AUTH-CONTROLLER] Kullanıcı UserProvider\'dan alındı: ${userModel.id}');
          break;
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      if (userModel == null) {
        // Eğer UserProvider'da user yoksa, token ile verify et (fallback)
        debugPrint('⚠️ [AUTH-CONTROLLER] UserProvider\'da user yok, token ile verify ediliyor...');
        final token = await _authService.getToken();
        if (token == null) {
          throw Exception('Token not found after login');
        }
        final verifiedUser = await _authService.verifyAndSetUser(token);
        if (verifiedUser == null) {
          throw Exception('User verification failed');
        }
        debugPrint('✅ [AUTH-CONTROLLER] Kullanıcı token ile doğrulandı: ${verifiedUser.id}');
        userModel = verifiedUser;
      }
      
      // 3. Navigation ve post-login işlemleri
      _navigateAfterLogin(userModel, context);
      
      // State'i güncelle (UI loading state'i kaldırmak için)
      state = const AsyncData(null);
      debugPrint('✅ [AUTH-CONTROLLER] Login tamamlandı');
      
    } catch (e, st) {
      debugPrint('❌ [AUTH-CONTROLLER] Login hatası: $e');
      debugPrint('❌ [AUTH-CONTROLLER] Stack trace: $st');
      
      state = AsyncError(e, st);
      
      // Hata durumunda onboarding'e yönlendir
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          PageRoutes.onboarding,
          (route) => false,
        );
        debugPrint('✅ [AUTH-CONTROLLER] Hata sonrası onboarding\'e yönlendirildi');
      }
    }
  }
  
  /// Login sonrası navigation ve post-login işlemleri
  void _navigateAfterLogin(UserModel userModel, BuildContext context) {
    // Navigation - Kullanıcıyı uygun ekrana yönlendir
    final isGuest = userModel.credential == 'guest';
    final hasCompletedProfile = userModel.answerData != null;
    
    debugPrint('🔵 [AUTH-CONTROLLER] Login sonrası kontrol:');
    debugPrint('🔵 [AUTH-CONTROLLER] credential: ${userModel.credential}');
    debugPrint('🔵 [AUTH-CONTROLLER] isGuest: $isGuest');
    debugPrint('🔵 [AUTH-CONTROLLER] hasCompletedProfile: $hasCompletedProfile');
    
    // Post-login işlemleri (async, non-blocking)
    _handlePostLoginTasks(userModel);
    
    // Yönlendirme
    if (isGuest || hasCompletedProfile) {
      // Misafir kullanıcı veya profil tamamlanmış kullanıcı
      debugPrint('✅ [AUTH-CONTROLLER] Authenticated\'a yönlendiriliyor');
      
      // Hoşgeldiniz bildirimi göster (navigation'dan önce)
      if (context.mounted) {
        _showWelcomeNotificationIfNeeded(context);
      }
      
      // Direkt NavbarShell'e yönlendir
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavbarShell()),
        );
        debugPrint('✅ [AUTH-CONTROLLER] NavbarShell\'e yönlendirildi');
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
    final user = ref.read(userProvider);
    if (user != null) {
      final username = user.username ?? 'Kullanıcı';
      InAppNotificationService.showWelcomeNotification(
        context,
        title: 'Hoş Geldiniz! 👋',
        subtitle: 'Merhaba $username, MindCoach\'a hoş geldiniz!',
        duration: const Duration(seconds: 4),
      );
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
        debugPrint('⚠️ [AUTH-CONTROLLER] Post-login işlemleri hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Notification service'e kullanıcıyı kaydet (async, non-blocking)
  void _registerUserForNotifications(String userId) {
    Future.microtask(() async {
      try {
        final notificationService = NotificationService();
        await notificationService.registerUser(userId);
        debugPrint('✅ [AUTH-CONTROLLER] Kullanıcı notification service\'e kaydedildi: $userId');
      } catch (e) {
        debugPrint('⚠️ [AUTH-CONTROLLER] Notification service kayıt hatası (göz ardı edildi): $e');
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
        debugPrint('⚠️ [AUTH-CONTROLLER] Chat yenileme hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Initialize periodic notifications (async, non-blocking)
  void _initializePeriodicNotifications() {
    Future.microtask(() async {
      try {
        debugPrint('🔄 [AUTH-CONTROLLER] Periodic notifications başlatılıyor...');
        final scheduler = PeriodicNotificationScheduler();
        await scheduler.initializeAndSchedule();
        debugPrint('✅ [AUTH-CONTROLLER] Periodic notifications initialized');
      } catch (e) {
        debugPrint('❌ [AUTH-CONTROLLER] Error initializing periodic notifications (göz ardı edildi): $e');
      }
    });
  }
  /// Logout işlemi
  ///
  /// - Repository → Logout API çağrısı
  /// - AuthService → Session temizle
  /// - Direkt Onboarding'e yönlendir
  Future<void> logout(BuildContext context) async {
    debugPrint('🔴 [AUTH-CONTROLLER] Logout başlatılıyor...');
    state = const AsyncLoading();
    try {
      // 1. Logout API çağrısı (hata olsa bile devam et)
      try {
        await _repo.logout();
        debugPrint('✅ [AUTH-CONTROLLER] Logout API çağrısı tamamlandı');
      } catch (e) {
        debugPrint('⚠️ [AUTH-CONTROLLER] Logout API hatası (göz ardı edildi): $e');
      }

      // 2. Session'ı temizle (ÖNEMLİ: Her zaman yapılmalı)
      await _authService.clearSession();
      debugPrint('✅ [AUTH-CONTROLLER] Session temizlendi');

      // 3. Direkt Onboarding'e yönlendir
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false, // Tüm önceki route'ları temizle
        );
        debugPrint('✅ [AUTH-CONTROLLER] Onboarding\'e yönlendirildi');
      }
      
      // State'i güncelle
      state = const AsyncData(null);
      debugPrint('✅ [AUTH-CONTROLLER] Logout tamamlandı');
      
    } catch (e, st) {
      debugPrint('❌ [AUTH-CONTROLLER] Logout hatası: $e');
      debugPrint('❌ [AUTH-CONTROLLER] Stack trace: $st');
      
      // Hata olsa bile session'ı temizle ve onboarding'e yönlendir
      try {
        await _authService.clearSession();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            (route) => false, // Tüm önceki route'ları temizle
          );
          debugPrint('✅ [AUTH-CONTROLLER] Hata sonrası session temizlendi ve onboarding\'e yönlendirildi');
        }
      } catch (cleanupError) {
        debugPrint('❌ [AUTH-CONTROLLER] Cleanup hatası: $cleanupError');
      }
      
      state = AsyncError(e, st);
    }
  }

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
