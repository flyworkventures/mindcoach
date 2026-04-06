import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Enums/user_state.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/models/user_model.dart';




class UserProvider extends StateNotifier<UserModel?> {
  UserProvider():super(null){
    debugPrint("Userprovider called ${hashCode}");
  }
  
  void setUserModel(UserModel? userModel){
    state = userModel;
    Logger.info(text: "User Id:${state?.id}",className: "UserProvider",functionName: "setUserModel");
  }

 UserState getUserState(){
                 
        final hasCompletedProfile = state?.answerData != null;
        if (hasCompletedProfile) {
          return UserState.profileMissing;
        }else if(state == null){
          return UserState.notAuth;
        }else{
          return UserState.auth;
        }
  }

}

