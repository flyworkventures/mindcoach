import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/Riverpod/Providers/user_provider.dart';

import '../../Riverpod/providers/all_providers.dart';

class StreamCallRepo {
  final WidgetRef? ref;

  StreamCallRepo(this.ref);

  Future<Map<String, dynamic>?> sendStreamCallAudio({
    required int consultantId,
    required File audioFile,
  }) async {
    try {
      final url = Uri.parse("${AppConstants.baseURL}${AppConstants.videoCallURL}");
      final request = http.MultipartRequest('POST', url);
      
      final token = ref?.read(AllProviders.userProvider)?.token ?? "";
      request.headers['Authorization'] = 'Bearer $token';
 
      final fileExtension = audioFile.path.split('.').last.toLowerCase();
      String mimeType = 'audio/mp4'; 
      
      if (fileExtension == 'm4a') {
        mimeType = 'audio/mp4';
      } else if (fileExtension == 'mp3') {
        mimeType = 'audio/mpeg';
      } else if (fileExtension == 'wav') {
        mimeType = 'audio/wav';
      } else if (fileExtension == 'ogg') {
        mimeType = 'audio/ogg';
      } else if (fileExtension == 'aac') {
        mimeType = 'audio/aac';
      }
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio', 
          audioFile.path,
          filename: audioFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ),
      );
      
      log("📤 [STREAM-CALL] Audio MIME type: $mimeType, extension: $fileExtension");
      

      request.fields['consultantId'] = consultantId.toString();
      
      log("📤 [STREAM-CALL] Audio gönderiliyor: ${audioFile.path}, consultantId: $consultantId");
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          log("✅ [STREAM-CALL] Audio başarıyla gönderildi");
          log("📥 [STREAM-CALL] Response: ${response.body}");
          return json;
        } else {
          log("❌ [STREAM-CALL] Error: ${json['error']}");
          return null;
        }
      } else {
        log("❌ [STREAM-CALL] HTTP Error: ${response.statusCode}");
        log("Response: ${response.body}");
        return null;
      }
    } catch (e) {
      log("❌ [STREAM-CALL] Error: $e");
      return null;
    }
  }
}

