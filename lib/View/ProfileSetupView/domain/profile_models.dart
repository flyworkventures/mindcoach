enum Gender { male, female, unknown }

enum SupportArea { individual, family, career, education, personalDevelopment }

enum MeetingTime { morning, afternoon, evening, flexible }

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

// --- GÜNCELLEDİĞİM KISIM ---

String? genderToString(Gender? g) => g?.name;

// Eğer gelen string boşsa null dön, böylece hiçbir şey seçili olmaz
Gender? genderFromString(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  return Gender.values.firstWhere(
    (e) => e.name == s,
    orElse: () => Gender.unknown,
  );
}

// ---------------------------

String supportAreaToString(SupportArea s) => s.name;
SupportArea supportAreaFromString(String s) => SupportArea.values.firstWhere(
  (e) => e.name == s,
  orElse: () => SupportArea.career,
);

String meetingTimeToString(MeetingTime m) => m.name;
MeetingTime meetingTimeFromString(String s) => MeetingTime.values.firstWhere(
  (e) => e.name == s,
  orElse: () => MeetingTime.morning,
);

String weekdayToString(Weekday w) => w.name;
Weekday weekdayFromString(String s) =>
    Weekday.values.firstWhere((e) => e.name == s, orElse: () => Weekday.monday);

// Helpers for converting collections of weekdays (the state stores a Set<Weekday>)
List<String> weekdaySetToList(Set<Weekday> set) =>
    set.map((d) => d.name).toList();
Set<Weekday> weekdaySetFromList(List<dynamic>? list) {
  if (list == null) return <Weekday>{};
  return list.map((e) => weekdayFromString(e as String)).toSet();
}
