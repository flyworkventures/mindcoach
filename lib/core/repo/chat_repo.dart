import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/message_model.dart';
import 'package:mindcoach/models/chat_model.dart';

class ChatRepo {
  final Ref? ref;

  ChatRepo(this.ref);



  Future<List<ChatModel>> getUserChats() async {
    HttpService httpService = HttpService(ref: ref);
    var res = await httpService.get(path: AppConstants.getUserChatsURL);
    
    if (res.statusCode != 200) {
      throw Exception('Failed to get user chats: ${res.statusCode}');
    }
    
    var json = jsonDecode(res.body);
    if (json['success'] != true || json['data'] == null) {
      throw Exception('Invalid response format');
    }
    
    List jsonList = json['data']['chats'] ?? [];
    List<ChatModel> chats = jsonList.map((e) => ChatModel.fromMap(e)).toList();
    return chats;
  }

  Future<ChatModel?> getChatById(int chatId) async {
    HttpService httpService = HttpService(ref: ref);
    var res = await httpService.get(path: '/chats/$chatId');
    
    if (res.statusCode != 200) {
      if (res.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get chat: ${res.statusCode}');
    }
    
    var json = jsonDecode(res.body);
    if (json['success'] != true || json['data'] == null || json['data']['chat'] == null) {
      return null;
    }
    
    return ChatModel.fromMap(json['data']['chat']);
  }

  Future<List<MessageModel>> getMessagesFromConsultantId(String id)async{
    List<MessageModel> messages = [];
    HttpService httpService = HttpService(ref: ref);
    var res = await httpService.get(path: AppConstants.getMessagesFromConsultantIdURL(id));
    var json = jsonDecode(res.body);
    //debugPrint("ATTDATA: ${json.toString()}");
    if (json["data"]["messages"] != null) {
          List jsonList = json["data"]["messages"];
    List<MessageModel> convertedList = jsonList.map((e)=>MessageModel.fromMap(e)).toList();
    messages.addAll(convertedList);
    return messages;
    } else {
      return [];
    }

  }


 /// Premium mesaj gönder - text, image veya voice gönderebilir
 /// Öncelik sırası: image > audio > text
 Future<void> sendPremiumMessage({
   required int consultantId,
   String? message,
   File? imageFile,
   File? audioFile,
 }) async {
   HttpService httpService = HttpService(ref: ref);
   
   // Resim varsa multipart image gönder
   if (imageFile != null) {
     final response = await httpService.postMultipartFile(
       path: AppConstants.sendPremiumMessageURL,
       file: imageFile,
       consultantId: consultantId,
       message: message,
       isImage: true,
     );
     
     if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
       throw Exception('Failed to send premium image message');
     }
     return;
   }
   
   // Ses dosyası varsa multipart audio gönder
   if (audioFile != null) {
     final response = await httpService.postMultipartFile(
       path: AppConstants.sendPremiumMessageURL,
       file: audioFile,
       consultantId: consultantId,
       message: message, // Sesli mesajda da mesaj gönderilebilir
       isImage: false,
     );
     
     if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
       throw Exception('Failed to send premium voice message');
     }
     return;
   }
   
   // Sadece text mesaj varsa normal POST gönder
   if (message != null && message.trim().isNotEmpty) {
     var body = {
       "consultantId": consultantId,
       "message": message.trim(),
     };
     final response = await httpService.post(
       path: AppConstants.sendPremiumMessageURL,
       body: body,
     );
     
     if (response.statusCode != 200 && response.statusCode != 201) {
       throw Exception('Failed to send premium text message');
     }
     return;
   }
   
  // Hiçbir şey gönderilmemişse hata fırlat
  throw Exception('No message, image, or audio provided');
}

