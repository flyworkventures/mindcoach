// ...existing code...
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/material.dart';
import 'package:in_app_notification/in_app_notification.dart';
import 'package:mindcoach/Enums/page_state.dart';
import 'package:mindcoach/Http/http_service.dart';
import 'package:mindcoach/Repositories/auth_repositories.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/View/OnboardView/onboarding_page.dart';
import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/app/navbar_provider.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/services/auth_service.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/models/user_model.dart';
 
 class ProfileSettingsController extends StateNotifier<PageState> {
  Ref ref;
   ProfileSettingsController(this.ref) : super(PageState.normal);

   AuthRepositories repo = AuthRepositories();
   
 
 
   Future<void> logout() async {
    AuthService authService = AuthService(ref: ref);

     try {
      state = PageState.loading;
     debugPrint('Logout başlatılıyor...');
    Logger.info(text: 'logout başlatılıyor', className: 'ProfileSettingsController', functionName: 'logout');
     await repo.logout();
        Logger.info(text: 'calling repo.logout()', className: 'ProfileSettingsController', functionName: 'logout');

      await authService.clearSession();
      Logger.info(text: 'Session Temizlendi', className: 'ProfileSettingsController', functionName: 'logout');
      ref.read(bottomNavProvider.notifier).setTab(0);
      state = PageState.normal;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(PageRoutes.onboarding, (a)=> false);
  Logger.info(text: 'Navigated to Onboarding and cleared routes', className: 'ProfileSettingsController', functionName: 'logout');

     } catch (e, st) {
      Logger.info(text: '🔴 Error $e', className: 'ProfileSettingsController', functionName: 'logout');
     }




   }



   updateUsername({required String name,required String savedInfoText,required BuildContext context})async{
      try {
                                final httpService = HttpService(ref: ref);
                                final body = {
                                  'username': name,
                                };
                                
                                final response = await httpService.put(
                                  path: AppConstants.completeProfileURL,
                                  body: body,
                                );
                                
                                if (response.statusCode == 200) {
                                  final json = jsonDecode(response.body);
                                  if (json['success'] == true && json['data'] != null) {
                                    // UserModel'i güncelle
                                    final userModel = UserModel.fromMap(json['data']['user']);
                                    // Token'ı koru
                                    final currentUser = ref.read(AllProviders.userProvider);
                                    final updatedUser = userModel.copyWith(
                                      token: currentUser?.token,
                                    );
                                    ref.read(AllProviders.userProvider.notifier).setUserModel(updatedUser);
                                         ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text( "Güncellendi"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    if (mounted) {
                                   
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(savedInfoText),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Güncelleme başarısız'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
   }
 
 
   
 }
 // ...existing code...