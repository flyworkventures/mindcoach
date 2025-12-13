import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class ProfileSetupNotifier extends Notifier<ProfileSetupState> {
  @override
  ProfileSetupState build() => const ProfileSetupState();

  void setFullName(String name) => state = state.copyWith(fullName: name);

  void setGender(Gender gender) => state = state.copyWith(gender: gender);

  void setDob(DateTime? dob) => state = state.copyWith(dob: dob);

  void setSupportArea(SupportArea area) => state = state.copyWith(supportArea: area);

  void setApproach(ApproachType approach) => state = state.copyWith(approach: approach);

  void toggleDay(Weekday day) {
    final days = Set<Weekday>.from(state.availableDays);
    days.contains(day) ? days.remove(day) : days.add(day);
    state = state.copyWith(availableDays: days);
  }

  void setMeetingTime(MeetingTime time) => state = state.copyWith(meetingTime: time);
}

final profileSetupProvider =
NotifierProvider<ProfileSetupNotifier, ProfileSetupState>(ProfileSetupNotifier.new);
