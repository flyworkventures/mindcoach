import 'dart:async';


/// Gerçek backend yokken kullanılan FAKE user storage.
///
/// ❗ Bu bir DB değildir.
/// ❗ Sadece flow ve UI testleri için vardır.
///
/// TODO: Backend (N8N) geldiğinde
/// - Bu sınıf kullanılmayacak
/// - Ama arayüz ve controller aynen kalacak
///

class FakeUserDb {
  static Map<String, dynamic>? _currentUser;

  /// Fake login işlemi
  /// Network hissi vermek için küçük delay içerir
  static Future<void> saveUser(String providerName) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'provider': providerName,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Kullanıcı login olmuş mu?
  static bool get isLoggedIn => _currentUser != null;

  /// Fake logout
  static Future<void> logout() async {
    _currentUser = null;
  }
}
