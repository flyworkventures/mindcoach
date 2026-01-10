
class UserModel {
  final int id;
  final String credential;
  final dynamic credentialData;
  final String username;
  final String? nativeLang;
  final String gender; // male female unknown
  final QuestionAnswers answerData;
  final String? lastPsychologicalProfile; // son psikolojik profili
  final List? userAgentNotes; // görüşmeler sonrasında ai notları;
  final List? leastSessions;
  final String? psychologicalProfileBasedOnMessages;
  final String accountCreatedDate;
  final String? generalProfile;
  final String? generalPsychologicalProfile;
  final String? profilePhotoUrl;
  UserModel({
    required this.id,
    required this.credential,
    required this.credentialData,
    required this.username,
    this.nativeLang,
    required this.gender,
    required this.answerData,
    this.lastPsychologicalProfile,
    this.userAgentNotes,
    this.leastSessions,
    this.psychologicalProfileBasedOnMessages,
    required this.accountCreatedDate,
    this.generalProfile,
    this.generalPsychologicalProfile,
    this.profilePhotoUrl
  });



  UserModel copyWith({
    int? id,
    String? credential,
    dynamic credentialData,
    String? username,
    String? nativeLang,
    String? gender,
    QuestionAnswers? answerData,
    String? lastPsychologicalProfile,
    List? userAgentNotes,
    List? leastSessions,
    String? psychologicalProfileBasedOnMessages,
    String? accountCreatedDate,
    String? generalProfile,
    String? generalPsychologicalProfile,
    String? profilePhotoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      credential: credential ?? this.credential,
      credentialData: credentialData ?? this.credentialData,
      username: username ?? this.username,
      nativeLang: nativeLang ?? this.nativeLang,
      gender: gender ?? this.gender,
      answerData: answerData ?? this.answerData,
      lastPsychologicalProfile: lastPsychologicalProfile ?? this.lastPsychologicalProfile,
      userAgentNotes: userAgentNotes ?? this.userAgentNotes,
      leastSessions: leastSessions ?? this.leastSessions,
      psychologicalProfileBasedOnMessages: psychologicalProfileBasedOnMessages ?? this.psychologicalProfileBasedOnMessages,
      accountCreatedDate: accountCreatedDate ?? this.accountCreatedDate,
      generalProfile: generalProfile ?? this.generalProfile,
      generalPsychologicalProfile: generalPsychologicalProfile ?? this.generalPsychologicalProfile,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'credential': credential,
      'credentialData': credentialData,
      'username': username,
      'nativeLang': nativeLang,
      'gender': gender,
      'answerData': answerData.toMap(),
      'lastPsychologicalProfile': lastPsychologicalProfile,
      'userAgentNotes': userAgentNotes,
      'leastSessions': leastSessions,
      'psychologicalProfileBasedOnMessages': psychologicalProfileBasedOnMessages,
      'accountCreatedDate': accountCreatedDate,
      'generalProfile': generalProfile,
      'generalPsychologicalProfile': generalPsychologicalProfile,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      credential: map['credential'] as String,
      credentialData: map['credentialData'] as dynamic,
      username: map['username'] as String,
      nativeLang: map['nativeLang'] != null ? map['nativeLang'] as String : null,
      gender: map['gender'] as String,
      answerData: QuestionAnswers.fromMap(map['answerData'] as Map<String,dynamic>),
      lastPsychologicalProfile: map['lastPsychologicalProfile'] != null ? map['lastPsychologicalProfile'] as String : null,
      userAgentNotes: map['userAgentNotes'],
      leastSessions: map['leastSessions'],
      psychologicalProfileBasedOnMessages: map['psychologicalProfileBasedOnMessages'] != null ? map['psychologicalProfileBasedOnMessages'] as String : null,
      accountCreatedDate: map['accountCreatedDate'] as String,
      generalProfile: map['generalProfile'] != null ? map['generalProfile'] as String : null,
      generalPsychologicalProfile: map['generalPsychologicalProfile'] != null ? map['generalPsychologicalProfile'] as String : null,
      profilePhotoUrl: map['profilePhotoUrl'],
    );
  }
  
}

class QuestionAnswers {
  final dynamic avaibleDays;
  final dynamic avaibleHours;
  final String supportArea;
  final String agentSpeakStyle; // yaklasim tarzi
  QuestionAnswers({
    required this.avaibleDays,
    required this.avaibleHours,
    required this.supportArea,
    required this.agentSpeakStyle,
  });
  

  QuestionAnswers copyWith({
    dynamic avaibleDays,
    dynamic avaibleHours,
    String? supportArea,
    String? agentSpeakStyle,
  }) {
    return QuestionAnswers(
      avaibleDays: avaibleDays ?? this.avaibleDays,
      avaibleHours: avaibleHours ?? this.avaibleHours,
      supportArea: supportArea ?? this.supportArea,
      agentSpeakStyle: agentSpeakStyle ?? this.agentSpeakStyle,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'avaibleDays': avaibleDays,
      'avaibleHours': avaibleHours,
      'supportArea': supportArea,
      'agentSpeakStyle': agentSpeakStyle,
    };
  }

  factory QuestionAnswers.fromMap(Map<String, dynamic> map) {
    return QuestionAnswers(
      avaibleDays: map['avaibleDays'] as dynamic,
      avaibleHours: map['avaibleHours'] as dynamic,
      supportArea: map['supportArea'] as String,
      agentSpeakStyle: map['agentSpeakStyle'] as String,
    );
  }
}
