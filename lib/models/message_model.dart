// ignore_for_file: public_member_api_docs, sort_constructors_first
class MessageModel {
  final int messageId;
  final int chatId;
  final int senderId;
  final String sender; // "user" , "assistant"
  final String message;
  final dynamic sentTime;
  final bool? isFile;
  final String? fileURL;
  final bool? isVoiceMessage;
  final String? voiceURL;
  final String? voiceMessageContent;
  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.sender,
    required this.message,
    required this.sentTime,
    this.isFile,
    this.fileURL,
    this.isVoiceMessage,
    this.voiceURL,
    this.voiceMessageContent
  });

  MessageModel copyWith({
    int? messageId,
    int? chatId,
    int? senderId,
    String? sender,
    String? message,
    dynamic sentTime,
    bool? isFile,
    String? fileURL,
    bool? isVoiceMessage,
    String? voiceURL,
     String? voiceMessageContent,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      sentTime: sentTime ?? this.sentTime,
      isFile: isFile ?? this.isFile,
      fileURL: fileURL ?? this.fileURL,
      isVoiceMessage: isVoiceMessage ?? this.isVoiceMessage,
      voiceURL: voiceURL ?? this.voiceURL,
      voiceMessageContent: voiceMessageContent ?? this.voiceMessageContent
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
      'isFile': isFile,
      'fileURL': fileURL,
      'isVoiceMessage': isVoiceMessage,
      'voiceURL': voiceURL,
      'voiceMessageContent': voiceMessageContent,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert int/bool to bool?
    bool? _toBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return null;
    }

    return MessageModel(
      messageId: map['messageId'] as int,
      chatId: map['chatId'] as int,
      senderId: map['senderId'] as int,
      sender: map['sender'] as String,
      message: map['message'] as String,
      sentTime: map['sentTime'] as dynamic,
      isFile: _toBool(map['isFile']),
      fileURL: map['fileURL'] as String?,
      isVoiceMessage: _toBool(map['isVoiceMessage']),
      voiceURL: map['voiceURL'] as String?,
      voiceMessageContent: map['voiceMessageContent'] as String?,
    );
  }
}
