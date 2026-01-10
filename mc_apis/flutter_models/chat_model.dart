
class ChatModel {
  final int chatId;
  final int consultantId;
  final int userId;
  final dynamic createdDate;
  final String lastMessage;
  final dynamic lastMessageDate;
  ChatModel({
    required this.chatId,
    required this.consultantId,
    required this.userId,
    required this.createdDate,
    required this.lastMessage,
    required this.lastMessageDate,
  });
  

  ChatModel copyWith({
    int? chatId,
    int? consultantId,
    int? userId,
    dynamic createdDate,
    String? lastMessage,
    dynamic lastMessageDate,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      consultantId: consultantId ?? this.consultantId,
      userId: userId ?? this.userId,
      createdDate: createdDate ?? this.createdDate,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'chatId': chatId,
      'consultantId': consultantId,
      'userId': userId,
      'createdDate': createdDate,
      'lastMessage': lastMessage,
      'lastMessageDate': lastMessageDate,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] as int,
      consultantId: map['consultantId'] as int,
      userId: map['userId'] as int,
      createdDate: map['createdDate'] as dynamic,
      lastMessage: map['lastMessage'] as String,
      lastMessageDate: map['lastMessageDate'] as dynamic,
    );
  }

}
