import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Repositories/auth_repositories.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:mindcoach/models/user_model.dart';

class AuthService {
  final Ref? ref;
  final LocalDbService _localDbService = LocalDbService();

  AuthService({this.ref});

  Future<void> saveToken(String token) async {
    await _localDbService.setString(key: LocalDbKeys.token, value: token);
    debugPrint('✅ [AUTH-SERVICE] Token kaydedildi');
  }


  Future<String?> getToken() async {
    return await _localDbService.getString(key: LocalDbKeys.token);
  }

  Future<void> clearToken() async {
    await _localDbService.deleteString(key: LocalDbKeys.token);
    debugPrint('✅ [AUTH-SERVICE] Token silindi');
  }


  Future<UserModel?> verifyAndSetUser(String token) async {
    try {
      debugPrint('🔄 [AUTH-SERVICE] Kullanıcı doğrulanıyor...');
      debugPrint('🔄 [AUTH-SERVICE] Token: ${token.substring(0, 20)}...');

      final userModel = await AuthRepositories().verifyUserByToken(token);
      debugPrint('🔄 [AUTH-SERVICE] verifyUserByToken tamamlandı, userModel: ${userModel?.id ?? "null"}');

      if (userModel == null) {
        debugPrint('❌ [AUTH-SERVICE] Kullanıcı doğrulama başarısız - userModel null');
        return null;
      }

      debugPrint('✅ [AUTH-SERVICE] Kullanıcı doğrulandı: ${userModel.id}');

      // Token ile birlikte userModel'i oluştur
      var userModelWithToken = userModel.copyWith(token: token);

      // Locally cached username override — sunucu eski veri dönüyorsa bu düzeltir
      final savedUsername = await _localDbService.getString(key: LocalDbKeys.savedUsername);
      if (savedUsername != null && savedUsername.isNotEmpty) {
        userModelWithToken = userModelWithToken.copyWith(username: savedUsername);
        debugPrint('✅ [AUTH-SERVICE] Cached username uygulandı: $savedUsername');
      }

      debugPrint('✅ [AUTH-SERVICE] UserModel token ile güncellendi');

      // UserProvider'a set et
      if (ref != null) {
        ref!.read(AllProviders.userProvider.notifier).setUserModel(userModelWithToken);
        debugPrint('✅ [AUTH-SERVICE] UserProvider güncellendi: ${userModel.id}');
      } else {
        debugPrint('⚠️ [AUTH-SERVICE] ref null, UserProvider güncellenemedi');
      }

      return userModelWithToken;
    } catch (e, stackTrace) {
      debugPrint('❌ [AUTH-SERVICE] Kullanıcı doğrulama hatası: $e');
      debugPrint('❌ [AUTH-SERVICE] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Mevcut session'ı kontrol et ve kullanıcıyı doğrula
  /// Returns: UserModel if session valid, null otherwise
  Future<UserModel?> checkSession() async {
    final token = await getToken();
    
    if (token == null) {
      debugPrint('⚠️ [AUTH-SERVICE] Token bulunamadı');
      return null;
    }

    return await verifyAndSetUser(token);
  }

  /// Session'ı temizle
  Future<void> clearSession() async {
    await clearToken();
    await _localDbService.deleteString(key: LocalDbKeys.savedUsername);
    if (ref != null) {
      ref!.read(AllProviders.userProvider.notifier).setUserModel(null);
      debugPrint('✅ [AUTH-SERVICE] Session temizlendi');
    }
  }
}

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref: ref);
});
