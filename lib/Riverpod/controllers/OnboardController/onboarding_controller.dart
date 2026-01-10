import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mindcoach/core/repo/auth_repository.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/user_model.dart';

final onboardingController = StateNotifierProvider((ref)=>OnboardingController(ref));

class OnboardingController extends StateNotifier{
  Ref? ref;
  OnboardingController(this.ref): super(0);


  AuthRepository authRepository = AuthRepository();

  Future signInGoogle() async{
   dynamic token = await authRepository.googleSignIn();
   if (token != false) {
    debugPrint("Auth not null"); 
debugPrint("token: $token");
    UserModel? userModel = await authRepository.verifyUserByToken(token);
     if (userModel != null) {
       log("User Model is not null");
         if (userModel.answerData != null) {
           // attokmak bull
         } else {
           
         }
     } else {
       
     }
   }else{
        debugPrint("Auth  null");
        

   }
  }
}