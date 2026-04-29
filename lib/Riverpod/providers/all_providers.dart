import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Riverpod/Providers/auth_provider.dart';
import 'package:mindcoach/Riverpod/Providers/premium_provider.dart';
import 'package:mindcoach/Riverpod/Providers/user_provider.dart';
import 'package:mindcoach/models/user_model.dart';

class AllProviders {
  static final userProvider = StateNotifierProvider<UserProvider,UserModel?>((ref)=>  UserProvider());
  static final authProvider = StateNotifierProvider((ref)=>  AuthProvider(ref));
  static final premiumProvider = StateNotifierProvider((ref)=>  PremiumProvider(ref));
}
