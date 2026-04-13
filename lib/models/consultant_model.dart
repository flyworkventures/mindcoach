// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class ConsultantModel {
  final int id;
  final Map<String,dynamic> names; // dillerde isimleri
  final String mainPrompt;
  final String photoURL;
  final String creadtedDate;
  final String explanation;
  final List features;
  final String job;
  final String? url3d; // 3D model URL
  final String? createdAt; // Created timestamp
  final String? updatedAt; // Updated timestamp
  final String? voiceId; // Voice ID
  final List? roles; // Consultant roles
  final double rating; // Star rating (0-5)

  ConsultantModel({
    required this.id,
    required this.names,
    required this.mainPrompt,
    required this.photoURL,
    required this.creadtedDate,
    required this.explanation,
    required this.features,
    required this.job,
    this.url3d,
    this.createdAt,
    this.updatedAt,
    this.voiceId,
    this.roles,
    this.rating = 0.0,
  });

  ConsultantModel copyWith({
    int? id,
    Map<String,dynamic>? names,
    String? mainPrompt,
    String? photoURL,
    String? creadtedDate,
    String? explanation,
    List? features,
    String? job,
    String? url3d,
    String? createdAt,
    String? updatedAt,
    String? voiceId,
    List? roles,
    double? rating,
  }) {
    return ConsultantModel(
      id: id ?? this.id,
      names: names ?? this.names,
      mainPrompt: mainPrompt ?? this.mainPrompt,
      photoURL: photoURL ?? this.photoURL,
      creadtedDate: creadtedDate ?? this.creadtedDate,
      explanation: explanation ?? this.explanation,
      features: features ?? this.features,
      job: job ?? this.job,
      url3d: url3d ?? this.url3d,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      voiceId: voiceId ?? this.voiceId,
      roles: roles ?? this.roles,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'names': names,
      'mainPrompt': mainPrompt,
      'photoURL': photoURL,
      'creadtedDate': creadtedDate,
      'explanation': explanation,
      'features': features,
      'job': job,
      'url3d': url3d,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'voiceId': voiceId,
      'roles': roles,
      'rating': rating,
    };
  }

  factory ConsultantModel.fromMap(Map<String, dynamic> map) {
    return ConsultantModel(
      id: map['id'] as int,
      names: map['names'],
      mainPrompt: map['mainPrompt'] as String? ?? map['main_prompt'] as String? ?? '',
      photoURL: map['photoURL'] as String? ?? map['photo_url'] as String? ?? '',
      creadtedDate: map['creadtedDate'] as String? ?? map['created_date'] as String? ?? map['createdDate'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
      features: map['features'] as List? ?? [],
      job: map['job'] as String? ?? '',
      url3d: map['url3d'] as String? ?? map['3d_url'] as String?,
      createdAt: map['createdAt'] as String? ?? map['created_at'] as String?,
      updatedAt: map['updatedAt'] as String? ?? map['updated_at'] as String?,
      voiceId: map['voiceId'] as String? ?? map['voice_id'] as String?,
      roles: map['roles'] as List?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ConsultantModel.fromJson(String source) => ConsultantModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ConsultantModel(id: $id, names: $names, mainPrompt: $mainPrompt, photoURL: $photoURL, creadtedDate: $creadtedDate, explanation: $explanation, features: $features, job: $job, url3d: $url3d, createdAt: $createdAt, updatedAt: $updatedAt, voiceId: $voiceId, roles: $roles, rating: $rating)';
  }

  @override
  bool operator ==(covariant ConsultantModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      mapEquals(other.names, names) &&
      other.mainPrompt == mainPrompt &&
      other.photoURL == photoURL &&
      other.creadtedDate == creadtedDate &&
      other.explanation == explanation &&
      listEquals(other.features, features) &&
      other.job == job &&
      other.url3d == url3d &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.voiceId == voiceId &&
      listEquals(other.roles, roles) &&
      other.rating == rating;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      names.hashCode ^
      mainPrompt.hashCode ^
      photoURL.hashCode ^
      creadtedDate.hashCode ^
      explanation.hashCode ^
      features.hashCode ^
      job.hashCode ^
      url3d.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      voiceId.hashCode ^
      (roles?.hashCode ?? 0) ^
      rating.hashCode;
  }
}
