// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MessageModel {
  final int messageId;
  final int chatId;
  final int senderId;
  final String sender; // "user" , "assistant"
  final String message;
  final dynamic sentTime;
  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.sender,
    required this.message,
    required this.sentTime,
  });

  MessageModel copyWith({
    int? messageId,
    int? chatId,
    int? senderId,
    String? sender,
    String? message,
    dynamic? sentTime,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      sentTime: sentTime ?? this.sentTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'sender': sender,
      'message': message,
      'sentTime': sentTime,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] as int,
      chatId: map['chatId'] as int,
      senderId: map['senderId'] as int,
      sender: map['sender'] as String,
      message: map['message'] as String,
      sentTime: map['sentTime'] as dynamic,
    );
  }
}