/// General Assistant mesaj gönder - text, image veya voice gönderebilir
/// Öncelik sırası: image > audio > text
/// Mesajlar kaydedilmez, sadece API'ye gönderilir
/// Response: {"success":true,"data":{"messageType":"text","message":"...","needsAppointment":false,"appointmentDate":null}}
Future<Map<String, dynamic>?> sendGeneralAssistantMessage({
  String? message,
  File? imageFile,
  File? audioFile,
}) async {
  HttpService httpService = HttpService(ref: ref);
  
  // Resim varsa multipart image gönder
  if (imageFile != null) {
    final response = await httpService.postMultipartFile(
      path: AppConstants.sendGeneralAssistantMessageURL,
      file: imageFile,
      consultantId: 0, // General assistant için 0 kullan (backend'de ignore edilecek)
      message: message,
      isImage: true,
    );
    
    if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
      throw Exception('Failed to send general assistant image message');
    }
    
    // Response'u parse et
    try {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return json['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      log("⚠️ Response parse hatası: $e");
    }
    return null;
  }
  
  // Ses dosyası varsa multipart audio gönder
  if (audioFile != null) {
    final response = await httpService.postMultipartFile(
      path: AppConstants.sendGeneralAssistantMessageURL,
      file: audioFile,
      consultantId: 0, // General assistant için 0 kullan (backend'de ignore edilecek)
      message: message, // Sesli mesajda da mesaj gönderilebilir
      isImage: false,
    );
    
    if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
      throw Exception('Failed to send general assistant voice message');
    }
    
    // Response'u parse et
    try {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return json['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      log("⚠️ Response parse hatası: $e");
    }
    return null;
  }
  
  // Sadece text mesaj varsa normal POST gönder
  if (message != null && message.trim().isNotEmpty) {
    var body = {
      "message": message.trim(),
    };
    final response = await httpService.post(
      path: AppConstants.sendGeneralAssistantMessageURL,
      body: body,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send general assistant text message');
    }
    
    // Response'u parse et ve döndür
    try {
      final json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        return json['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      log("⚠️ Response parse hatası: $e");
    }
    return null;
  }
  
  // Hiçbir şey gönderilmemişse hata fırlat
  throw Exception('No message, image, or audio provided');
}

/// Normal kullanıcılar için text mesaj gönder
 Future<void> sendMessagesFromConsultantId(int id, String message) async {
   var body = {
     "consultantId": id,
     "message": message
   };
   HttpService httpService = HttpService(ref: ref);
   await httpService.post(path: AppConstants.consultantssendMessageURL, body: body);
 }

 /// Normal kullanıcılar için resim mesajı gönder
 Future<void> sendImageMessage({
   required int consultantId,
   required File imageFile,
   String? message,
 }) async {
   HttpService httpService = HttpService(ref: ref);
   final response = await httpService.postMultipartFile(
     path: AppConstants.consultantssendMessageURL,
     file: imageFile,
     consultantId: consultantId,
     message: message,
     isImage: true,
   );
   
   if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
     throw Exception('Failed to send image message');
   }
 }

 /// Normal kullanıcılar için sesli mesaj gönder
 Future<void> sendVoiceMessage({
   required int consultantId,
   required File audioFile,
   String? message,
 }) async {
   HttpService httpService = HttpService(ref: ref);
   final response = await httpService.postMultipartFile(
     path: AppConstants.consultantssendMessageURL,
     file: audioFile,
     consultantId: consultantId,
     message: null, // Mesaj boş bırakılıyor
     isImage: false,
   );
   
   if (response == null || (response.statusCode != 200 && response.statusCode != 201)) {
     throw Exception('Failed to send voice message');
   }
 }

 /// Chat'i sil (consultant ID'ye göre)
 Future<void> deleteChat(int consultantId) async {
   HttpService httpService = HttpService(ref: ref);
   final response = await httpService.delete(path: AppConstants.deleteChatURL(consultantId));
   
   if (response.statusCode != 200) {
     throw Exception('Failed to delete chat: ${response.statusCode}');
   }
   
   final json = jsonDecode(response.body);
   if (json['success'] != true) {
     throw Exception('Failed to delete chat: ${json['error'] ?? 'Unknown error'}');
   }
 }




}
