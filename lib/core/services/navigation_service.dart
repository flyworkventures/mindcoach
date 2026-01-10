import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/config/app_status_notifier.dart';
import 'package:mindcoach/models/user_model.dart';
import 'package:mindcoach/Services/NotificationsService/notification_service.dart';
import 'package:mindcoach/View/chat_screen/chat_notifier.dart';


class NavigationService {
  final Ref? ref;

  NavigationService({this.ref});


  Future<void> navigateToAuthenticated(UserModel userModel) async {
    debugPrint('🔄 [NAV-SERVICE] Authenticated\'a yönlendiriliyor...');
    final currentState = ref?.read(appStatusProvider);
    debugPrint('🔄 [NAV-SERVICE] Mevcut state: $currentState');
    

    ref?.read(appStatusProvider.notifier).goToAuthenticated();
    

    final newState = ref?.read(appStatusProvider);
    debugPrint('✅ [NAV-SERVICE] AppStatus authenticated olarak güncellendi: $currentState → $newState');
    

    Future.microtask(() {
      final verifiedState = ref?.read(appStatusProvider);
      if (verifiedState != AppStatus.authenticated) {
        debugPrint('⚠️ [NAV-SERVICE] State doğrulanmadı, tekrar güncelleniyor: $verifiedState');
        ref?.read(appStatusProvider.notifier).goToAuthenticated();
      } else {
        debugPrint('✅ [NAV-SERVICE] State doğrulandı: $verifiedState');
      }
    });

    _handlePostLoginTasks(userModel);
  }


  void navigateToProfileSetup() {
    debugPrint('🔄 [NAV-SERVICE] ProfileSetup\'a yönlendiriliyor...');
    ref?.read(appStatusProvider.notifier).goToProfileSetup();
    debugPrint('✅ [NAV-SERVICE] AppStatus profileSetup olarak güncellendi');
  }

  /// Kullanıcıyı onboarding'e yönlendir
  void navigateToOnboarding() {
    debugPrint('🔄 [NAV-SERVICE] Onboarding\'e yönlendiriliyor...');
    final currentState = ref?.read(appStatusProvider);
    debugPrint('🔄 [NAV-SERVICE] Mevcut state: $currentState');
    
    // ÖNCE AppStatus'u güncelle (navigation için kritik - synchronously)
    ref?.read(appStatusProvider.notifier).goToOnboarding();
    
    // State değişikliğini doğrula
    final newState = ref?.read(appStatusProvider);
    debugPrint('✅ [NAV-SERVICE] AppStatus onboarding olarak güncellendi: $currentState → $newState');
    
    // State değişikliğini zorunlu kıl
    Future.microtask(() {
      final verifiedState = ref?.read(appStatusProvider);
      if (verifiedState != AppStatus.onboarding) {
        debugPrint('⚠️ [NAV-SERVICE] State doğrulanmadı, tekrar güncelleniyor: $verifiedState');
        ref?.read(appStatusProvider.notifier).goToOnboarding();
      } else {
        debugPrint('✅ [NAV-SERVICE] State doğrulandı: $verifiedState');
      }
    });
  }

  /// Kullanıcıyı unauthenticated state'e yönlendir
  void navigateToUnauthenticated() {
    debugPrint('🔄 [NAV-SERVICE] Unauthenticated\'a yönlendiriliyor...');
    ref?.read(appStatusProvider.notifier).goToUnauthenticated();
    debugPrint('✅ [NAV-SERVICE] AppStatus unauthenticated olarak güncellendi');
  }

  /// Post-login async işlemleri (non-blocking)
  void _handlePostLoginTasks(UserModel userModel) {
    Future.microtask(() async {
      try {
        _registerUserForNotifications(userModel.id.toString());

        _refreshChats();
        
     
        debugPrint('[NAV-SERVICE] Post-login işlemleri başlatıldı');
      } catch (e) {
        debugPrint('[NAV-SERVICE] Post-login işlemleri hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Notification service'e kullanıcıyı kaydet (async, non-blocking)
  void _registerUserForNotifications(String userId) {
    Future.microtask(() async {
      try {
        final notificationService = NotificationService();
        await notificationService.registerUser(userId);
        debugPrint('NAV-SERVICE] Kullanıcı notification service\'e kaydedildi: $userId');
      } catch (e) {
        debugPrint('[NAV-SERVICE] Notification service kayıt hatası (göz ardı edildi): $e');
      }
    });
  }

  /// Chat'leri yeniden yükle (async, non-blocking)
  void _refreshChats() {
    Future.microtask(() {
      try {
        ref?.read(chatProvider.notifier).refreshChats();
        debugPrint('[NAV-SERVICE] Chat\'ler yeniden yükleme başlatıldı');
      } catch (e) {
        debugPrint('[NAV-SERVICE] Chat yenileme hatası (göz ardı edildi): $e');
      }
    });
  }
}


final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService(ref: ref);
});
