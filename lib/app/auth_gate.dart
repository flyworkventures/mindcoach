import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/View/SplashView/splash_view.dart';

import '../core/config/app_status_notifier.dart';
import '../View/OnboardView/onboarding_page.dart';
import '../View/ProfileSetupView/profile_setup_view.dart';
import '../View/BottomNavBar/bottom_nav_bar.dart';



class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});
  

  @override
  ConsumerState<AuthGate> createState() => AuthGateState();
}



class AuthGateState extends ConsumerState<AuthGate> {
  bool _initialized = false;
  AppStatus? _lastStatus;
  
  @override
  void initState() {
    super.initState();
    // Sadece ilk kez init çağrılmalı (logout sonrası rebuild'de tekrar çağrılmamalı)
    // Ama logout sonrası login yapıldığında state zaten NavigationService tarafından güncelleniyor
    // Bu yüzden init() sadece app ilk açıldığında çağrılmalı
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() {
        if (mounted) {
          ref.read(appStatusProvider.notifier).init();
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ref.watch kullanarak state'i dinle - her state değişikliğinde rebuild olur
    final status = ref.watch(appStatusProvider);
    
    // State değişikliğini logla
    if (_lastStatus != status) {
      debugPrint('🔄 [AUTH-GATE] State değişti: $_lastStatus → $status');
      _lastStatus = status;
    }
    
    // Debug log - state değişikliklerini takip et
    debugPrint('🔄 [AUTH-GATE] Build çağrıldı, status: $status');
    
    // State değişikliğini zorunlu kıl (ref.watch bazen state değişikliğini algılamayabilir)
    // ref.listen kullanarak state değişikliğini dinle ve rebuild'i tetikle
    ref.listen<AppStatus>(appStatusProvider, (previous, next) {
      debugPrint('🔄 [AUTH-GATE] State değişikliği algılandı (listen): $previous → $next');
      if (mounted && previous != next) {
        // State değiştiğinde rebuild'i zorla (hemen, synchronously)
        // postFrameCallback kullanmadan direkt setState çağır
        setState(() {
          _lastStatus = next;
          debugPrint('🔄 [AUTH-GATE] setState çağrıldı, yeni status: $next');
        });
      }
    });

    switch (status) {
      case AppStatus.onboarding:
        debugPrint('📱 [AUTH-GATE] OnboardingScreen gösteriliyor');
        return const OnboardingScreen();

      case AppStatus.profileSetup:
        debugPrint('📱 [AUTH-GATE] MindCoachOnboarding gösteriliyor');
        return const MindCoachOnboarding();

      case AppStatus.authenticated:
        debugPrint('📱 [AUTH-GATE] BottomNavBar gösteriliyor');
        return const BottomNavBar();

      case AppStatus.unauthenticated:
        debugPrint('📱 [AUTH-GATE] OnboardingScreen gösteriliyor (unauthenticated)');
        // TODO: LoginScreen
        return const OnboardingScreen();
      case AppStatus.splash:
        debugPrint('📱 [AUTH-GATE] Splash gösteriliyor');
        // TODO: LoginScreen
        return const Splash(); // hasanrevize
    }
  
  }
}
