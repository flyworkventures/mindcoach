import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart';

class HttpService {
	final String baseUrl;
  final dynamic ref; 

	HttpService({this.baseUrl = AppConstants.baseURL, this.ref});


  Map<String, String> get header {
    try {
  
      final token = (ref as dynamic)?.watch(userProvider)?.token ?? "";
      return {
        "Authorization": "Bearer $token",
        'Content-Type': 'application/json'
      };
    } catch (e) {
      return {
        "Authorization": "Bearer ",
        'Content-Type': 'application/json'
      };
    }
  }



 Future<http.Response> post({required String path,dynamic body,Map<String, String>? headers}) async{
  log("sent body: $body, header: $header");
 http.Response response = await http.post(Uri.parse("$baseUrl$path"),body: body == null ? null : jsonEncode(body),headers: header);
 if (response.statusCode == 200) {
   log("POST: Response ${response.body}");
 }else{
     log("POST ERR: Response ${response.body}");
 }
 return response;
 }

 Future<http.Response> get({required String path,dynamic body,Map<String, String>? headers}) async{
  log("sent body: $body, header: $headers path: $path");
 http.Response response = await http.get(Uri.parse("$baseUrl$path"),headers: headers ?? header);
 if (response.statusCode == 200) {
   log("POST: Response ${response.body}");
 }else{
     log("POST ERR: Response ${response.body}");
 }
 return response;
 }


 Future<http.Response> getUrl({required String url,dynamic body,Map<String, String>? headers}) async{
  log("sent body: $body, header: $headers");
 http.Response response = await http.get(Uri.parse(url),headers: headers ?? header);
 if (response.statusCode == 200) {
   log("POST: Response ${response.body}");
 }else{
     log("POST ERR: Response ${response.body}");
 }
 return response;
 }



 Future<http.Response> put({required String path,dynamic body,Map<String, String>? headers}) async{
  log("sent body: $body, header: $header");
 http.Response response = await http.put(Uri.parse("$baseUrl$path"),body: body == null ? null : jsonEncode(body),headers: headers ?? header);
 if (response.statusCode == 200) {
   log("POST: Response ${response.body}");
 }else{
   log("POST ERR: Response ${response.body}");
 }
 return response;
 }

 Future<http.Response> delete({required String path,Map<String, String>? headers}) async{
  log("DELETE request: $path, header: $header");
 http.Response response = await http.delete(Uri.parse("$baseUrl$path"),headers: headers ?? header);
 if (response.statusCode == 200) {
   log("DELETE: Response ${response.body}");
 }else{
   log("DELETE ERR: Response ${response.body}");
 }
 return response;
 }





 Future<http.StreamedResponse?> postAudioFile({required String path,required File file,var conversation,Map<String, String>? headers}) async{

try {
    final url = Uri.parse("$baseUrl$path");
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.fields["conversation"] = conversation;
    request.fields["sender"] = "user";
    http.StreamedResponse response = await request.send();
 if (response.statusCode != 200) {
  var body = await response.stream.bytesToString();
  var json = jsonDecode(body);
   log("POST: Response ${json["error"]}");
 }
  return response;
} catch (e) {
  log("Error on postAudio: $e");
  return null;
}

 }

 Future<http.Response> uploadToCDN({
    required String url,
    required List<int> fileBytes,
    required String contentType,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        body: fileBytes,
        headers: {
          'AccessKey': '68664abb-b19e-47e7-acd67dba78a5-e90a-4386',
          'Content-Type': contentType,
        },
      );
      
      log("CDN Upload Response: ${response.statusCode}");
      return response;
    } catch (e) {
      log("Error uploading to CDN: $e");
      rethrow;
    }
  }

  /// Multipart/form-data ile resim veya ses dosyası gönder
  /// Yeni API formatı: consultantId, message (optional), file (image) veya voice (audio)
  Future<http.Response?> postMultipartFile({
    required String path,
    required File file,
    required int consultantId,
    String? message,
    required bool isImage, // true = image (file field), false = audio (voice field)
  }) async {
    try {
      final url = Uri.parse("$baseUrl$path");
      final request = http.MultipartRequest('POST', url);
      
      // Authorization header ekle
      final token = ref?.watch(userProvider)?.token ?? "";
      request.headers['Authorization'] = 'Bearer $token';
      
      // Dosyayı ekle (resim için 'file', ses için 'voice')
      if (isImage) {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else {
        request.files.add(await http.MultipartFile.fromPath('voice', file.path));
      }
      
      // Form fields
      request.fields['consultantId'] = consultantId.toString();
      if (message != null && message.isNotEmpty) {
        request.fields['message'] = message;
      }
      
      log("📤 Sending ${isImage ? 'image' : 'voice'}: ${file.path}, consultantId: $consultantId");
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        log("✅ ${isImage ? 'Image' : 'Voice'} sent successfully");
        log("Response: ${response.body}");
      } else {
        log("❌ POST ${isImage ? 'Image' : 'Voice'} Error: ${response.statusCode}");
        log("Response: ${response.body}");
      }
      
      return response;
    } catch (e) {
      log("❌ Error on postMultipartFile: $e");
      return null;
    }
  }


}