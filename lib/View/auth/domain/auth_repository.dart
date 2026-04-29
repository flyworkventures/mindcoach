// features/auth/domain/auth_repository.dart

/// Auth domain sözleşmesi.
///
/// UI ve controller bu interface ile konuşur.
/// Altında Fake / N8N / Firebase ne olduğu önemli değildir.
///
/// 🔁 Backend swap edildiğinde bu dosya ASLA değişmez.

abstract class AuthRepository {

  Future<void> logout();
  Future<void> deleteAccount({
    String? deleteReason,
    String? deleteMessage,
  });
  Future<bool> isLoggedIn();
}
