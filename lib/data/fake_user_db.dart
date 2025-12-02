// lib/data/fake_user_db.dart
import 'dart:async';

enum SocialLoginProvider {
  google,
  apple,
  facebook,
}

class FakeUserDb {
  static Map<String, dynamic>? _currentUser;

  static Future<void> saveUser(SocialLoginProvider provider) async {
    // Sanki network/db işi varmış gibi ufak bir delay verelim
    await Future<void>.delayed(const Duration(milliseconds: 300));

    _currentUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'provider': provider.name,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic>? get currentUser => _currentUser;

  static bool get isLoggedIn => _currentUser != null;

  static Future<void> logout() async {
    _currentUser = null;
  }
}
