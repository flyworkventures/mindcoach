import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_notification/in_app_notification.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Riverpod/Providers/premium_provider.dart';
import 'package:mindcoach/Services/ApiService/premium_api_service.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/View/splash/splash.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/device_utils.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:mindcoach/models/premium_state.dart';
import 'package:mindcoach/models/user_model.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/config/size_config.dart';
import '../core/locale/locale_provider.dart';
import '../core/routes/app_router.dart';
import '../l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final Future<String> _premiumInitFuture;
  bool _processingPurchase = false;
  CustomerInfoUpdateListener? _customerInfoListener;
  String? _analyticsDistinctId;
  bool _premiumHydrated = false;

  @override
  void initState() {
    super.initState();
    // App ömrü boyunca premium init işlemini tek sefer çalıştır.
    _premiumInitFuture = _initializePremiumOnLaunch(ref);
  }

  @override
  void dispose() {
    final listener = _customerInfoListener;
    if (listener != null) {
      Purchases.removeCustomerInfoUpdateListener(listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize premium provider with device ID and check status
    ref.listen(premiumProvider, (previous, next) {
      debugPrint(
        '🔐 Premium status: ${next.isPremium}, Days: ${next.daysRemaining}',
      );
      _trackPremiumAnalytics(previous, next);
    });

    // Auth state transitions → align RevenueCat identity + re-sync premium.
    ref.listen<UserModel?>(AllProviders.userProvider, (previous, next) {
      final prevId = previous?.id;
      final nextId = next?.id;
      if (prevId == nextId) return;
      if (nextId != null) {
        _analyticsDistinctId = nextId.toString();
        unawaited(_identifyUserForAnalytics(next!));
        _handleAuthLogin(nextId);
      } else {
        _handleAuthLogout();
        _resetAnalyticsIdentity();
      }
    });

    final locale = ref.watch(localeProvider);
    // Gerçek locale kodunu göster (sistem locale dahil)
    final currentLanguageCode = ref
        .read(localeProvider.notifier)
        .getLanguageCode();
    debugPrint("Locale: $currentLanguageCode");

    return FutureBuilder<String>(
      future: _premiumInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MindCoach',
          navigatorKey: navigatorKey,
          navigatorObservers: [
            if (AnalyticsService.instance.isEnabled) PosthogObserver(),
          ],
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          //routes: AppRouter.routes,
          home: const Splash(),
          onGenerateRoute: AppRouter.generateRoute,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2BD383),
            ),
            textTheme: GoogleFonts.quicksandTextTheme(),
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
          ),
          builder: (context, child) {
            SizeConfig.init(context);
            return InAppNotification(child: child!);
          },
        );
      },
    );
  }

  /// Initialize premium provider with device ID and check status on app launch
  Future<String> _initializePremiumOnLaunch(WidgetRef ref) async {
    try {
      // Get or create device ID
      final deviceId = await DeviceUtils.getDeviceId();
      _analyticsDistinctId = 'device_$deviceId';

      final loggedInUser = ref.read(AllProviders.userProvider);
      if (loggedInUser?.id != null) {
        _analyticsDistinctId = loggedInUser!.id.toString();
        await _identifyUserForAnalytics(loggedInUser);
      }

      // Initialize premium provider with device ID
      final initialState = PremiumState.initial(deviceId: deviceId);

      // Update the provider with loaded state
      ref.read(premiumProvider.notifier).setPremiumState(initialState);

      // Check and update premium status from local storage first
      await ref.read(premiumProvider.notifier).checkPremiumStatus();
      debugPrint('✅ Loaded local premium status for device: $deviceId');

      // Sync with backend: get current premium status from server.
      // await ile bekliyoruz ki backend cevabı geldikten SONRA RevenueCat
      // kontrolü çalışsın. Böylece RevenueCat son sözü söyler.
      await _syncPremiumWithBackend(deviceId, ref);

      // RevenueCat satın alma / restore event'lerini dinle.
      _registerPurchaseListener(deviceId, ref);

      // RevenueCat'ten mevcut entitlement'ları proaktif kontrol et.
      // Backend sync'ten SONRA çalışır → RevenueCat'te aktif satın alma
      // varsa backend'in "premium yok" kararını override eder.
      await _checkExistingEntitlements(deviceId, ref);

      _premiumHydrated = true;
      return deviceId;
    } catch (e) {
      debugPrint('⚠️ Error initializing premium: $e');
      _premiumHydrated = true;
      return 'unknown';
    }
  }

  /// RevenueCat CustomerInfo değişimlerini dinler.
  /// Satın alma tamamlanır tamamlanmaz tetiklenir (paywall close beklenmez).
  /// App açılışında RevenueCat'ten mevcut entitlement'ları kontrol et.
  /// Listener sadece değişiklik olduğunda tetiklenir; bu metod mevcut
  /// satın almaları yakalar (ör. backend sync başarısız olduysa).
  Future<void> _checkExistingEntitlements(String deviceId, WidgetRef ref) async {
    try {
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active.isNotEmpty) {
        debugPrint('🔍 RevenueCat: mevcut aktif entitlement bulundu, işleniyor...');
        await _handleCustomerInfoUpdate(info, deviceId, ref);
      }
    } catch (e) {
      debugPrint('⚠️ RevenueCat entitlement check failed (non-blocking): $e');
    }
  }

  void _registerPurchaseListener(String deviceId, WidgetRef ref) {
    listener(CustomerInfo info) {
      _handleCustomerInfoUpdate(info, deviceId, ref);
    }

    _customerInfoListener = listener;
    Purchases.addCustomerInfoUpdateListener(listener);
    debugPrint('🔔 RevenueCat CustomerInfo listener kaydedildi.');
  }

  Future<void> _handleCustomerInfoUpdate(
    CustomerInfo info,
    String deviceId,
    WidgetRef ref,
  ) async {
    if (_processingPurchase) return;
    try {
      _processingPurchase = true;

      final activeEntitlements = info.entitlements.active;
      final notifier = ref.read(premiumProvider.notifier);
      final currentState = ref.read(premiumProvider);

      if (activeEntitlements.isEmpty) {
        // RC sadece POZİTİF sinyalle hareket etsin. Boş entitlement geçici
        // bir state olabilir (Purchases.logIn esnasında anonim→user geçişi
        // sırasında RC kısa süre boş CustomerInfo fırlatabiliyor).
        // Refund/iptal durumunda backend bir sonraki /initialize sync'inde
        // isPremium=false döner ve _applyBackendStatusToLocal local'i temizler.
        debugPrint(
          'ℹ️ RevenueCat entitlement bos — locale dokunmuyoruz '
          '(backend sync source-of-truth).',
        );
        return;
      }

      // İlk aktif entitlement'ı kullan.
      final entitlement = activeEntitlements.values.first;
      final expiryStr = entitlement.expirationDate;
      final expiryDate = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
      final productId = entitlement.productIdentifier;
      final receipt = info.originalAppUserId;

      // Aynı satın almayı tekrar tekrar işlememek için: zaten satın alındı
      // işaretliyse ve expiry değişmediyse no-op.
      if (currentState.isPurchased &&
          currentState.expiryDate != null &&
          expiryDate != null &&
          currentState.expiryDate!.isAtSameMomentAs(expiryDate)) {
        return;
      }

      // 1) Local premium'u aktive et (anında UI güncellensin).
      // premiumProvider state değişimi → ref.listen → trackPremiumTransition
      // → premium_purchased event'ini tek noktadan ateşler. Burada manuel
      // capture etmiyoruz (duplicate olurdu).
      await notifier.activatePurchasedPremium(expiryDate: expiryDate);
      debugPrint(
        '✅ Local premium aktive edildi (purchased, expiry=$expiryDate, product=$productId).',
      );

      // 2) Backend'i bilgilendir (best-effort, başarısız olsa app çalışmaya devam).
      try {
        final currentUserId = ref.read(AllProviders.userProvider)?.id;
        await PremiumApiService().confirmPurchase(
          deviceId: deviceId,
          userId: currentUserId,
          receiptData: receipt,
          packageIdentifier: productId,
        );
        debugPrint('✅ Backend confirmPurchase başarılı (userId=$currentUserId).');
      } catch (e) {
        debugPrint('⚠️ Backend confirmPurchase başarısız (non-blocking): $e');
      }
    } catch (e) {
      debugPrint('⚠️ CustomerInfo update işlenirken hata: $e');
    } finally {
      _processingPurchase = false;
    }
  }

  /// Sync premium status with backend (non-blocking).
  /// Backend account-aware: user-scoped if userId provided, else device-scoped.
  Future<void> _syncPremiumWithBackend(
    String deviceId,
    WidgetRef ref, {
    int? userId,
  }) async {
    try {
      final qs = userId != null ? '?userId=$userId' : '';
      final response = await http
          .get(
            Uri.parse(
              '${AppConstants.baseURL}/api/v1/premium/device-status/$deviceId$qs',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint(
            '✅ Backend premium status: isPremium=${data['isPremium']}, '
            'daysRemaining=${data['daysRemaining']}, userId=$userId',
          );
          _applyBackendStatusToLocal(data, deviceId, ref);
        }
      } else {
        debugPrint(
          '⚠️ Backend premium status check failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Backend premium sync failed (non-blocking): $e');
    }
  }

  /// Backend response'unu local Riverpod state'e uygular.
  /// Hem `/initialize` hem `/device-status` aynı payload formatını döner.
  void _applyBackendStatusToLocal(
    Map<String, dynamic> data,
    String deviceId,
    WidgetRef ref,
  ) {
    if (data['isPremium'] == true && data['expiryDate'] != null) {
      final expiryDate = DateTime.parse(data['expiryDate']);
      ref.read(premiumProvider.notifier).setPremiumState(
            PremiumState(
              isPremium: true,
              expiryDate: expiryDate,
              deviceId: deviceId,
              isPurchased: data['planId'] != 'trial',
              daysRemaining: data['daysRemaining'] ?? 0,
            ),
          );
      debugPrint('   → Updated local premium state from backend');
    } else if (data['isPremium'] == false) {
      final currentState = ref.read(premiumProvider);
      if (currentState.isPremium) {
        ref.read(premiumProvider.notifier).deactivatePremium();
        debugPrint('   → Backend says no premium, local temizlendi.');
      }
    }
  }

  /// Auth: user logged in (userProvider null → User transition).
  /// 1) RevenueCat user identity'sini hizala (cross-device entitlement).
  /// 2) Backend'den user-scoped premium status çek.
  Future<void> _handleAuthLogin(int userId) async {
    try {
      final deviceId = await DeviceUtils.getDeviceId();
      debugPrint('🔐 Login event: userId=$userId, deviceId=$deviceId');

      // 1) RevenueCat identity. CustomerInfo update listener otomatik tetiklenir.
      try {
        await Purchases.logIn(userId.toString());
        debugPrint('✅ Purchases.logIn ok (userId=$userId)');
      } catch (e) {
        debugPrint('⚠️ Purchases.logIn failed: $e');
      }

      // 2) Backend sync (user-scoped). Initialize endpoint trial gate'i de uygular.
      try {
        final data = await PremiumApiService().initialize(
          deviceId: deviceId,
          userId: userId,
        );
        _applyBackendStatusToLocal(data, deviceId, ref);
      } catch (e) {
        debugPrint('⚠️ Backend initialize (login) failed: $e');
      }
    } catch (e) {
      debugPrint('⚠️ _handleAuthLogin error: $e');
    }
  }

  /// Auth: user logged out (userProvider User → null transition).
  /// RevenueCat'i detach et, local premium'u temizle, guest mode'da yeniden sync et.
  Future<void> _identifyUserForAnalytics(UserModel user) async {
    final premium = ref.read(premiumProvider);
    await AnalyticsService.instance.identifyUser(
      userId: user.id,
      credential: user.credential,
      hasCompletedProfile: user.answerData != null,
      isPremium: premium.isPremium,
      daysRemaining: premium.daysRemaining,
    );
  }

  Future<void> _resetAnalyticsIdentity() async {
    await AnalyticsService.instance.reset();
    try {
      final deviceId = await DeviceUtils.getDeviceId();
      _analyticsDistinctId = 'device_$deviceId';
      await AnalyticsService.instance.identifyDevice(deviceId);
    } catch (_) {}
  }

  void _trackPremiumAnalytics(PremiumState? previous, PremiumState next) {
    final distinctId = _analyticsDistinctId;
    if (distinctId == null || !AnalyticsService.instance.isEnabled) return;

    // Hydration sırasında (local DB → backend → RevenueCat zinciri) premium
    // state birden çok kez set ediliyor; bunları gerçek transition sanıp
    // phantom premium_purchased / premium_deactivated event'i atmamak için
    // init future tamamlanana kadar tracking kapalı.
    if (!_premiumHydrated) return;

    final prev = previous ?? PremiumState.initial(deviceId: next.deviceId);
    if (prev.isPremium == next.isPremium &&
        prev.isPurchased == next.isPurchased) {
      return;
    }
    AnalyticsService.instance.trackPremiumTransition(
      userDistinctId: distinctId,
      wasPremium: prev.isPremium,
      wasPurchased: prev.isPurchased,
      isPremium: next.isPremium,
      isPurchased: next.isPurchased,
      daysRemaining: next.daysRemaining,
      source: 'premium_provider',
    );
  }

  Future<void> _handleAuthLogout() async {
    try {
      final deviceId = await DeviceUtils.getDeviceId();
      debugPrint('🔐 Logout event: deviceId=$deviceId');

      try {
        await Purchases.logOut();
        debugPrint('✅ Purchases.logOut ok');
      } catch (e) {
        // RevenueCat anonymous user üzerinde logOut çağırılırsa hata fırlatabilir.
        // İçinde zaten anonim ise sorun değil — devam et.
        debugPrint('⚠️ Purchases.logOut: $e');
      }

      // Local premium'u temizle. Guest device row'unda premium varsa
      // aşağıdaki backend sync onu geri yükleyecek.
      await ref.read(premiumProvider.notifier).deactivatePremium();

      try {
        final data = await PremiumApiService().initialize(deviceId: deviceId);
        _applyBackendStatusToLocal(data, deviceId, ref);
      } catch (e) {
        debugPrint('⚠️ Backend initialize (logout) failed: $e');
      }
    } catch (e) {
      debugPrint('⚠️ _handleAuthLogout error: $e');
    }
  }
}
