import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';


import 'package:mindcoach/models/user_model.dart';

import '../../../core/repo/auth_repository.dart';
import '../../../Riverpod/providers/user_provider.dart';
import '../../../core/config/app_status_notifier.dart';
import '../domain/profile_models.dart';
import '../constants/approach_strings.dart';

/// ProfileSetupNotifier
/// ------------------------------------------------------------
/// Profile setup akışının state yönetimi.
/// UI doğrudan state’i değiştirmez; notifier üzerinden gider.
///
/// TODO(Persistence):
/// - N8N geldiğinde burada “saveProfile()” ekleyip
///   repository üzerinden server’a yazacağız.
/// - UI aynı kalır.
class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  Ref? ref;
  ProfileSetupNotifier({this.ref}) : super(ProfileSetupState());

  Future<void> initFromUser() async {
    if (ref != null) {
      // Önce Apple'dan gelen fullName'i kontrol et
      final localDbService = LocalDbService();
      final appleFullName = await localDbService.getString(key: LocalDbKeys.appleFullName);
      
      if (appleFullName != null && appleFullName.isNotEmpty && state.fullName.isEmpty) {
        state = state.copyWith(fullName: appleFullName);
        // Kullanıldıktan sonra temizle
        await localDbService.deleteString(key: LocalDbKeys.appleFullName);
        return;
      }
      
      // Apple fullName yoksa, username'i kullan (fallback)
      final user = ref!.read(userProvider);
      if (user?.username != null && user!.username!.isNotEmpty) {
        // Eğer fullName boşsa, username'i kullan
        if (state.fullName.isEmpty) {
          state = state.copyWith(fullName: user.username!);
        }
      }
    }
  }

  void setFullName(String name) => state = state.copyWith(fullName: name);

  void setGender(Gender gender) => state = state.copyWith(gender: gender);

  void setDob(DateTime? dob) => state = state.copyWith(dob: dob);

  void setSupportArea(SupportArea area) => state = state.copyWith(supportArea: area);

  void setApproach(ApproachType approach) => state = state.copyWith(approach: approach);

  void toggleDay(Weekday day) {
    final days = List<Weekday>.from(state.availableDays);
    days.contains(day) ? days.remove(day) : days.add(day);
    state = state.copyWith(availableDays: days);
  }

  void setMeetingTime(MeetingTime time) => state = state.copyWith(meetingTime: time);

  Future<bool> completeProfile()async{
try {
          AuthRepository authRepository = AuthRepository();

    List<String> avaibleDays = [];
    for (var element in state.availableDays) {
      String day = weekdayToString(element);
      avaibleDays.add(day);
    }
    
    debugPrint("📝 Profil tamamlanıyor: username=${state.fullName}, gender=${genderToString(state.gender)}");
    
    bool success = await authRepository.completeProfile(
      state.fullName, 
      genderToString(state.gender),  
      avaibleDays,
      meetingTimeToString(state.meetingTime), 
      supportAreaToString(state.supportArea),
      ApproachStrings.display(state.approach),
      ref!
    );
    
    if (!success) {
      debugPrint("❌ Profil tamamlama başarısız");
      return false;
    }
    
    LocalDbService localDbService = LocalDbService();
    String? token = await localDbService.getString(key: LocalDbKeys.token);
    UserModel? userModel = await authRepository.verifyUserByToken(token!);
    
    if (userModel != null) {
      debugPrint("✅ Kullanıcı bilgileri güncellendi: answerData=${userModel.answerData != null ? 'var' : 'null'}");
      ref?.read(userProvider.notifier).setUserModel(userModel.copyWith(token: token));
      
      // Profil tamamlandıktan sonra app status'u authenticated'a güncelle
      if (userModel.answerData != null) {
        debugPrint("✅ Profil tamamlandı, authenticated'a yönlendiriliyor");
      
      } else {
        debugPrint("⚠️ answerData hala null, profil tamamlanmamış sayılıyor");
      }
    } else {
      debugPrint("❌ Kullanıcı bilgileri alınamadı");
    }
    
    return success;
} catch (e, stackTrace) {
  debugPrint("❌ Profil tamamlama hatası: $e");
  debugPrint("📍 Stack trace: $stackTrace");
  return false;
}

  }

}

final profileSetupProvider =
StateNotifierProvider<ProfileSetupNotifier, ProfileSetupState>((ref)=> ProfileSetupNotifier(ref: ref));
