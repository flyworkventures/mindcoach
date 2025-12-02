import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/features/onboarding/onboarding_page.dart';
import 'package:mindcoach/features/onboarding/profile_setup/profile_setup_page.dart';

import 'core/routes/page_routes.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';
import 'core/config/size_config.dart';


void main() {

  // 1. Widgets bağlama işlemini koruma altına al:
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. Splash ekranını koru:
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(ProviderScope(child: const MyApp()));

  // FlutterNativeSplash.remove(); // app yüklenince splashi kaldır
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// TEMA, LOKAL AYARLAR. HOME AUTH GATE
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: PageRoutes.onboarding,
      /// test amaçlı böyle ayarladım auth kısımları ayarlandıktan sonra burası değişecek
      locale: Locale('en'),
      routes: {
        PageRoutes.onboarding: (_) => const OnboardingScreen(),
        PageRoutes.profileSetup: (_) => const MindCoachOnboarding(),
        PageRoutes.home: (_) => const HomeScreen(),
      },

      title: 'Mind Coach',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.quicksandTextTheme(),
      ),
      home: Builder(
        builder: (context) {
          SizeConfig.init(context);
          return const OnboardingScreen();   // buraya auth gate ile kontrol eklenip ona göre onboarding veya homepage'e yollanacak
        },
      ),
    );
  }
}
