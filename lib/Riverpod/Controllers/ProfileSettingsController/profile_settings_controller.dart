// ...existing code...
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Enums/page_state.dart';
import 'package:mindcoach/Http/http_service.dart';
import 'package:mindcoach/Repositories/auth_repositories.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/app/navbar_provider.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/services/auth_service.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
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
      Logger.info(
        text: 'logout başlatılıyor',
        className: 'ProfileSettingsController',
        functionName: 'logout',
      );
      await repo.logout();
      Logger.info(
        text: 'calling repo.logout()',
        className: 'ProfileSettingsController',
        functionName: 'logout',
      );

      await authService.clearSession();
      Logger.info(
        text: 'Session Temizlendi',
        className: 'ProfileSettingsController',
        functionName: 'logout',
      );
      ref.read(bottomNavProvider.notifier).setTab(0);
      state = PageState.normal;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        PageRoutes.login,
        (a) => false,
      );
      Logger.info(
        text: 'Navigated to Onboarding and cleared routes',
        className: 'ProfileSettingsController',
        functionName: 'logout',
      );
    } catch (e, st) {
      Logger.info(
        text: '🔴 Error $e',
        className: 'ProfileSettingsController',
        functionName: 'logout',
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    String? age,
    required String successText,
    required String errorText,
    required BuildContext context,
  }) async {
    try {
      final httpService = HttpService(ref: ref);
      final body = <String, dynamic>{'username': name};
      if (age != null && age.trim().isNotEmpty) {
        body['age'] = int.tryParse(age.trim()) ?? age.trim();
      }

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
          final updatedUser = userModel.copyWith(token: currentUser?.token);
          ref
              .read(AllProviders.userProvider.notifier)
              .setUserModel(updatedUser);

          // Username'i local cache'e kaydet (restart sonrası da kalıcı olsun)
          await LocalDbService().setString(
            key: LocalDbKeys.savedUsername,
            value: name,
          );

          // Başarı mesajı göster, ardından profile ekranına dön
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successText),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorText), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText), backgroundColor: Colors.red),
      );
    }
  }
}
 // ...existing code...