import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart';
import 'package:mindcoach/models/user_model.dart';

class AllProviders {
  static final userProvider = StateNotifierProvider<UserProvider,UserModel?>((_)=>  UserProvider());
}
