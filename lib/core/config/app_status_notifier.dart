import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/services/auth_service.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';

enum AppStatus {
  onboarding,
  profileSetup,
  authenticated,
  unauthenticated,
  splash
}

final appStatusProvider =
NotifierProvider<AppStatusNotifier, AppStatus>(AppStatusNotifier.new);

class AppStatusNotifier extends Notifier<AppStatus> {
  @override
  AppStatus build() {
    // Başlangıç state'i splash
    return AppStatus.splash;
  }


  Future init() async{
    debugPrint(' [APP-STATUS] Init başlatılıyor... (mevcut state: $state)');

    if (state != AppStatus.splash) {
      debugPrint('[APP-STATUS] Splash state\'te değil ($state), init atlandı');
      return;
    }
    
    // AuthService kullanarak session kontrolü yap (sadece splash state'te)
    final authService = AuthService(ref: ref);
    final userModel = await authService.checkSession();
    
    if (userModel != null) {
      debugPrint(" [APP-STATUS] Session geçerli, kullanıcı: ${userModel.id}");
      
      final isGuest = userModel.credential == 'guest';
      final hasCompletedProfile = userModel.answerData != null;
      
      if (isGuest || hasCompletedProfile) {

        debugPrint(' [APP-STATUS] Authenticated kullanıcı - authenticated\'a yönlendiriliyor (init)');
        setStatus(AppStatus.authenticated);
        

        _initializePeriodicNotifications();
      } else {

        debugPrint(' [APP-STATUS] Profil tamamlanmamış - profileSetup\'a yönlendiriliyor');
        setStatus(AppStatus.profileSetup);
      }
    } else {
      // Token yok veya geçersiz
      debugPrint(' [APP-STATUS] Session geçersiz veya token yok - onboarding\'e yönlendiriliyor');
      setStatus(AppStatus.onboarding);
    }
    
    debugPrint('[APP-STATUS] Init tamamlandı, state: $state');
  }
  
  void goToOnboarding() {
    debugPrint('[APP-STATUS] goToOnboarding çağrıldı (mevcut: $state)');
    final previousState = state;
    
    state = AppStatus.onboarding;
    
    debugPrint('[APP-STATUS] State onboarding olarak güncellendi: $previousState → $state');
    
    // State değişikliğini zorunlu kıl
    Future.microtask(() {
      if (state != AppStatus.onboarding) {
        state = AppStatus.onboarding;
        debugPrint(' [APP-STATUS] State tekrar onboarding olarak güncellendi (microtask): $state');
      }
    });
  }
  
  void goToProfileSetup() {
    debugPrint(' [APP-STATUS] goToProfileSetup çağrıldı (mevcut: $state)');
    state = AppStatus.profileSetup;
    debugPrint(' [APP-STATUS] State profileSetup olarak güncellendi: $state');
  }
  void goToAuthenticated() {
    debugPrint('[APP-STATUS] goToAuthenticated çağrıldı');
    final previousState = state;
    debugPrint(' [APP-STATUS] Mevcut state: $previousState');
    

    state = AppStatus.authenticated;
    
    debugPrint(' [APP-STATUS] State authenticated olarak güncellendi: $previousState → $state');
    

    Future.microtask(() {
      if (state != AppStatus.authenticated) {
        state = AppStatus.authenticated;
        debugPrint(' [APP-STATUS] State tekrar authenticated olarak güncellendi (microtask): $state');
      }
    });
    

    _initializePeriodicNotifications();
  }
  
  void setStatus(AppStatus newStatus) {
    debugPrint(' [APP-STATUS] setStatus çağrıldı: $newStatus (mevcut: $state)');
    state = newStatus;
    debugPrint('[APP-STATUS] State güncellendi: $state');
  }
  void goToUnauthenticated() {
    debugPrint('[APP-STATUS] goToUnauthenticated çağrıldı (mevcut: $state)');
    state = AppStatus.unauthenticated;
    debugPrint('[APP-STATUS] State unauthenticated olarak güncellendi: $state');
  }


  Future<void> _initializePeriodicNotifications() async {
    Future.microtask(() async {
      try {
        debugPrint(' [APP-STATUS] Periodic notifications başlatılıyor...');
        final scheduler = PeriodicNotificationScheduler();
        await scheduler.initializeAndSchedule();
        debugPrint(' [APP-STATUS] Periodic notifications initialized');
      } catch (e) {
        debugPrint(' [APP-STATUS] Error initializing periodic notifications (göz ardı edildi): $e');
      }
    });
  }


}
