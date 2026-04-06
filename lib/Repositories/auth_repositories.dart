import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/core/repo/auth_repository.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/user_model.dart';

class AuthRepositories {
    final Ref? ref;
  final LocalDbService _localDbService = LocalDbService();
  final AuthRepository _authRepository = AuthRepository();

  AuthRepositories({this.ref});

  Future<void> saveToken(String token) async {
    await _localDbService.setString(key: LocalDbKeys.token, value: token);
    Logger.info(text: "Token kaydedildi",className: "AuthRepositories",functionName: "saveToken");
   

  }


  Future<String?> getToken() async {
    return await _localDbService.getString(key: LocalDbKeys.token);
  }

  Future<void> clearToken() async {
    await _localDbService.deleteString(key: LocalDbKeys.token);
     Logger.info(text: "Token silindi",className: "AuthRepositories",functionName: "clearToken");
  }


  Future<UserModel?> verifyAndSetUser(String token) async {
    try {
      
      final userModel = await verifyUserByToken(token);
       Logger.info(text: "verifyUserByToken tamamlandı, userModel: ${userModel?.id ?? "null"}",className: "AuthRepositories",functionName: "verifyAndSetUser");
      
      if (userModel == null) {
         Logger.errorLog(text: "Kullanıcı doğrulama başarısız - userModel null",className: "AuthRepositories",functionName: "verifyAndSetUser");
        return null;
      }

       Logger.info(text: "Kullanıcı doğrulandı: ${userModel.id}",className: "AuthRepositories",functionName: "verifyAndSetUser");
      
      // Token ile birlikte userModel'i oluştur
      final userModelWithToken = userModel.copyWith(token: token);
       Logger.info(text: "UserModel token ile güncellendi",className: "AuthRepositories",functionName: "verifyAndSetUser");
      
      // UserProvider'a set et

        ref?.read(AllProviders.userProvider.notifier).setUserModel(userModelWithToken);
         Logger.info(text: "UserProvider güncellendi: ${ref?.read(AllProviders.userProvider)?.id}",className: "AuthRepositories",functionName: "verifyAndSetUser");

      
      return userModelWithToken;
    } catch (e, stackTrace) {
       Logger.errorLog(text: " Kullanıcı doğrulama hatası: $e",className: "AuthRepositories",functionName: "verifyAndSetUser");
          Logger.errorLog(text: "Stack trace: $stackTrace",className: "AuthRepositories",functionName: "verifyAndSetUser");
      return null;
    }
  }

  /// Mevcut session'ı kontrol et ve kullanıcıyı doğrula
  /// Returns: UserModel if session valid, null otherwise
  Future<UserModel?> checkSession() async {
    final token = await getToken();
    
    if (token == null) {
        Logger.errorLog(text: "Token bulunamadı'",className: "AuthRepositories",functionName: "checkSession");
      return null;
    }

    return await verifyAndSetUser(token);
  }

  /// Session'ı temizle
  Future<void> clearSession() async {
    await clearToken();
    if (ref != null) {
      ref!.read(AllProviders.userProvider.notifier).setUserModel(null);
           Logger.info(text: "Session temizlendi",className: "AuthRepositories",functionName: "clearSession");
    }
  }






Future<UserModel?> verifyUserByToken(String token) async {
  try {

    Logger.info(text: "verifyUserByToken başlatılıyor",className: "AuthRepositories", functionName: "verifyUserByToken");
    
    HttpService httpService = HttpService();
    
    var res = await httpService.get(
      path: AppConstants.verifyTokenURL,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      }
    );
    
    
    if (res.statusCode == 200) {
      var json = jsonDecode(res.body);
      Logger.info(text: "Response JSON parse edildi",className: "AuthRepositories", functionName: "verifyUserByToken");
      
      if (json["success"] == true && json["data"] != null) {
        // Yeni API formatı: {"success": true, "data": {"valid": true, "user": {...}}}
        if (json["data"]["valid"] == true && json["data"]["user"] != null) {
          Logger.info(text: "Token geçerli, user model oluşturuluyor...",className: "AuthRepositories", functionName: "verifyUserByToken");
          UserModel userModel = UserModel.fromMap(json["data"]["user"]);
           Logger.info(text: "Token geçerli, user model oluşturuluyor... : ${userModel.id}",className: "AuthRepositories", functionName: "verifyUserByToken");

          return userModel;
        } else {
           Logger.errorLog(text: "Token validation error: valid=false veya user=null",className: "AuthRepositories", functionName: "verifyUserByToken");
          return null;
        }
      } else {
        Logger.errorLog(text: "Response format hatası: success=false veya data=null",className: "AuthRepositories", functionName: "verifyUserByToken");
        return null;
      }
    } else {
      Logger.errorLog(text: "Request to validation error: statusCode=${res.statusCode}",className: "AuthRepositories", functionName: "verifyUserByToken");
      return null;
    }
  } catch (e, stackTrace) {
     Logger.errorLog(text: "verifyUserByToken hatası: $e",className: "AuthRepositories", functionName: "verifyUserByToken");
    return null;
  }
}


