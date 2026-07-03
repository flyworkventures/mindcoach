import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/consultant_model.dart';

class ConsultantRepo {
  final Ref? ref;

  ConsultantRepo(this.ref);


 Future<List<ConsultantModel>?> getAllConsultant()async{
  try {
    HttpService http = HttpService(ref: ref);
   var res = await http.get(path: AppConstants.consultantsURL);
   if (res.statusCode == 200) {
     var json = jsonDecode(res.body);
     List jsonList = json["data"]["consultants"];
     List<ConsultantModel> datas =  jsonList.map((e)=> ConsultantModel.fromMap(e)).toList();
     return datas;
   }else{
    return [];
   }
  } catch (e) {
    debugPrint("Error $e");
    return [];
  }
 }

 /// Tek bir danışmanı id ile getirir (analiz kartı gibi doğrudan açılışlar için).
 Future<ConsultantModel?> getConsultantById(int id) async {
   try {
     final http = HttpService(ref: ref);
     final res = await http.get(path: AppConstants.getConsultantByIdURL(id));
     if (res.statusCode != 200) return null;
     final json = jsonDecode(res.body);
     if (json['success'] != true || json['data']?['consultant'] == null) {
       return null;
     }
     return ConsultantModel.fromMap(
       json['data']['consultant'] as Map<String, dynamic>,
     );
   } catch (e) {
     debugPrint('getConsultantById($id) error: $e');
     return null;
   }
 }
}