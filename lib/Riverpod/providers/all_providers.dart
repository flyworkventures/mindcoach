import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Riverpod/Providers/auth_provider.dart';
import 'package:mindcoach/Riverpod/Providers/premium_provider.dart' as premium_module;
import 'package:mindcoach/Riverpod/Providers/user_provider.dart';
import 'package:mindcoach/models/user_model.dart';
import 'package:mindcoach/models/premium_state.dart';

class AllProviders {
  static final userProvider = StateNotifierProvider<UserProvider,UserModel?>((ref)=>  UserProvider());
  static final authProvider = StateNotifierProvider((ref)=>  AuthProvider(ref));

  // ⭐ Device-based premium provider (new system)
  // Note: This now returns PremiumState instead of bool
  // Use: ref.watch(AllProviders.premiumProvider).isPremium for boolean check
  static final premiumProvider = premium_module.premiumProvider;
}
