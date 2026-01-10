import '../../auth/domain/social_login_provider.dart';
import '../constants/approach_strings.dart';


enum Gender { male, female, unknown }

enum SupportArea { individual, family, career, education, personalDevelopment }

enum MeetingTime { morning, afternoon, evening, flexible }

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

// --- Enum <-> String helpers ---
// Simple helpers to convert enums to string and back. Useful when serializing
// to/from backend or local storage.

String genderToString(Gender g) => g.name;
Gender genderFromString(String s) => Gender.values.firstWhere((e) => e.name == s, orElse: () => Gender.male);

String supportAreaToString(SupportArea s) => s.name;
SupportArea supportAreaFromString(String s) => SupportArea.values.firstWhere((e) => e.name == s, orElse: () => SupportArea.career);

String meetingTimeToString(MeetingTime m) => m.name;
MeetingTime meetingTimeFromString(String s) => MeetingTime.values.firstWhere((e) => e.name == s, orElse: () => MeetingTime.morning);

String weekdayToString(Weekday w) => w.name;
Weekday weekdayFromString(String s) => Weekday.values.firstWhere((e) => e.name == s, orElse: () => Weekday.monday);

// Helpers for converting collections of weekdays (the state stores a Set<Weekday>)
List<String> weekdaySetToList(Set<Weekday> set) => set.map((d) => d.name).toList();
Set<Weekday> weekdaySetFromList(List<dynamic>? list) {
  if (list == null) return <Weekday>{};
  return list.map((e) => weekdayFromString(e as String)).toSet();
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



