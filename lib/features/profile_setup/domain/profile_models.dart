import '../../auth/domain/social_login_provider.dart';
import '../constants/approach_strings.dart';

/// ProfileSetup domain modelleri
/// ------------------------------------------------------------
/// UI ve backend arasında “kanonik” veri taşıyacak yapılar.
/// String yerine enum kullanarak typo/locale buglarını engelleriz.
///
/// TODO(N8N):
/// - Bu state server’a yazılıp okunacak.
/// - Mapping tek noktada yapılacak (swap kolay).
enum Gender { male, female }

enum SupportArea { individual, family, career, education, personalDevelopment }

enum MeetingTime { morning, afternoon, evening, flexible }

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class ProfileSetupState {
  final String fullName;
  final Gender gender;
  final DateTime? dob;
  final SupportArea supportArea;
  final ApproachType approach;
  final Set<Weekday> availableDays;
  final MeetingTime meetingTime;

  const ProfileSetupState({
    this.fullName = '',
    this.gender = Gender.male,
    this.dob,
    this.supportArea = SupportArea.career,
    this.approach = ApproachType.convincing,
    this.availableDays = const {Weekday.monday, Weekday.wednesday, Weekday.friday},
    this.meetingTime = MeetingTime.morning,
  });

  ProfileSetupState copyWith({
    String? fullName,
    Gender? gender,
    DateTime? dob,
    SupportArea? supportArea,
    ApproachType? approach,
    Set<Weekday>? availableDays,
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
