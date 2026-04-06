import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/http/http_service.dart';

class MoodRepo {
  final Ref? ref;

  MoodRepo(this.ref);


  Future<Map<String, dynamic>?> getTodayMood(int userId) async {
    try {
      HttpService httpService = HttpService(ref: ref);

      final tokenUserId = ref?.read(AllProviders.userProvider)?.id;
      if (tokenUserId == null) {
        log("Token'dan userId alınamadı");
        return null;
      }
      

      final today = DateTime.now();
      final todayString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      log("🔍 Bugünkü tarih kontrolü (local): $todayString");
      

      // Daha fazla kayıt al (bugünün kaydını bulmak için)
      final pathWithQuery = "${AppConstants.getUserMoodsURL(tokenUserId)}?limit=50&offset=0";
      final response = await httpService.get(
        path: pathWithQuery,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json["data"];
        
        log("📥 API'den ${data is List ? data.length : 0} mood kaydı geldi");
        
        if (data != null && data is List && data.isNotEmpty) {
          // Tüm kayıtları kontrol et (bugünün kaydını bulmak için)
          for (var moodRecord in data) {
            final recordDate = moodRecord["date"] as String?;
            
            if (recordDate != null) {
              String recordDateOnly;
              if (recordDate.contains('T')) {
                recordDateOnly = recordDate.split('T')[0];
              } else {
                recordDateOnly = recordDate;
              }
              
              log("📅 Kayıt tarihi kontrol ediliyor: $recordDateOnly");

              try {
                String localDateString;
                if (recordDate.contains('T')) {
                  final utcDate = DateTime.parse(recordDate);
                  final localDate = utcDate.toLocal();
                  localDateString = "${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}";
                  
                  log("📅 API tarihi: $recordDateOnly (UTC) -> $localDateString (local)");
                } else {
                  localDateString = recordDateOnly;
                  log("📅 API tarihi: $recordDateOnly (zaten local format)");
                }

                if (localDateString == todayString) {
                  log("✅ Bugünkü mood bulundu: ${moodRecord["mood"]}, date: $localDateString");
                  return {
                    'date': recordDate,
                    'mood': moodRecord["mood"],
                  };
                }
              } catch (e) {
                log("⚠️ Tarih parse hatası: $e");
                // Fallback: string karşılaştırması
                if (recordDateOnly == todayString) {
                  log("✅ Bugünkü mood bulundu (fallback): ${moodRecord["mood"]}, date: $recordDateOnly");
                  return {
                    'date': recordDate,
                    'mood': moodRecord["mood"],
                  };
                }
              }
            }
          }
        }
        
        log("❌ Bugünkü mood kaydı bulunamadı (bugün: $todayString)");
        return null;
      } else {
        log("GET mood hatası: ${response.statusCode}");
        log("Response: ${response.body}");
        return null;
      }
    } catch (e) {
      log(" getTodayMood hatası: $e");
      return null;
    }
  }

  Future<bool> createOrUpdateMood({
    required String date,
    required int mood,
  }) async {
    try {
      HttpService httpService = HttpService(ref: ref);
      
      final body = {
        "date": date,
        "mood": mood,
      };

      final response = await httpService.post(
        path: AppConstants.createOrUpdateMoodURL,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("Mood kaydedildi/güncellendi: date=$date, mood=$mood");
        return true;
      } else {
        log("POST mood hatası: ${response.statusCode}");
        log("Response: ${response.body}");
        return false;
      }
    } catch (e) {
      log("createOrUpdateMood hatası: $e");
      return false;
    }
  }
}

