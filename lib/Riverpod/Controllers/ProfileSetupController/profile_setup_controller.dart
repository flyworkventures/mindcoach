import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Repositories/auth_repositories.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/View/ProfileSetupView/constants/approach_strings.dart';
import 'package:mindcoach/View/ProfileSetupView/domain/profile_models.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:mindcoach/models/user_model.dart';

class ProfileSetupController extends StateNotifier<ProfileSetupState>{
  Ref ref;
  ProfileSetupController(this.ref):super(ProfileSetupState());



  void setFullName(String name){

    state = state.copyWith(fullName: name);
    debugPrint("Username: $name");
  }

  void setGender(Gender gender) => state = state.copyWith(gender: gender);

  void setDob(DateTime? dob) => state = state.copyWith(dob: dob);

  void setSupportArea(SupportArea area) => state = state.copyWith(supportArea: area);

  void setApproach(ApproachType approach) => state = state.copyWith(approach: approach);




  Future<void> initFromUser() async {
    try {
      // Önce userProvider'dan kullanıcı bilgisini al
      var userModel = ref.read(AllProviders.userProvider);
      
      log("Username and Token: ${userModel?.credential}, ${userModel?.token}. Ref: var");
      
      // Eğer userProvider'da kullanıcı yoksa, token'dan çek
      if (userModel == null) {
        log("⚠️ [PROFILE-SETUP] UserProvider'da kullanıcı yok, token'dan çekiliyor...");
        final localDbService = LocalDbService();
        final token = await localDbService.getString(key: LocalDbKeys.token);
        
        if (token != null && token.isNotEmpty) {
          try {
            final authRepository = AuthRepositories(ref: ref);
            userModel = await authRepository.verifyUserByToken(token);
            
            if (userModel != null) {
              log("✅ [PROFILE-SETUP] Token'dan kullanıcı çekildi: ${userModel.id}");
              // UserProvider'a set et
              ref.read(AllProviders.userProvider.notifier).setUserModel(userModel.copyWith(token: token));
            } else {
              log("⚠️ [PROFILE-SETUP] Token geçersiz veya kullanıcı bulunamadı");
            }
          } catch (e) {
            log("❌ [PROFILE-SETUP] Token'dan kullanıcı çekme hatası: $e");
          }
        } else {
          log("⚠️ [PROFILE-SETUP] Token bulunamadı");
        }
      }
      
      // Kullanıcı bilgisini kullan
      if (userModel != null && userModel.username != null && userModel.username!.isNotEmpty) {
        log("✅ [PROFILE-SETUP] Username set ediliyor: ${userModel.username}");
        state = state.copyWith(fullName: userModel.username!);
        return;
      }
      
      // Username yoksa, Apple'dan gelen fullName'i kontrol et
      final localDbService = LocalDbService();
      final appleFullName = await localDbService.getString(key: LocalDbKeys.appleFullName);
      
      if (appleFullName != null && appleFullName.isNotEmpty && state.fullName.isEmpty) {
        log("✅ [PROFILE-SETUP] Apple fullName set ediliyor: $appleFullName");
        state = state.copyWith(fullName: appleFullName);
        // Kullanıldıktan sonra temizle
        await localDbService.deleteString(key: LocalDbKeys.appleFullName);
        return;
      }
      
      log("⚠️ [PROFILE-SETUP] Kullanıcı adı bulunamadı, boş bırakılıyor");
    } catch (e, stackTrace) {
      log("❌ [PROFILE-SETUP] initFromUser hatası: $e");
      log("❌ [PROFILE-SETUP] Stack trace: $stackTrace");
    }
  }




  void toggleDay(Weekday day) {
    final days = List<Weekday>.from(state.availableDays);
    days.contains(day) ? days.remove(day) : days.add(day);
    state = state.copyWith(availableDays: days);
  }

  void setMeetingTime(MeetingTime time) => state = state.copyWith(meetingTime: time);

  Future<bool> completeProfile()async{
try {
          AuthRepositories authRepository = AuthRepositories(ref: ref);

    List<String> avaibleDays = [];
    for (var element in state.availableDays) {
      String day = weekdayToString(element);
      avaibleDays.add(day);
    }
    

    Logger.info(text: "Profil tamamlanıyor: username=${state.fullName}, gender=${genderToString(state.gender)}",className: "ProfileSetupController",functionName: "completeProfile");
    
    bool success = await authRepository.completeProfile(
      state.fullName, 
      genderToString(state.gender),  
      avaibleDays,
      meetingTimeToString(state.meetingTime), 
      supportAreaToString(state.supportArea),
      ApproachStrings.display(state.approach),
    );
    
    if (!success) {
      Logger.errorLog(text: "Profil tamamlama başarısız",className: "ProfileSetupController",functionName: "completeProfile");

      return false;
    }
    
    LocalDbService localDbService = LocalDbService();
    String? token = await localDbService.getString(key: LocalDbKeys.token);
    UserModel? userModel = await authRepository.verifyUserByToken(token!);
    
    if (userModel != null) {
       Logger.info(text: "Kullanıcı bilgileri güncellendi: answerData=${userModel.answerData != null ? 'var' : 'null'}",className: "ProfileSetupController",functionName: "completeProfile");
      ref.read(AllProviders.userProvider.notifier).setUserModel(userModel.copyWith(token: token));
      
      // Profil tamamlandıktan sonra app status'u authenticated'a güncelle
      if (userModel.answerData != null) {
         Logger.info(text: "Profil tamamlandı, authenticated'a yönlendiriliyor",className: "ProfileSetupController",functionName: "completeProfile");

      
      } else {
        Logger.errorLog(text: "⚠️ answerData hala null, profil tamamlanmamış sayılıyor",className: "ProfileSetupController",functionName: "completeProfile");
      }
    } else {
      Logger.errorLog(text: "Kullanıcı bilgileri alınamadız",className: "ProfileSetupController",functionName: "completeProfile");

    }
    
    return success;
} catch (e) {
  Logger.errorLog(text: "Profil tamamlama hatası: $e",functionName: "completeProfile",className: "ProfileSetupController");
  return false;
}

  }



  
}



class ProfileSetupState {
  final String fullName;
  final Gender gender;
  final DateTime? dob;
  final SupportArea supportArea;
  final ApproachType approach;
  final List<Weekday> availableDays;
  final MeetingTime meetingTime;

  const ProfileSetupState({
    this.fullName = '',
    this.gender = Gender.male,
    this.dob,
    this.supportArea = SupportArea.career,
    this.approach = ApproachType.convincing,
    this.availableDays = const [Weekday.monday, Weekday.wednesday, Weekday.friday],
    this.meetingTime = MeetingTime.morning,
  });

  ProfileSetupState copyWith({
    String? fullName,
    Gender? gender,
    DateTime? dob,
    SupportArea? supportArea,
    ApproachType? approach,
    List<Weekday>? availableDays,
    MeetingTime? meetingTime,
  }) {
    return ProfileSetupState(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      supportArea: supportArea ?? this.supportArea,
      approach: approach ?? this.approach,
      availableDays: availableDays ?? this.availableDays,
      meetingTime: meetingTime ?? this.meetingTime,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      // Enum'lar genellikle backend'e string isimleri ile gönderilir
      'gender': gender.name,
      'dob': dob?.toIso8601String(),
      'supportArea': supportArea.name,
      'approach': approach.name,
      // Set<Weekday> --> List<String>
      'availableDays': availableDays.map((d) => d.name).toList(),
      'meetingTime': meetingTime.name,
    };
  }
}

