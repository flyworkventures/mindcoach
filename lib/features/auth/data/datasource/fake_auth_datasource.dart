import '../../domain/social_login_provider.dart';
import '../local/fake_user_db.dart';
import 'auth_remote_datasource.dart';



/// FakeAuthDataSource
/// ------------------------------------------------------------
/// AuthRemoteDataSource’un geçici (fake) implementasyonu.
///
/// Gerçek backend gelene kadar:
/// - login
/// - logout
/// - session kontrolü
/// gibi işlemleri simüle eder.
///
/// TODO(N8N):
/// - Bu sınıfın yerine N8nAuthDataSource yazılacak
/// - auth_di.dart içinde sadece provider swap edilecek

class FakeAuthDataSource implements AuthRemoteDataSource {
  @override
  Future<void> loginWithSocial(SocialLoginProvider provider) async {
    await FakeUserDb.saveUser(provider.name);
  }

  @override
  Future<void> logout() => FakeUserDb.logout();

  @override
  Future<bool> isLoggedIn() async => FakeUserDb.isLoggedIn;
}
