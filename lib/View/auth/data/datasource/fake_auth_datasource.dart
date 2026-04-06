import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'dart:developer' as developer;
import '../../../../core/utils/app_constants.dart';
import '../../../../core/repo/auth_repository.dart';
import '../../../../Http/http_service.dart';
import '../../../../core/utils/local_db_keys.dart';
import '../../../../Riverpod/providers/user_provider.dart';
import '../../../../models/user_model.dart';
import '../../domain/social_login_provider.dart';
import '../local/fake_user_db.dart';
import 'auth_remote_datasource.dart';




class FakeAuthDataSource implements AuthRemoteDataSource {
  final Ref? ref;
  
  FakeAuthDataSource({this.ref});



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
