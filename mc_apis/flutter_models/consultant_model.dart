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
  ConsultantModel({
    required this.id,
    required this.names,
    required this.mainPrompt,
    required this.photoURL,
    required this.creadtedDate,
    required this.explanation,
    required this.features,
    required this.job,
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
    };
  }

  factory ConsultantModel.fromMap(Map<String, dynamic> map) {
    return ConsultantModel(
      id: map['id'] as int,
      names: map['names'],
      mainPrompt: map['mainPrompt'] as String,
      photoURL: map['photoURL'] as String,
      creadtedDate: map['creadtedDate'] as String,
      explanation: map['explanation'] as String,
      features: map['features'] ,
      job: map['job'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ConsultantModel.fromJson(String source) => ConsultantModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ConsultantModel(id: $id, names: $names, mainPrompt: $mainPrompt, photoURL: $photoURL, creadtedDate: $creadtedDate, explanation: $explanation, features: $features, job: $job)';
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
      other.job == job;
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
      job.hashCode;
  }
}
