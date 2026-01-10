import 'dart:convert';
import 'dart:io';

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
    List jsonList = json["data"]["messages"];
    List<MessageModel> convertedList = jsonList.map((e)=>MessageModel.fromMap(e)).toList();
    messages.addAll(convertedList);
    return messages;
  }


 Future<void> sendMessagesFromConsultantId(int id,String message)async{
  var body = {
  "consultantId": id,
  "message": message
};
  HttpService httpService = HttpService(ref: ref);
  await httpService.post(path: AppConstants.consultantssendMessageURL,body: body);
 }


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
