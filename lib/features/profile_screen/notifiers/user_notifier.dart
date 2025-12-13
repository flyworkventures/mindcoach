import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final String fullName;
  final String email;
  final String phone;
  final String avatarAssetPath;

  const UserState({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarAssetPath,
  });

  UserState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarAssetPath,
  }) {
    return UserState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarAssetPath: avatarAssetPath ?? this.avatarAssetPath,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState(
      fullName: 'Hasan Özgür Özdemir',
      email: 'team@fly-work.com',
      phone: '+90 5xx xxx xx xx',
      avatarAssetPath: 'assets/images/profile_avatar.jpeg',
    );
  }

  void updateUser({
    String? fullName,
    String? email,
    String? phone,
  }) {
    state = state.copyWith(
      fullName: fullName?.trim(),
      email: email?.trim(),
      phone: phone?.trim(),
    );
  }

  void setAvatar(String assetPath) {
    state = state.copyWith(avatarAssetPath: assetPath);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);
