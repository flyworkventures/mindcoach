// features/auth/domain/auth_repository.dart
import 'package:mindcoach/View/auth/domain/social_login_provider.dart';

/// Auth domain sözleşmesi.
///
/// UI ve controller bu interface ile konuşur.
/// Altında Fake / N8N / Firebase ne olduğu önemli değildir.
///
/// 🔁 Backend swap edildiğinde bu dosya ASLA değişmez.

abstract class AuthRepository {
  Future<void> loginWithSocial(SocialLoginProvider provider);
  Future<void> logout();
  Future<void> deleteAccount();
  Future<bool> isLoggedIn();
}
