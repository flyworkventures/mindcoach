import '../../domain/social_login_provider.dart';

/// AuthRemoteDataSource
/// ------------------------------------------------------------
/// Auth işlemleri için dış dünya ile konuşan soyut katmandır.
///
/// UI veya Controller bu interface’i bilir,
/// ama hangi implementasyonun kullanıldığını bilmez.
///
/// Şu an:
/// - FakeAuthDataSource kullanılıyor
///
/// Gelecekte:
/// - N8nAuthDataSource
/// - FirebaseAuthDataSource
/// - SupabaseAuthDataSource
///
/// ⚠️ Swap noktası BURASI.
/// UI ve feature katmanları bu değişimden etkilenmez.

abstract class AuthRemoteDataSource {
 

  Future<void> deleteAccount();
  Future<bool> isLoggedIn();
}
