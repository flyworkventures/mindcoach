
class UserModel {
  final int id;
  final String credential;
  final dynamic credentialData;
  final String? username;
  final String? nativeLang;
  final String gender; // male female unknown
  final QuestionAnswers? answerData;
  final String? lastPsychologicalProfile; // son psikolojik profili
  final List? userAgentNotes; // görüşmeler sonrasında ai notları;
  final List? leastSessions;
  final String? psychologicalProfileBasedOnMessages;
  final String accountCreatedDate;
  final String? generalProfile;
  final String? generalPsychologicalProfile;
  final String? profilePhotoUrl;
  final Membership? currentMembership; // şimdiki üyelik bilgisi
  final List<Purchase>? pastPurchases; // geçmiş alımlar
  final String? token; // authentication / session token
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
    this.profilePhotoUrl,
    this.currentMembership,
    this.pastPurchases,
    this.token,
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
    Membership? currentMembership,
    List<Purchase>? pastPurchases,
    String? token,
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
      ,
      currentMembership: currentMembership ?? this.currentMembership,
      pastPurchases: pastPurchases ?? this.pastPurchases,
      token: token ?? this.token,
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
      'answerData': answerData?.toMap(),
      'lastPsychologicalProfile': lastPsychologicalProfile,
      'userAgentNotes': userAgentNotes,
      'leastSessions': leastSessions,
      'psychologicalProfileBasedOnMessages': psychologicalProfileBasedOnMessages,
      'accountCreatedDate': accountCreatedDate,
      'generalProfile': generalProfile,
      'generalPsychologicalProfile': generalPsychologicalProfile,
      'profilePhotoUrl': profilePhotoUrl,
      'currentMembership': currentMembership != null ? currentMembership!.toMap() : null,
      'pastPurchases': pastPurchases?.map((e) => e.toMap()).toList(),
      'token': token,
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
      answerData: map['answerData'] == null || (map['answerData'] is Map && (map['answerData'] as Map).isEmpty) 
        ? null 
        : QuestionAnswers.fromMap(map['answerData'] as Map<String,dynamic>),
      lastPsychologicalProfile: map['lastPsychologicalProfile'] != null ? map['lastPsychologicalProfile'] as String : null,
      userAgentNotes: map['userAgentNotes'],
      leastSessions: map['leastSessions'],
      psychologicalProfileBasedOnMessages: map['psychologicalProfileBasedOnMessages'] != null ? map['psychologicalProfileBasedOnMessages'] as String : null,
      accountCreatedDate: map['accountCreatedDate'] as String,
      generalProfile: map['generalProfile'] != null ? map['generalProfile'] as String : null,
      generalPsychologicalProfile: map['generalPsychologicalProfile'] != null ? map['generalPsychologicalProfile'] as String : null,
      profilePhotoUrl: map['profilePhotoUrl'],
      currentMembership: map['currentMembership'] != null ? Membership.fromMap(Map<String, dynamic>.from(map['currentMembership'] as Map)) : null,
      pastPurchases: map['pastPurchases'] != null ? List<Purchase>.from((map['pastPurchases'] as List).map((x) => Purchase.fromMap(Map<String, dynamic>.from(x as Map)))) : null,
      token: map['token'] != null ? map['token'] as String : null,
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
      supportArea: map['supportArea'] as String? ?? '',
      agentSpeakStyle: map['agentSpeakStyle'] as String? ?? '',
    );
  }
}

class Membership {
  final String? planId;
  final String? planName;
  final String? startDate; // ISO string
  final String? endDate; // ISO string, nullable for ongoing
  final bool isActive;
  final bool? autoRenew;

  Membership({
    this.planId,
    this.planName,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.autoRenew,
  });

  Membership copyWith({
    String? planId,
    String? planName,
    String? startDate,
    String? endDate,
    bool? isActive,
    bool? autoRenew,
  }) {
    return Membership(
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'planName': planName,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'autoRenew': autoRenew,
    };
  }

  factory Membership.fromMap(Map<String, dynamic> map) {
    return Membership(
      planId: map['planId'] != null ? map['planId'] as String : null,
      planName: map['planName'] != null ? map['planName'] as String : null,
      startDate: map['startDate'] != null ? map['startDate'] as String : null,
      endDate: map['endDate'] != null ? map['endDate'] as String : null,
      isActive: map['isActive'] != null ? map['isActive'] as bool : false,
      autoRenew: map['autoRenew'] != null ? map['autoRenew'] as bool : null,
    );
  }
}

class Purchase {
  final String? id;
  final String? productId;
  final double? amount;
  final String? currency;
  final String? purchaseDate; // ISO string
  final String? status; // e.g. completed, refunded

  Purchase({
    this.id,
    this.productId,
    this.amount,
    this.currency,
    this.purchaseDate,
    this.status,
  });

  Purchase copyWith({
    String? id,
    String? productId,
    double? amount,
    String? currency,
    String? purchaseDate,
    String? status,
  }) {
    return Purchase(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'amount': amount,
      'currency': currency,
      'purchaseDate': purchaseDate,
      'status': status,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] != null ? map['id'] as String : null,
      productId: map['productId'] != null ? map['productId'] as String : null,
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      currency: map['currency'] != null ? map['currency'] as String : null,
      purchaseDate: map['purchaseDate'] != null ? map['purchaseDate'] as String : null,
      status: map['status'] != null ? map['status'] as String : null,
    );
  }
}
