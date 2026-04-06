import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/http/http_service.dart';



class AppointmentRepo {
  final Ref? ref;

  AppointmentRepo(this.ref);

  Future<List<Map<String, dynamic>>> getAllAppointments(int userId) async {
    try {
      HttpService httpService = HttpService(ref: ref);
      

      final tokenUserId = ref?.read(AllProviders.userProvider)?.id;
      if (tokenUserId == null) {
        log("❌ Token'dan userId alınamadı");
        return [];
      }
      
      log("📞 getAllAppointments çağrıldı: userId=$userId, tokenUserId=$tokenUserId");
     
      final path = AppConstants.getAllAppointmentsURL(tokenUserId);
      log("📞 API Path: $path");
      final response = await httpService.get(
        path: path,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"];
        
        log("📥 API Response: ${response.body}");
        log("📥 Parsed data type: ${data.runtimeType}");
        
        if (data != null && data is List) {
          log("✅ API'den ${data.length} randevu bulundu");
          
          // Randevu istatistiklerini hesapla
          final now = DateTime.now();
          int pastCount = 0;
          int upcomingCount = 0;
          int cancelledCount = 0;
          
          // Her randevuyu logla ve istatistik hesapla
          for (var i = 0; i < data.length; i++) {
            final appointment = data[i];
            final appointmentDateStr = appointment["appointment_date"] as String?;
            final status = appointment["status"] as String?;
            
            if (status?.toLowerCase() == 'cancelled') {
              cancelledCount++;
            } else if (appointmentDateStr != null) {
              try {
                final appointmentDate = DateTime.parse(appointmentDateStr).toLocal();
                if (appointmentDate.isBefore(now)) {
                  pastCount++;
                } else {
                  upcomingCount++;
                }
              } catch (e) {
                log("⚠️ Tarih parse edilemedi: $appointmentDateStr");
              }
            }
            
            log("📅 Randevu ${i + 1}/${data.length}: id=${appointment["id"]}, date=${appointmentDateStr}, consultantId=${appointment["consultant_id"]}, status=$status");
          }
          
          log("📊 RANDEVU ÖZETİ:");
          log("   📈 Toplam: ${data.length}");
          log("   ✅ Gelecek: $upcomingCount");
          log("   📜 Geçmiş: $pastCount");
          log("   ❌ İptal: $cancelledCount");
          
          return List<Map<String, dynamic>>.from(data);
        } else {
          log("⚠️ Randevu bulunamadı (data: null veya liste değil)");
          log("⚠️ Data değeri: $data");
          return [];
        }
      } else {
        log("❌ GET all appointments hatası: ${response.statusCode}");
        log("❌ Response: ${response.body}");
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
      

      final tokenUserId = ref?.read(AllProviders.userProvider)?.id;
      if (tokenUserId == null) {
        log("❌ Token'dan userId alınamadı");
        return null;
      }
      
      log("📞 getUpcomingAppointment çağrıldı: userId=$userId, tokenUserId=$tokenUserId");

      final path = AppConstants.getUpcomingAppointmentURL(tokenUserId);
      log("📞 API Path: $path");
      final response = await httpService.get(
        path: path,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"];
        
        log("📥 Upcoming API Response: ${response.body}");
        log("📥 Parsed data: $data");
        
        if (data != null) {
          log("✅ Yaklaşan randevu bulundu: id=${data["id"]}, date=${data["appointment_date"]}, consultantId=${data["consultant_id"]}, status=${data["status"]}");
          return data as Map<String, dynamic>;
        } else {
          log("⚠️ Yaklaşan randevu bulunamadı (data: null)");
          log("⚠️ Full response: ${json.toString()}");
          return null;
        }
      } else {
        log("❌ GET upcoming appointment hatası: ${response.statusCode}");
        log("❌ Response: ${response.body}");
        return null;
      }
    } catch (e) {
      log(" getUpcomingAppointment hatası: $e");
      return null;
    }
  }

  /// Randevuyu iptal et
  /// DELETE /appointments/:id
  Future<bool> cancelAppointment(int appointmentId) async {
    try {
      HttpService httpService = HttpService(ref: ref);
      final path = AppConstants.cancelAppointmentURL(appointmentId);
      log("🚫 Randevu iptal ediliyor: appointmentId=$appointmentId, path=$path");
      
      final response = await httpService.delete(path: path);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          log("✅ Randevu başarıyla iptal edildi: $appointmentId");
          return true;
        } else {
          log("❌ Randevu iptal edilemedi: ${json['error'] ?? 'Unknown error'}");
          return false;
        }
      } else {
        final json = jsonDecode(response.body);
        log("❌ Randevu iptal hatası (${response.statusCode}): ${json['error'] ?? response.body}");
        return false;
      }
    } catch (e) {
      log("❌ cancelAppointment hatası: $e");
      return false;
    }
  }

  /// İptal edilmiş randevuyu geri al (reactivate)
  /// PUT /appointments/:id/reactivate
  Future<bool> reactivateAppointment(int appointmentId) async {
    try {
      HttpService httpService = HttpService(ref: ref);
      final path = AppConstants.reactivateAppointmentURL(appointmentId);
      log("✅ Randevu geri alınıyor: appointmentId=$appointmentId, path=$path");
      
      final response = await httpService.put(path: path, body: null);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          log("✅ Randevu başarıyla geri alındı: $appointmentId");
          return true;
        } else {
          log("❌ Randevu geri alınamadı: ${json['error'] ?? 'Unknown error'}");
          return false;
        }
      } else {
        final json = jsonDecode(response.body);
        log("❌ Randevu geri alma hatası (${response.statusCode}): ${json['error'] ?? response.body}");
        return false;
      }
    } catch (e) {
      log("❌ reactivateAppointment hatası: $e");
      return false;
    }
  }
}

