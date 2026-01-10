import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_notification/in_app_notification.dart';

import '../core/config/size_config.dart';
import '../core/locale/locale_provider.dart';
import '../core/routes/app_router.dart';
import '../l10n/app_localizations.dart';
import '../View/splash/splash.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    // Gerçek locale kodunu göster (sistem locale dahil)
    final currentLanguageCode = ref.read(localeProvider.notifier).getLanguageCode();
    debugPrint("Locale: $currentLanguageCode");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mind Coach',
   
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

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
        return InAppNotification(
          child: child!,
        );
      },
    );
  }
}
