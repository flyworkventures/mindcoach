import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart';

class AppointmentRepo {
  final Ref? ref;

  AppointmentRepo(this.ref);

  Future<List<Map<String, dynamic>>> getAllAppointments(int userId) async {
    try {
      HttpService httpService = HttpService(ref: ref);
      

      final tokenUserId = ref?.read(userProvider)?.id;
      if (tokenUserId == null) {
        log("❌ Token'dan userId alınamadı");
        return [];
      }
      
     
      final path = AppConstants.getAllAppointmentsURL(tokenUserId);
      final response = await httpService.get(
        path: path,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"];
        
        if (data != null && data is List) {
          log(" ${data.length} randevu bulundu");
          return List<Map<String, dynamic>>.from(data);
        } else {
          log("Randevu bulunamadı (data: null veya liste değil)");
          return [];
        }
      } else {
        log(" GET all appointments hatası: ${response.statusCode}");
        log("Response: ${response.body}");
        return [];
      }
    } catch (e) {
      log(" getAllAppointments hatası: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>?> getUpcomingAppointment(int userId) async {
    try {
      HttpService httpService = HttpService(ref: ref);
      

      final tokenUserId = ref?.read(userProvider)?.id;
      if (tokenUserId == null) {
        log(" Token'dan userId alınamadı");
        return null;
      }

      final path = AppConstants.getUpcomingAppointmentURL(tokenUserId);
      final response = await httpService.get(
        path: path,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"];
        
        if (data != null) {
          log(" Yaklaşan randevu bulundu: ${data["id"]}, date: ${data["appointment_date"]}");
          return data as Map<String, dynamic>;
        } else {
          log("Yaklaşan randevu bulunamadı (data: null)");
          return null;
        }
      } else {
        log(" GET upcoming appointment hatası: ${response.statusCode}");
        log("Response: ${response.body}");
        return null;
      }
    } catch (e) {
      log(" getUpcomingAppointment hatası: $e");
      return null;
    }
  }
}

