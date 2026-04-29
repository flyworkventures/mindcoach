import 'package:flutter/material.dart';
import 'package:mindcoach/View/LoginView/login_view.dart';
import 'package:mindcoach/View/ProfileSettingsView/profile_settings.dart';
import 'package:mindcoach/View/ProfileSetupView/profile_setup_view.dart';
import 'package:mindcoach/View/ProfileSetupView/steps/find_coach_step.dart';
import 'package:mindcoach/View/ProfileView/appointment/appointment_screen.dart';
import 'package:mindcoach/View/ProfileView/faq/faq_screen.dart';
import 'package:mindcoach/View/ProfileView/language/language_selection_screen.dart';
import 'package:mindcoach/View/ProfileView/notifications/notifications_screen.dart';
import 'package:mindcoach/View/ProfileView/premium/premium_screen.dart';
import 'package:mindcoach/View/ProfileView/presentation/goodbye_screen.dart';
import 'package:mindcoach/View/ProfileView/presentation/invite_screen.dart';
import 'package:mindcoach/View/chat_screen/conversation/conversation_page.dart';
import 'package:mindcoach/View/chat_screen/conversation/video_call/video_call_realtime_screen.dart';
import 'package:mindcoach/View/chat_screen/conversation/voice_call/voice_call_view.dart';
import 'package:mindcoach/View/mental_tests/test_intro_screen.dart';
import 'package:mindcoach/View/mental_tests/test_question_screen.dart';
import 'package:mindcoach/View/mental_tests/test_result_screen.dart';
import 'package:mindcoach/View/relaxing_sound/relaxing_sound_screen.dart';
import 'package:mindcoach/View/specialists_screen/specialist_detail_screen.dart';
import 'package:mindcoach/app/navbar_shell.dart';
import 'package:mindcoach/models/consultant_model.dart';

import '../../View/OnboardView/onboarding_page.dart';
import 'page_routes.dart';

