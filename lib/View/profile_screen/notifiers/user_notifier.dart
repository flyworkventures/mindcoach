import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/user_model.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart' as global_user_provider;

class UserState {
  final String fullName;
  final String email;
  final String phone;
  final String avatarAssetPath;
  final bool isLoading;
  final String? error;

  const UserState({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarAssetPath,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarAssetPath,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    // İlk yüklemede API'den kullanıcı bilgilerini çek
    _loadUserProfile();
    
    // Varsayılan değerler (API yüklenene kadar)
    return const UserState(
      fullName: '',
      email: '',
      phone: '',
      avatarAssetPath: 'assets/images/profile_avatar.jpeg',
      isLoading: true,
    );
  }

  /// API'den kullanıcı profil bilgilerini yükle
  Future<void> _loadUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final httpService = HttpService(ref: ref);
      final response = await httpService.get(
        path: AppConstants.getUserProfileURL,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final userData = json['data']['user'];
          
          // Email'i credentialData'dan al
          String email = '';
          if (userData['credentialData'] != null) {
            final credentialData = userData['credentialData'];
            if (credentialData is Map) {
              email = credentialData['email'] ?? '';
            }
          }
          
          // FullName için username kullan (veya başka bir field)
          String fullName = userData['username'] ?? '';
          
          // Phone için şimdilik boş (API'de phone field'ı yok)
          String phone = '';
          
          state = state.copyWith(
            fullName: fullName,
            email: email,
            phone: phone,
            isLoading: false,
            error: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Kullanıcı bilgileri alınamadı',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'API hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Hata: $e',
      );
    }
  }

  /// Kullanıcı bilgilerini güncelle (API'ye gönder)
  Future<void> updateUser({
    String? fullName,
    String? email,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final httpService = HttpService(ref: ref);
      
      // API'ye gönderilecek body (username olarak fullName kullanılıyor)
      final body = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) {
        body['username'] = fullName.trim();
      }
      
      final response = await httpService.put(
        path: AppConstants.completeProfileURL,
        body: body.isNotEmpty ? body : null,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          // Başarılı güncelleme sonrası state'i güncelle
          state = state.copyWith(
            fullName: fullName?.trim() ?? state.fullName,
            email: email?.trim() ?? state.email,
            phone: phone?.trim() ?? state.phone,
            isLoading: false,
            error: null,
          );
          
          // Global user provider'ı da güncelle
          if (json['data'] != null && json['data']['user'] != null) {
            try {
              final userModel = UserModel.fromMap(json['data']['user']);
              ref.read(global_user_provider.userProvider.notifier).setUserModel(userModel);
            } catch (e) {
              // UserModel parse hatası olabilir, devam et
            }
          }
        } else {
          state = state.copyWith(
            isLoading: false,
            error: json['error'] ?? 'Güncelleme başarısız',
          );
        }
      } else {
        final errorBody = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'error': 'Bilinmeyen hata'};
        state = state.copyWith(
          isLoading: false,
          error: errorBody['error'] ?? 'API hatası: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Hata: $e',
      );
      rethrow;
    }
  }

  void setAvatar(String assetPath) {
    state = state.copyWith(avatarAssetPath: assetPath);
  }
  
  /// Profil bilgilerini yeniden yükle
  Future<void> refreshProfile() async {
    await _loadUserProfile();
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
