import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/size_config.dart';
import '../core/locale/locale_provider.dart';
import '../core/routes/app_router.dart';
import '../l10n/app_localizations.dart';
import 'auth_gate.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? overrideLocale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mind Coach',

      locale: overrideLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      home: const AuthGate(),

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
        return child!;
      },
    );
  }
}