class AppRouter {
  static Map<String, WidgetBuilder> routes = {
    PageRoutes.onboarding: (_) => const OnboardingScreen(),
    PageRoutes.profileSetup: (_) => const MindCoachOnboarding(),
    PageRoutes.findCoach: (_) => const FindCoachScreen(),
    PageRoutes.login: (_) => const LoginView(),
    PageRoutes.navbar: (_) => const BottomNavBar(),

    PageRoutes.profileSettings: (_) => const ProfileSettingsScreen(),
    PageRoutes.goodbye: (_) => const GoodbyeScreen(),
    PageRoutes.invite: (_) => const InviteScreen(),
    PageRoutes.faq: (_) => const FaqScreen(),
    PageRoutes.appointments: (_) => const AppointmentsScreen(),
    PageRoutes.notifications: (_) => const NotificationsScreen(),
    PageRoutes.premimum: (_) => const PremiumScreen(),
    PageRoutes.videoCallView: (_) => const Scaffold(
      body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
    ),
    PageRoutes.relaxingSoundScreen: (_) => const RelaxingSoundScreen(),
    PageRoutes.languageSelection: (_) => const LanguageSelectionScreen(),

    PageRoutes.conversationScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! ConsultantModel) {
        return const Scaffold(
          body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
        );
      }
      return ConversationScreen(specialistId: args);
    },

    PageRoutes.videoCall: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! ConsultantModel) {
        return const Scaffold(
          body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
        );
      }
      return VideoCallRealtimeScreen(specialist: args);
    },

    /// YENİ EKLENEN: Voice Call Route
    PageRoutes.voiceCallView: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! ConsultantModel) {
        return const Scaffold(
          body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
        );
      }
      return VoiceCallScreen(
        specialist: args,
      ); // Class adınız VoiceCallView ise onu kullanın
    },

    PageRoutes.specialistDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is! ConsultantModel) {
        return const Scaffold(
          body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
        );
      }
      return SpecialistDetailScreen(specialist: args);
    },

    PageRoutes.testIntroScreen: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
          {};
      return TestIntroScreen(
        testName: (args['testName'] as String?) ?? 'Default Test',
        testTitle: (args['testTitle'] as String?) ?? 'Introductory Information',
        imagePath: (args['imagePath'] as String?) ?? 'assets/chars/char0.jpg',
        totalQuestions: _parseInt(args['totalQuestions'], fallback: 7),
      );
    },

    PageRoutes.testQuestionScreen: (_) => const TestQuestionScreen(),

    PageRoutes.testResultScreen: (context) {
      final results = _parseResultsMap(
        ModalRoute.of(context)?.settings.arguments,
      );
      return TestResultScreen(results: results);
    },
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      /// ROOT / SHELL
      case PageRoutes.onboarding:
        return _page(const OnboardingScreen(), settings);

      case PageRoutes.profileSetup:
        return _page(const MindCoachOnboarding(), settings);
      case PageRoutes.findCoach:
        return _page(const FindCoachScreen(), settings);

      case PageRoutes.login:
        return _page(const LoginView(), settings);

      case PageRoutes.navbar:
        return _page(const BottomNavBar(), settings);

      /// PROFILE PAGES
      case PageRoutes.profileSettings:
        return _page(const ProfileSettingsScreen(), settings);

      case PageRoutes.goodbye:
        return _page(const GoodbyeScreen(), settings);

      case PageRoutes.invite:
        return _page(const InviteScreen(), settings);

      case PageRoutes.faq:
        return _page(const FaqScreen(), settings);

      case PageRoutes.appointments:
        return _page(const AppointmentsScreen(), settings);

      case PageRoutes.notifications:
        return _page(const NotificationsScreen(), settings);

      case PageRoutes.premimum:
        return _page(const PremiumScreen(), settings);

      /// CHAT & CALLS
      case PageRoutes.conversationScreen:
        final args = settings.arguments;
        if (args is! ConsultantModel) {
          return _page(
            const Scaffold(
              body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
            ),
            settings,
          );
        }
        return _page(ConversationScreen(specialistId: args), settings);

      case PageRoutes.videoCall:
        final args = settings.arguments;
        if (args is! ConsultantModel) {
          return _page(
            const Scaffold(
              body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
            ),
            settings,
          );
        }
        return _page(VideoCallRealtimeScreen(specialist: args), settings);

      case PageRoutes.videoCallView:
        return _page(
          const Scaffold(
            body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
          ),
          settings,
        );

      /// YENİ EKLENEN: Voice Call Route
      case PageRoutes.voiceCallView:
        final args = settings.arguments;
        if (args is! ConsultantModel) {
          return _page(
            const Scaffold(
              body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
            ),
            settings,
          );
        }
        return _page(
          VoiceCallScreen(specialist: args),
          settings,
        ); // Class adınız VoiceCallView ise onu kullanın

      /// LANGUAGE SELECTION
      case PageRoutes.languageSelection:
        return _page(const LanguageSelectionScreen(), settings);

      /// RELAXING SOUND
      case PageRoutes.relaxingSoundScreen:
        return _page(const RelaxingSoundScreen(), settings);

      /// SPECIALIST DETAIL
      case PageRoutes.specialistDetail:
        final args = settings.arguments;
        if (args is! ConsultantModel) {
          return _page(
            const Scaffold(
              body: Center(child: Text('Hata: ConsultantModel bekleniyor')),
            ),
            settings,
          );
        }
        return _page(SpecialistDetailScreen(specialist: args), settings);

      /// TESTS
      case PageRoutes.testIntroScreen:
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        return _page(
          TestIntroScreen(
            testName: (args['testName'] as String?) ?? 'Default Test',
            testTitle:
                (args['testTitle'] as String?) ?? 'Introductory Information',
            imagePath:
                (args['imagePath'] as String?) ?? 'assets/chars/char0.jpg',
            totalQuestions: _parseInt(args['totalQuestions'], fallback: 7),
          ),
          settings,
        );

      case PageRoutes.testQuestionScreen:
        return _page(const TestQuestionScreen(), settings);

      case PageRoutes.testResultScreen:
        final results = _parseResultsMap(settings.arguments);
        return _page(TestResultScreen(results: results), settings);

      /// FALLBACK
      default:
        return _page(
          const Scaffold(body: Center(child: Text('Hata: Rota Bulunamadı!'))),
          settings,
        );
    }
  }

  static MaterialPageRoute _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => child, settings: settings);
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static Map<int, int> _parseResultsMap(dynamic args) {
    if (args is Map<int, int>) return args;
    if (args is Map) {
      final out = <int, int>{};
      args.forEach((k, v) {
        final key = (k is int) ? k : int.tryParse(k.toString());
        final val = (v is int) ? v : int.tryParse(v.toString());
        if (key != null && val != null) out[key] = val;
      });
      return out;
    }
    return <int, int>{};
  }
}
