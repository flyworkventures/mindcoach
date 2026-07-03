import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/Utils/logger.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';

class HttpService {
  final String baseUrl;
  final Ref? ref;

  /// Yanlış IP / kapalı backend durumunda login'in sonsuza kadar
  /// beklemesini önler.
  static const Duration defaultTimeout = Duration(seconds: 20);

  HttpService({this.baseUrl = AppConstants.baseURL, this.ref});

  /// Token'i once Riverpod state'inden, bulamazsa local storage'dan alir.
  Future<Map<String, String>> _getHeaders() async {
    String token = '';

    // 1. Riverpod state'inden dene
    try {
      token = ref?.read(AllProviders.userProvider)?.token ?? '';
    } catch (_) {}

    // 2. Bos gelirse local storage'a bak (fallback)
    if (token.isEmpty) {
      try {
        token = await LocalDbService().getString(key: LocalDbKeys.token) ?? '';
      } catch (_) {}
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> post({
    required String path,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    Logger.info(
      text: "POST: $path,",
      className: "HttpService",
      functionName: "post",
    );
    final h = headers ?? await _getHeaders();
    try {
      http.Response response = await http
          .post(
            Uri.parse("$baseUrl$path"),
            body: body == null ? null : jsonEncode(body),
            headers: h,
          )
          .timeout(defaultTimeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info(
          text: "RESPONSE $path: ${response.body}",
          className: "HttpService",
          functionName: "post",
        );
      } else {
        Logger.errorLog(
          text: "RESPONSE $path (${response.statusCode}): ${response.body}",
          className: "HttpService",
          functionName: "post",
        );
      }
      return response;
    } on SocketException catch (e) {
      Logger.errorLog(
        text: "POST $path bağlantı hatası ($baseUrl): $e",
        className: "HttpService",
        functionName: "post",
      );
      rethrow;
    } on TimeoutException catch (e) {
      Logger.errorLog(
        text: "POST $path zaman aşımı ($baseUrl): $e",
        className: "HttpService",
        functionName: "post",
      );
      rethrow;
    }
  }

  Future<http.Response> get({
    required String path,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    Logger.info(
      text: "GET: $path,",
      className: "HttpService",
      functionName: "get",
    );
    final h = headers ?? await _getHeaders();
    http.Response response = await http.get(
      Uri.parse("$baseUrl$path"),
      headers: h,
    );
    if (response.statusCode == 200) {
      Logger.info(
        text: "RESPONSE $path: ${response.body}",
        className: "HttpService",
        functionName: "get",
      );
    } else {
      Logger.errorLog(
        text: "RESPONSE $path: ${response.body}",
        className: "HttpService",
        functionName: "get",
      );
    }
    return response;
  }

  Future<http.Response> getUrl({
    required String url,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    log("sent body: $body, header: $headers");
    final h = headers ?? await _getHeaders();
    http.Response response = await http.get(Uri.parse(url), headers: h);
    if (response.statusCode == 200) {
      log("GET: Response ${response.body}");
    } else {
      log("GET ERR: Response ${response.body}");
    }
    return response;
  }

  Future<http.Response> put({
    required String path,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final h = headers ?? await _getHeaders();
    Logger.info(
      text: "PUT: $path, Token: ${h["Authorization"]}",
      className: "HttpService",
      functionName: "put",
    );
    http.Response response = await http.put(
      Uri.parse("$baseUrl$path"),
      body: body == null ? null : jsonEncode(body),
      headers: h,
    );
    if (response.statusCode == 200) {
      Logger.info(
        text: "PUT Response $path:  ${response.body}",
        className: "HttpService",
        functionName: "put",
      );
    } else {
      Logger.errorLog(
        text: "PUT Response $path:  ${response.body}",
        className: "HttpService",
        functionName: "put",
      );
    }
    return response;
  }

  Future<http.Response> delete({
    required String path,
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final h = headers ?? await _getHeaders();
    log("DELETE request: $path");
    http.Response response = await http.delete(
      Uri.parse("$baseUrl$path"),
      body: body == null ? null : jsonEncode(body),
      headers: h,
    );
    if (response.statusCode == 200) {
      log("DELETE: Response ${response.body}");
    } else {
      log("DELETE ERR: Response ${response.body}");
    }
    return response;
  }

  Future<http.StreamedResponse?> postAudioFile({
    required String path,
    required File file,
    var conversation,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse("$baseUrl$path");
      final request = http.MultipartRequest('POST', url);

      // Authorization header ekle
      final h = await _getHeaders();
      request.headers['Authorization'] = h['Authorization']!;

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
  Future<http.Response?> postMultipartFile({
    required String path,
    required File file,
    required int consultantId,
    String? message,
    required bool isImage,
  }) async {
    try {
      final url = Uri.parse("$baseUrl$path");
      final request = http.MultipartRequest('POST', url);

      // Authorization header ekle
      final h = await _getHeaders();
      request.headers['Authorization'] = h['Authorization']!;

      // Dosyayı ekle (resim için 'file', ses için 'voice')
      if (isImage) {
        request.files
            .add(await http.MultipartFile.fromPath('file', file.path));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('voice', file.path));
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
