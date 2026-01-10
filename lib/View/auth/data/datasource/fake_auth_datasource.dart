import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'dart:developer' as developer;
import '../../../../core/utils/app_constants.dart';
import '../../../../core/repo/auth_repository.dart';
import '../../../../http/http_service.dart';
import '../../../../core/utils/local_db_keys.dart';
import '../../../../Riverpod/providers/user_provider.dart';
import '../../../../models/user_model.dart';
import '../../domain/social_login_provider.dart';
import '../local/fake_user_db.dart';
import 'auth_remote_datasource.dart';



/// FakeAuthDataSource
/// ------------------------------------------------------------
/// AuthRemoteDataSource'un geçici (fake) implementasyonu.
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
  final Ref? ref;
  
  FakeAuthDataSource({this.ref});

  @override
  Future<void> loginWithSocial(SocialLoginProvider provider) async {
    // AuthRepository'den gerçek login metodunu çağır
    final authRepo = AuthRepository();
    final localDbService = LocalDbService();
    final httpService = HttpService(ref: ref);
    
    try {
      dynamic result;
      String? apiPath;
      Map<String, dynamic>? body;
      
      switch (provider) {
        case SocialLoginProvider.google:
          result = await authRepo.googleSignIn();
          if (result == false || result == null) {
            throw Exception('Google login failed');
          }
          apiPath = AppConstants.googleAuth;
          body = {'idToken': result};
          break;
          
        case SocialLoginProvider.facebook:
          result = await authRepo.facebookSignIn();
          if (result == null || result['accessToken'] == null) {
            throw Exception('Facebook login failed');
          }
          apiPath = AppConstants.facebookAuth;
          body = {'accessToken': result['accessToken']};
          break;
          
        case SocialLoginProvider.apple:
          result = await authRepo.appleSignIn();
          if (result == null || result['userIdentifier'] == null) {
            throw Exception('Apple login failed');
          }
          apiPath = AppConstants.appleAuth;
          body = {
            'identityToken': result['identityToken'],
            'userIdentifier': result['userIdentifier'],
            if (result['authorizationCode'] != null) 'authorizationCode': result['authorizationCode']!,
            // Apple'dan gelen fullName'i API'ye gönder
            if (result['fullName'] != null && result['fullName'].toString().isNotEmpty) 
              'fullName': result['fullName'].toString(),
          };
          // Apple'dan gelen fullName'i geçici olarak sakla (profil tamamlama için fallback)
          if (result['fullName'] != null && result['fullName'].toString().isNotEmpty) {
            await localDbService.setString(
              key: LocalDbKeys.appleFullName,
              value: result['fullName'].toString(),
            );
            developer.log('✅ [AUTH] Apple fullName sent to API: ${result['fullName']}');
          }
          break;
          
        case SocialLoginProvider.guest:
          // Misafir girişi için body yok
          apiPath = AppConstants.guestAuth;
          body = null;
          // Guest login için token göndermemeli (Authorization header'ı olmamalı)
          break;
      }
      
      // API'ye login isteği gönder
      // Guest login için Authorization header'ı göndermemeli
      final Map<String, String>? customHeaders = provider == SocialLoginProvider.guest
          ? {'Content-Type': 'application/json'} // Sadece Content-Type, Authorization yok
          : null; // Diğer durumlarda default header kullan (Authorization ile)
      
      final response = await httpService.post(
        path: apiPath,
        body: body ?? {},
        headers: customHeaders,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final token = json['data']['token'];
          final userData = json['data']['user'];
          
          // Token'ı kaydet
          await localDbService.setString(key: LocalDbKeys.token, value: token);
          developer.log('✅ [AUTH] ${provider.name} login successful, token saved');
          
          // User bilgisini de kaydet (UserProvider'a set etmek için)
          if (userData != null && ref != null) {
            try {
              // UserModel oluştur
              final userModel = UserModel.fromMap(userData);
              final userModelWithToken = userModel.copyWith(token: token);
              
              // UserProvider'a set et
              (ref as dynamic).read(userProvider.notifier).setUserModel(userModelWithToken);
              developer.log('✅ [AUTH] UserProvider güncellendi: ${userModel.id}');
            } catch (e) {
              developer.log('⚠️ [AUTH] UserProvider güncelleme hatası (göz ardı edildi): $e');
              // Hata olsa bile devam et, verifyUserByToken ile düzeltilebilir
            }
          }
        } else {
          throw Exception('API response indicates failure');
        }
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e) {
      developer.log('❌ [AUTH] ${provider.name} login error: $e');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    developer.log('🔴 [LOGOUT] Logout başlatılıyor...');
    
    try {
      // Apple Sign-In state'ini temizle (eğer Apple ile giriş yapıldıysa)
      try {
        // Apple Sign-In'in kendi state'ini temizlemek için
        // Not: sign_in_with_apple paketi otomatik olarak state'i yönetir,
        // ama logout sonrası Apple'ın credential cache'ini temizlemek için
        // herhangi bir özel işlem gerekmez
        developer.log('🔴 [LOGOUT] Apple Sign-In state kontrol edildi');
      } catch (e) {
        developer.log('⚠️ [LOGOUT] Apple Sign-In temizleme hatası (göz ardı edildi): $e');
      }
      
      // API'ye logout isteği gönder
      final httpService = HttpService(ref: ref);
      developer.log('🔴 [LOGOUT] API isteği gönderiliyor: ${AppConstants.logoutURL}');
      
      final response = await httpService.post(
        path: AppConstants.logoutURL,
      );
      
      developer.log('🔴 [LOGOUT] API yanıtı: ${response.statusCode}');
      
      // Token'ı local storage'dan sil (başarılı olsun olmasın)
      final localDbService = LocalDbService();
      await localDbService.deleteString(key: LocalDbKeys.token);
      developer.log('🔴 [LOGOUT] Token local storage\'dan silindi');
      
      // UserProvider'ı temizle
      if (ref != null) {
        try {
          (ref as dynamic).read(userProvider.notifier).setUserModel(null);
          developer.log('🔴 [LOGOUT] UserProvider temizlendi');
        } catch (e) {
          developer.log('⚠️ [LOGOUT] UserProvider temizleme hatası: $e');
        }
      }
      
      // Fake DB'den de temizle
      await FakeUserDb.logout();
      developer.log('🔴 [LOGOUT] FakeUserDb temizlendi');
      developer.log('✅ [LOGOUT] Logout başarıyla tamamlandı');
    } catch (e, st) {
      developer.log('❌ [LOGOUT] Logout hatası: $e');
      developer.log('❌ [LOGOUT] Stack trace: $st');
      
      // Hata olsa bile local storage'ı ve userProvider'ı temizle
      final localDbService = LocalDbService();
      await localDbService.deleteString(key: LocalDbKeys.token);
      developer.log('🔴 [LOGOUT] Token local storage\'dan silindi (hata durumunda)');
      
      // UserProvider'ı temizle
      if (ref != null) {
        try {
          (ref as dynamic).read(userProvider.notifier).setUserModel(null);
          developer.log('🔴 [LOGOUT] UserProvider temizlendi (hata durumunda)');
        } catch (e) {
          developer.log('⚠️ [LOGOUT] UserProvider temizleme hatası: $e');
        }
      }
      
      await FakeUserDb.logout();
      developer.log('🔴 [LOGOUT] FakeUserDb temizlendi (hata durumunda)');
      // Logout işlemi tamamlandı, hata fırlatma (kullanıcı zaten çıkış yapmış olmalı)
    }
  }

  @override
  Future<void> deleteAccount() async {
    developer.log('🗑️ [DELETE-ACCOUNT] Delete account başlatılıyor...');
    
    try {
      // API'ye delete account isteği gönder
      final httpService = HttpService(ref: ref);
      developer.log('🗑️ [DELETE-ACCOUNT] API isteği gönderiliyor: ${AppConstants.deleteAccountURL}');
      
      final response = await httpService.delete(
        path: AppConstants.deleteAccountURL,
      );
      
      developer.log('🗑️ [DELETE-ACCOUNT] API yanıtı: ${response.statusCode}');
      
      // Token'ı local storage'dan sil (başarılı olsun olmasın)
      final localDbService = LocalDbService();
      await localDbService.deleteString(key: LocalDbKeys.token);
      developer.log('🗑️ [DELETE-ACCOUNT] Token local storage\'dan silindi');
      
      // UserProvider'ı temizle
      if (ref != null) {
        try {
          (ref as dynamic).read(userProvider.notifier).setUserModel(null);
          developer.log('🗑️ [DELETE-ACCOUNT] UserProvider temizlendi');
        } catch (e) {
          developer.log('⚠️ [DELETE-ACCOUNT] UserProvider temizleme hatası: $e');
        }
      }
      
      // Fake DB'den de temizle
      await FakeUserDb.logout();
      developer.log('🗑️ [DELETE-ACCOUNT] FakeUserDb temizlendi');
      developer.log('✅ [DELETE-ACCOUNT] Delete account başarıyla tamamlandı');
    } catch (e, st) {
      developer.log('❌ [DELETE-ACCOUNT] Delete account hatası: $e');
      developer.log('❌ [DELETE-ACCOUNT] Stack trace: $st');
      
      // Hata olsa bile local storage'ı ve userProvider'ı temizle
      final localDbService = LocalDbService();
      await localDbService.deleteString(key: LocalDbKeys.token);
      developer.log('🗑️ [DELETE-ACCOUNT] Token local storage\'dan silindi (hata durumunda)');
      
      // UserProvider'ı temizle
      if (ref != null) {
        try {
          (ref as dynamic).read(userProvider.notifier).setUserModel(null);
          developer.log('🗑️ [DELETE-ACCOUNT] UserProvider temizlendi (hata durumunda)');
        } catch (e) {
          developer.log('⚠️ [DELETE-ACCOUNT] UserProvider temizleme hatası: $e');
        }
      }
      
      await FakeUserDb.logout();
      developer.log('🗑️ [DELETE-ACCOUNT] FakeUserDb temizlendi (hata durumunda)');
      // Delete account işlemi tamamlandı, hata fırlatma
    }
  }

  @override
  Future<bool> isLoggedIn() async => FakeUserDb.isLoggedIn;
}
