import '../domain/auth_repository.dart';
import '../domain/social_login_provider.dart';
import 'datasource/auth_remote_datasource.dart';


/// AuthRepositoryImpl
/// ------------------------------------------------------------
/// Domain katmanının istediği AuthRepository kontratını
/// data katmanındaki AuthRemoteDataSource ile birleştirir.
///
/// Feature/UI bu sınıfı değil,
/// sadece AuthRepository interface’ini bilir.
///
/// Amaç:
/// - Data kaynağı değişse bile (Fake → N8N)
///   feature tarafında hiçbir kodun değişmemesi.

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<void> loginWithSocial(SocialLoginProvider provider) =>
      _remote.loginWithSocial(provider);

  @override
  Future<void> logout() => _remote.logout();

  @override
  Future<bool> isLoggedIn() => _remote.isLoggedIn();
}
