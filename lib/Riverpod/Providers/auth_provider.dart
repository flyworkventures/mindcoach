// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';

import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/View/auth/domain/social_login_provider.dart';
import 'package:mindcoach/core/repo/auth_repository.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:mindcoach/Http/http_service.dart';
import 'package:mindcoach/models/user_model.dart';

class AuthProvider extends StateNotifier{
  Ref? ref;
  AuthProvider(this.ref): super(0);

  final authRepo = AuthRepository();
  final localDbService = LocalDbService();


  Future<UserModel?> login(SocialLoginProvider provider)async{
  HandleLoginModel loginModel =  await handleLogin(provider);
  UserModel? userModel = await sendAPI(loginModel);
  ref?.read(AllProviders.userProvider.notifier).setUserModel(userModel);

  return userModel;
  }


  Future<HandleLoginModel> handleLogin(SocialLoginProvider provider) async{
    
   // final httpService = HttpService(ref: ref);
    String? apiPath;
    dynamic result;
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
        
        /*
          result = await authRepo.facebookSignIn();
          if (result == null || result['accessToken'] == null) {
            throw Exception('Facebook login failed');
          }
          */
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

          if (result['fullName'] != null && result['fullName'].toString().isNotEmpty) {
            await localDbService.setString(
              key: LocalDbKeys.appleFullName,
              value: result['fullName'].toString(),
            );
          
          }
          break;
          
        case SocialLoginProvider.guest:
          // Cihaza özgü sabit guest ID — her zaman aynı hesaba döner
          String? savedGuestId = await localDbService.getString(key: LocalDbKeys.guestDeviceId);
          if (savedGuestId == null || savedGuestId.isEmpty) {
            // İlk kez: rastgele ama kalıcı bir ID oluştur
            final ts = DateTime.now().millisecondsSinceEpoch;
            final rand = ts.toRadixString(36) +
                ts.hashCode.abs().toRadixString(36);
            savedGuestId = 'guest_device_$rand';
            await localDbService.setString(
              key: LocalDbKeys.guestDeviceId,
              value: savedGuestId,
            );
            debugPrint('🆕 [GUEST] Yeni cihaz ID oluşturuldu: $savedGuestId');
          } else {
            debugPrint('♻️ [GUEST] Mevcut cihaz ID kullanılıyor: $savedGuestId');
          }
          apiPath = AppConstants.guestAuth;
          body = {'deviceId': savedGuestId};
          // Guest login için token göndermemeli (Authorization header'ı olmamalı)
          break;
      }
            final Map<String, String>? customHeaders = provider == SocialLoginProvider.guest
          ? {'Content-Type': 'application/json'} // Sadece Content-Type, Authorization yok
          : null; // Diğer durumlarda default header kullan (Authorization ile)

       debugPrint("Auth Model: 'result': $result, apiPath: $apiPath, body: $body, header: $customHeaders");
      return HandleLoginModel(result: result,apiPath: apiPath,body: body,header: customHeaders);
  }


 Future<UserModel?> sendAPI(HandleLoginModel loginModel) async{
  final httpService = HttpService(ref: ref);
        final response = await httpService.post(
        path: loginModel.apiPath!,
        body: loginModel.body ?? {},
        headers: loginModel.header,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final token = json['data']['token'];
          final userData = json['data']['user'];
          
          // Token'ı kaydet
          await localDbService.setString(key: LocalDbKeys.token, value: token);
 
          // User bilgisini de kaydet (UserProvider'a set etmek için)
          if (userData != null) {
             final userModel = UserModel.fromMap(userData);
              final userModelWithToken = userModel.copyWith(token: token);
              return userModelWithToken;
          }else {
         return null;
          
        }
        } else {
         return null;
          
        }
      } else {
         return null;
      }
 }




Future logout() async{

   
      final httpService = HttpService(ref: ref);
      Logger.info(text: "API isteği gönderiliyor: ${AppConstants.logoutURL}",className: "AuthProvider",functionName: "logout");
      
      final response = await httpService.post(
        path: AppConstants.logoutURL,
      );
        Logger.info(text: "API yanıtı: ${response.statusCode}",className: "AuthProvider",functionName: "logout");
      
      // Token'ı local storage'dan sil (başarılı olsun olmasın)
      final localDbService = LocalDbService();
      await localDbService.deleteString(key: LocalDbKeys.token);
       Logger.info(text: "Token local storage'dan silindi",className: "AuthProvider",functionName: "logout");
      
      // UserProvider'ı temizle
      if (ref != null) {
        try {
          ref?.read(AllProviders.userProvider.notifier).setUserModel(null);
          Logger.info(text: " UserProvider temizlendi",className: "AuthProvider",functionName: "logout");
        } catch (e) {
            Logger.errorLog(text: "[LOGOUT] UserProvider temizleme hatası: $e",className: "AuthProvider",functionName: "logout");
        }
      }
    
}




}



class HandleLoginModel {
    String? apiPath;
    dynamic result;
    Map<String, dynamic>? body;
    Map<String, String>? header;
  HandleLoginModel({
    this.apiPath,
    required this.result,
    this.body,
    this.header
  });
}


