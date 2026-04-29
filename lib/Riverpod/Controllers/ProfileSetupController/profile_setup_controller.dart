import 'dart:convert';
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

class ProfileSetupController extends StateNotifier<ProfileSetupState> {
  Ref ref;
  final LocalDbService _localDbService = LocalDbService();

  ProfileSetupController(this.ref) : super(const ProfileSetupState()) {
    // Controller olusturulur olusturulmaz local storage'taki onceden girilen
    // profile setup verisini yukle (uygulama yeniden acildiginda da kaybolmasin)
    Future.microtask(_loadFromLocalDb);
  }

  void setFullName(String name) {
    state = state.copyWith(fullName: name);
    debugPrint("Username: $name");
    _persistState();
  }

  // Nullable Gender kabul edecek şekilde güncellendi
  void setGender(Gender? gender) {
    state = state.copyWith(gender: gender);
    _persistState();
  }

  void setDob(DateTime? dob) {
    state = state.copyWith(dob: dob);
    _persistState();
  }

  void setSupportArea(SupportArea area) {
    state = state.copyWith(supportArea: area);
    _persistState();
  }

  void setApproach(ApproachType approach) {
    state = state.copyWith(approach: approach);
    _persistState();
  }

  Future<void> initFromUser() async {
    try {
      // 0. Once local storage'tan onceden kaydedilmis profile setup verisini yukle
      await _loadFromLocalDb();

      // Önce userProvider'dan kullanıcı bilgisini al
      var userModel = ref.read(AllProviders.userProvider);

      log(
        "Username and Token: ${userModel?.credential}, ${userModel?.token}. Ref: var",
      );

      // Eğer userProvider'da kullanıcı yoksa, token'dan çek
      if (userModel == null) {
        log(
          "⚠️ [PROFILE-SETUP] UserProvider'da kullanıcı yok, token'dan çekiliyor...",
        );
        final localDbService = LocalDbService();
        final token = await localDbService.getString(key: LocalDbKeys.token);

        if (token != null && token.isNotEmpty) {
          try {
            final authRepository = AuthRepositories(ref: ref);
            userModel = await authRepository.verifyUserByToken(token);

            if (userModel != null) {
              log(
                "✅ [PROFILE-SETUP] Token'dan kullanıcı çekildi: ${userModel.id}",
              );
              // UserProvider'a set et
              ref
                  .read(AllProviders.userProvider.notifier)
                  .setUserModel(userModel.copyWith(token: token));
            } else {
              log(
                "⚠️ [PROFILE-SETUP] Token geçersiz veya kullanıcı bulunamadı",
              );
            }
          } catch (e) {
            log("❌ [PROFILE-SETUP] Token'dan kullanıcı çekme hatası: $e");
          }
        } else {
          log("⚠️ [PROFILE-SETUP] Token bulunamadı");
        }
      }

      // Onboarding sirasinda kullanici zaten bir isim girdi ise (localden geldi),
      // backendten gelen username'in uzerine yazma. Aksi halde backendden gelen
      // username'i kullan.
      if (state.fullName.trim().isEmpty &&
          userModel != null &&
          userModel.username != null &&
          userModel.username!.isNotEmpty) {
        log("✅ [PROFILE-SETUP] Username set ediliyor: ${userModel.username}");
        state = state.copyWith(fullName: userModel.username!);
        _persistState();
        return;
      }

      // Username yoksa, Apple'dan gelen fullName'i kontrol et
      final localDbService = LocalDbService();
      final appleFullName = await localDbService.getString(
        key: LocalDbKeys.appleFullName,
      );

      if (appleFullName != null &&
          appleFullName.isNotEmpty &&
          state.fullName.isEmpty) {
        log("✅ [PROFILE-SETUP] Apple fullName set ediliyor: $appleFullName");
        state = state.copyWith(fullName: appleFullName);
        _persistState();
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
    _persistState();
  }

  void setMeetingTime(MeetingTime time) {
    state = state.copyWith(meetingTime: time);
    _persistState();
  }

  /// Onboarding'de toplanan veriyi local storage'a yaz. Boylece kullanici
  /// uygulamayi kapatip acsa bile yada login ekraninda Apple/Google ile giris
  /// yaparken ayni isim/cinsiyet/gun bilgisi backend'e gonderilebilir.
  Future<void> _persistState() async {
    try {
      final jsonString = jsonEncode(state.toJson());
      await _localDbService.setString(
        key: LocalDbKeys.profileSetupData,
        value: jsonString,
      );
    } catch (e) {
      log("⚠️ [PROFILE-SETUP] persistState hatasi: $e");
    }
  }

  Future<void> _loadFromLocalDb() async {
    try {
      final raw = await _localDbService.getString(
        key: LocalDbKeys.profileSetupData,
      );
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final restored = ProfileSetupState.fromJson(map);

      // Mevcut state default ise restore et. Kullanici bu session'da yeni veri
      // girmis ise (state.fullName boş değil vs.) onunla overwrite etme.
      final currentIsEmpty =
          state.fullName.trim().isEmpty && state.gender == null;
      if (currentIsEmpty) {
        state = restored;
        log(
          "✅ [PROFILE-SETUP] Local storage'tan profil verisi yuklendi: fullName=${restored.fullName}",
        );
      }
    } catch (e) {
      log("⚠️ [PROFILE-SETUP] loadFromLocalDb hatasi: $e");
    }
  }

  /// Profil verisi backend'e basariyla gonderildikten sonra local cache'i
  /// temizle, boylece sonraki kullanicilarin verisi karismaz.
  Future<void> _clearPersistedState() async {
    try {
      await _localDbService.deleteString(key: LocalDbKeys.profileSetupData);
    } catch (_) {}
  }

  /// Login akisindan once cagrilarak local storage'taki onceden girilmis
  /// profile setup verisini Riverpod state'ine yukler. Login basarili oldugunda
  /// completeProfile bu veriyi kullanir.
  Future<void> hydrateFromLocalIfNeeded() async {
    await _loadFromLocalDb();
  }

  Future<bool> completeProfile() async {
    try {
      AuthRepositories authRepository = AuthRepositories(ref: ref);

      List<String> avaibleDays = [];
      for (var element in state.availableDays) {
        String day = weekdayToString(element);
        avaibleDays.add(day);
      }

      // genderToString null dönerse varsayılan olarak 'unknown' ata
      final String genderString =
          genderToString(state.gender) ?? Gender.unknown.name;

      Logger.info(
        text:
            "Profil tamamlanıyor: username=${state.fullName}, gender=$genderString",
        className: "ProfileSetupController",
        functionName: "completeProfile",
      );

      bool success = await authRepository.completeProfile(
        state.fullName,
        genderString, // <-- Hata veren kısım düzeltildi (Artık kesin String gidiyor)
        avaibleDays,
        meetingTimeToString(state.meetingTime ?? MeetingTime.morning),
        supportAreaToString(state.supportArea ?? SupportArea.career),
        ApproachStrings.display(state.approach ?? ApproachType.convincing),
      );

      if (!success) {
        Logger.errorLog(
          text: "Profil tamamlama başarısız",
          className: "ProfileSetupController",
          functionName: "completeProfile",
        );

        return false;
      }

      LocalDbService localDbService = LocalDbService();
      String? token = await localDbService.getString(key: LocalDbKeys.token);
      UserModel? userModel = await authRepository.verifyUserByToken(token!);

      if (userModel != null) {
        Logger.info(
          text:
              "Kullanıcı bilgileri güncellendi: answerData=${userModel.answerData != null ? 'var' : 'null'}",
          className: "ProfileSetupController",
          functionName: "completeProfile",
        );
        ref
            .read(AllProviders.userProvider.notifier)
            .setUserModel(userModel.copyWith(token: token));

        // Profil tamamlandıktan sonra app status'u authenticated'a güncelle
        if (userModel.answerData != null) {
          Logger.info(
            text: "Profil tamamlandı, authenticated'a yönlendiriliyor",
            className: "ProfileSetupController",
            functionName: "completeProfile",
          );
          // Backend'e ulasti, local cache'i temizle
          await _clearPersistedState();
        } else {
          Logger.errorLog(
            text: "⚠️ answerData hala null, profil tamamlanmamış sayılıyor",
            className: "ProfileSetupController",
            functionName: "completeProfile",
          );
        }
      } else {
        Logger.errorLog(
          text: "Kullanıcı bilgileri alınamadız",
          className: "ProfileSetupController",
          functionName: "completeProfile",
        );
      }

      return success;
    } catch (e) {
      Logger.errorLog(
        text: "Profil tamamlama hatası: $e",
        functionName: "completeProfile",
        className: "ProfileSetupController",
      );
      return false;
    }
  }
}

class ProfileSetupState {
  final String fullName;
  final Gender? gender; // <-- Nullable yapıldı
  final DateTime? dob;
  final SupportArea? supportArea;
  final ApproachType? approach;
  final List<Weekday> availableDays;
  final MeetingTime? meetingTime;

  const ProfileSetupState({
    this.fullName = '',
    this.gender, // <-- Başlangıçta null (hiçbiri seçili değil) olması sağlandı
    this.dob,
    this.supportArea,
    this.approach,
    this.availableDays = const [],
    this.meetingTime,
  });

  ProfileSetupState copyWith({
    String? fullName,
    Gender? gender,
    DateTime? dob,
    Object? supportArea = _sentinel,
    Object? approach = _sentinel,
    List<Weekday>? availableDays,
    Object? meetingTime = _sentinel,
  }) {
    return ProfileSetupState(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      supportArea: identical(supportArea, _sentinel)
          ? this.supportArea
          : supportArea as SupportArea?,
      approach: identical(approach, _sentinel)
          ? this.approach
          : approach as ApproachType?,
      availableDays: availableDays ?? this.availableDays,
      meetingTime: identical(meetingTime, _sentinel)
          ? this.meetingTime
          : meetingTime as MeetingTime?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'gender': gender?.name,
      'dob': dob?.toIso8601String(),
      'supportArea': supportArea?.name,
      'approach': approach?.name,
      'availableDays': availableDays.map((d) => d.name).toList(),
      'meetingTime': meetingTime?.name,
    };
  }

  factory ProfileSetupState.fromJson(Map<String, dynamic> json) {
    return ProfileSetupState(
      fullName: (json['fullName'] as String?) ?? '',
      gender: genderFromString(json['gender'] as String?),
      dob: (json['dob'] is String && (json['dob'] as String).isNotEmpty)
          ? DateTime.tryParse(json['dob'] as String)
          : null,
      supportArea: ((json['supportArea'] as String?)?.trim().isEmpty ?? true)
          ? null
          : supportAreaFromString(json['supportArea'] as String),
      approach: ((json['approach'] as String?)?.trim().isEmpty ?? true)
          ? null
          : ApproachType.values.firstWhere(
              (e) => e.name == (json['approach'] as String?),
              orElse: () => ApproachType.convincing,
            ),
      availableDays: ((json['availableDays'] as List?) ?? const [])
          .map((e) => weekdayFromString(e.toString()))
          .toList(),
      meetingTime: ((json['meetingTime'] as String?)?.trim().isEmpty ?? true)
          ? null
          : meetingTimeFromString(json['meetingTime'] as String),
    );
  }
}

const Object _sentinel = Object();
