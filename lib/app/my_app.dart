import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_notification/in_app_notification.dart';
import 'package:mindcoach/Riverpod/Providers/premium_provider.dart';
import 'package:mindcoach/View/ProfileSetupView/steps/find_coach_step.dart';
import 'package:mindcoach/View/splash/splash.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/device_utils.dart';
import 'package:mindcoach/models/premium_state.dart';

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

  @override
  void initState() {
    super.initState();
    // App ömrü boyunca premium init işlemini tek sefer çalıştır.
    _premiumInitFuture = _initializePremiumOnLaunch(ref);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize premium provider with device ID and check status
    ref.listen(premiumProvider, (previous, next) {
      debugPrint(
        '🔐 Premium status: ${next.isPremium}, Days: ${next.daysRemaining}',
      );
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

      // Initialize premium provider with device ID
      final initialState = PremiumState.initial(deviceId: deviceId);

      // Update the provider with loaded state
      ref.read(premiumProvider.notifier).setPremiumState(initialState);

      // Check and update premium status from local storage first
      await ref.read(premiumProvider.notifier).checkPremiumStatus();
      debugPrint('✅ Loaded local premium status for device: $deviceId');

      // Sync with backend: get current premium status from server
      _syncPremiumWithBackend(deviceId, ref);

      return deviceId;
    } catch (e) {
      debugPrint('⚠️ Error initializing premium: $e');
      return 'unknown';
    }
  }

  /// Sync premium status with backend (non-blocking)
  /// Backend may have more recent premium status than local cache
  Future<void> _syncPremiumWithBackend(String deviceId, WidgetRef ref) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConstants.baseURL}/api/v1/premium/device-status/$deviceId',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Backend premium status check timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint(
            '✅ Backend premium status: isPremium=${data['isPremium']}, daysRemaining=${data['daysRemaining']}',
          );

          // Update local premium state if backend has different status
          if (data['isPremium'] == true && data['expiryDate'] != null) {
            final expiryDate = DateTime.parse(data['expiryDate']);
            ref
                .read(premiumProvider.notifier)
                .setPremiumState(
                  PremiumState(
                    isPremium: true,
                    expiryDate: expiryDate,
                    deviceId: deviceId,
                    isPurchased: data['planId'] != 'trial',
                    daysRemaining: data['daysRemaining'] ?? 0,
                  ),
                );
            debugPrint('   → Updated local premium state from backend');
          }
        }
      } else {
        debugPrint(
          '⚠️ Backend premium status check failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Backend premium sync failed (non-blocking): $e');
      // Continue with local cache if backend unavailable
    }
  }
}
