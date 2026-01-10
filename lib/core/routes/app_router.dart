import 'package:flutter/material.dart';
import 'package:mindcoach/models/consultant_model.dart';


import 'package:mindcoach/app/navbar_shell.dart';
import 'package:mindcoach/View/chat_screen/presentation/pages/conversation_screen.dart';
import 'package:mindcoach/View/chat_screen/conversation/video_call/video_call_screen.dart';
import 'package:mindcoach/View/mental_tests/test_intro_screen.dart';
import 'package:mindcoach/View/mental_tests/test_question_screen.dart';
import 'package:mindcoach/View/mental_tests/test_result_screen.dart';
import 'package:mindcoach/View/profile_setup/presentation/pages/profile_setup_page.dart';
import 'package:mindcoach/View/profile_screen/appointment/appointment_screen.dart';
import 'package:mindcoach/View/profile_screen/faq/faq_screen.dart';
import 'package:mindcoach/View/profile_screen/notifications/notifications_screen.dart';
import 'package:mindcoach/View/profile_screen/presentation/goodbye_screen.dart';
import 'package:mindcoach/View/profile_screen/presentation/invite_screen.dart';
import 'package:mindcoach/View/profile_screen/premium/premium_screen.dart';
import 'package:mindcoach/View/profile_screen/presentation/profile_settings.dart';
import '../../View/Onboard/onboarding_page.dart';
import 'page_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
    /// ROOT / SHELL
      case PageRoutes.onboarding:
        return _page(const OnboardingScreen(), settings);

      case PageRoutes.profileSetup:
        return _page(const MindCoachOnboarding(), settings);

      case PageRoutes.navbar:
        return _page(const NavbarShell(), settings);

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

    /// CHAT
      case PageRoutes.conversationScreen:
        // ConsultantModel bekleniyor
        final args = settings.arguments;
        
        if (args is! ConsultantModel) {
          // Eğer ConsultantModel değilse, fallback oluştur
          return _page(
            Scaffold(
              body: Center(
                child: Text('Hata: ConsultantModel bekleniyor'),
              ),
            ),
            settings,
          );
        }
        
        return _page(
          ConversationScreen(specialistId: args ),
          settings,
        );

      case PageRoutes.videoCall:
        return _page(const VideoCallScreen(), settings);

    /// TESTS
      case PageRoutes.testIntroScreen:
        final args = settings.arguments as Map<String, dynamic>? ?? {};

        return _page(
          TestIntroScreen(
            testName: (args['testName'] as String?) ?? 'Default Test',
            testTitle: (args['testTitle'] as String?) ?? 'Introductory Information',
            imagePath: (args['imagePath'] as String?) ?? 'assets/chars/char0.jpg',
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
          const Scaffold(
            body: Center(child: Text('Hata: Rota Bulunamadı!')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }

  static int _parseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static Map<int, int> _parseResultsMap(dynamic args) {
    if (args is Map<int, int>) return args;

    // Map<dynamic,dynamic> -> Map<int,int> dönüşümü (güvenli)
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