Future<bool> completeProfile(String username,String gender,List<String> avaibleDays,String avaibleHours,String area,String speakingStyle)async{
   HttpService httpService = HttpService(ref: ref);
  
  // Username boşsa veya sadece boşluklardan oluşuyorsa "MindCoach User" olarak ayarla
  final finalUsername = (username.trim().isEmpty) ? 'MindCoach User' : username.trim();
  

  Logger.info(text: '📝 Profil tamamlanıyor: username="$finalUsername" (orijinal: "$username")',className: "AuthRepositories",functionName: "completeProfile");
  
  var body = {
  "username": finalUsername,
  "nativeLang": "tr",
  "gender": gender,
  "answerData": {
    "avaibleDays": avaibleDays,
    "avaibleHours": avaibleHours,
    "supportArea": area,
    "agentSpeakStyle": speakingStyle
  }
};

  var response = await httpService.put(path: AppConstants.completeProfileURL,
  body: body
  );
  if (response.statusCode == 200) {
    Logger.info(text: 'Profile Completed successfully',className: "AuthRepositories",functionName: "completeProfile");
  
    return true;
  } else {
     Logger.errorLog(text: 'Profile completion failed: ${response.statusCode}, ${response.body.toString()}',className: "AuthRepositories",functionName: "completeProfile");
    return false;
  }
}


// ...existing code...
Future<void> logout() async {
  Logger.info(text: 'Logout başlatılıyor...', className: 'AuthRepositories', functionName: 'logout');

  try {
    try {
      Logger.info(text: 'Apple Sign-In state kontrol edildi', className: 'AuthRepositories', functionName: 'logout');
    } catch (e) {
      Logger.errorLog(text: 'Apple Sign-In temizleme hatası: $e', className: 'AuthRepositories', functionName: 'logout');
    }

    final httpService = HttpService(ref: ref);
    Logger.info(text: 'API isteği gönderiliyor: ${AppConstants.logoutURL}', className: 'AuthRepositories', functionName: 'logout');

    final response = await httpService.post(path: AppConstants.logoutURL);
    Logger.info(text: 'API yanıtı: ${response.statusCode}', className: 'AuthRepositories', functionName: 'logout');

    await _localDbService.deleteString(key: LocalDbKeys.token);
    Logger.info(text: 'Token local storage\'dan silindi', className: 'AuthRepositories', functionName: 'logout');

    if (ref != null) {
      try {
        ref!.read(AllProviders.userProvider.notifier).setUserModel(null);
        Logger.info(text: 'UserProvider temizlendi', className: 'AuthRepositories', functionName: 'logout');
      } catch (e) {
        Logger.errorLog(text: 'UserProvider temizleme hatası: $e', className: 'AuthRepositories', functionName: 'logout');
      }
    }

   // await FakeUserDb.logout();
    Logger.info(text: 'FakeUserDb temizlendi', className: 'AuthRepositories', functionName: 'logout');

    Logger.info(text: '✅ [LOGOUT] Logout başarıyla tamamlandı', className: 'AuthRepositories', functionName: 'logout');
  } catch (e, st) {
    Logger.errorLog(text: 'Logout hatası: $e', className: 'AuthRepositories', functionName: 'logout');
    Logger.errorLog(text: 'Stack trace: $st', className: 'AuthRepositories', functionName: 'logout');

    try {
      await _localDbService.deleteString(key: LocalDbKeys.token);
      Logger.info(text: 'Token local storage\'dan silindi (hata durumunda)', className: 'AuthRepositories', functionName: 'logout');
    } catch (e) {
      Logger.errorLog(text: 'Token silinirken hata: $e', className: 'AuthRepositories', functionName: 'logout');
    }

    if (ref != null) {
      try {
        ref!.read(AllProviders.userProvider.notifier).setUserModel(null);
        Logger.info(text: 'UserProvider temizlendi (hata durumunda)', className: 'AuthRepositories', functionName: 'logout');
      } catch (e) {
        Logger.errorLog(text: 'UserProvider temizleme hatası (hata durumunda): $e', className: 'AuthRepositories', functionName: 'logout');
      }
    }

    try {
    //  await FakeUserDb.logout();
      Logger.info(text: 'FakeUserDb temizlendi (hata durumunda)', className: 'AuthRepositories', functionName: 'logout');
    } catch (e) {
      Logger.errorLog(text: 'FakeUserDb temizlenirken hata: $e', className: 'AuthRepositories', functionName: 'logout');
    }
  }
}
// ...existing code...



}