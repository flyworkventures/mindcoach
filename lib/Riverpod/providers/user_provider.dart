import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/models/user_model.dart';




class UserProvider extends StateNotifier<UserModel?> {
  UserProvider():super(null);
  
  void setUserModel(UserModel? userModel){
    state = userModel;
  }

}
final  userProvider = StateNotifierProvider<UserProvider,UserModel?>((_)=> UserProvider());
