import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../specialists_screen/specialists_notifier.dart';

class ChatItem {
  final SpecialistId specialistId;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final bool isFromMe;

  const ChatItem({
    required this.specialistId,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isFromMe,
  });

  ChatItem copyWith({
    SpecialistId? specialistId,
    String? lastMessage,
    DateTime? time,
    int? unreadCount,
    bool? isFromMe,
  }) {
    return ChatItem(
      specialistId: specialistId ?? this.specialistId,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unreadCount: unreadCount ?? this.unreadCount,
      isFromMe: isFromMe ?? this.isFromMe,
    );
  }
}

class ChatState {
  final String currentUserName;
  final List<ChatItem> chats;

  const ChatState({
    required this.currentUserName,
    required this.chats,
  });

  ChatState copyWith({
    String? currentUserName,
    List<ChatItem>? chats,
  }) {
    return ChatState(
      currentUserName: currentUserName ?? this.currentUserName,
      chats: chats ?? this.chats,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    final dummyChats = <ChatItem>[
      ChatItem(
        specialistId: SpecialistId.elara,
        lastMessage: 'Lorem Ipsum is simply dummy text of the printing.',
        time: DateTime(2025, 1, 12, 12, 15),
        unreadCount: 2,
        isFromMe: false,
      ),
      ChatItem(
        specialistId: SpecialistId.orion,
        lastMessage: 'Lorem Ipsum is simply dummy text of the printing.',
        time: DateTime(2025, 1, 12, 10, 10),
        unreadCount: 2,
        isFromMe: false,
      ),
      ChatItem(
        specialistId: SpecialistId.aura,
        lastMessage: 'Lorem Ipsum is simply dummy text of the printing.',
        time: DateTime(2025, 1, 12, 9, 35),
        unreadCount: 0,
        isFromMe: true,
      ),
      ChatItem(
        specialistId: SpecialistId.zen,
        lastMessage: 'Lorem Ipsum is simply dummy text of the printing.',
        time: DateTime(2025, 1, 12, 8, 25),
        unreadCount: 0,
        isFromMe: true,
      ),
    ];

    return ChatState(
      currentUserName: 'Hasan',
      chats: dummyChats,
    );
  }

  void deleteChat(SpecialistId id) {
    final filtered = state.chats.where((c) => c.specialistId != id).toList();
    state = state.copyWith(chats: filtered);
  }

  void markChatRead(SpecialistId id) {
    final updated = state.chats
        .map((c) => c.specialistId == id ? c.copyWith(unreadCount: 0) : c)
        .toList();
    state = state.copyWith(chats: updated);
  }

  void addChat(ChatItem item) {
    state = state.copyWith(chats: [item, ...state.chats]);
  }

  /// Yeni sohbet başlat (varsa üste taşı)
  void startChatWith(SpecialistId id) {
    final existingIndex = state.chats.indexWhere((c) => c.specialistId == id);

    if (existingIndex != -1) {
      final existing = state.chats[existingIndex].copyWith(time: DateTime.now());
      final list = [...state.chats]..removeAt(existingIndex);
      state = state.copyWith(chats: [existing, ...list]);
      return;
    }

    final newChat = ChatItem(
      specialistId: id,
      lastMessage: 'New chat started.',
      time: DateTime.now(),
      unreadCount: 0,
      isFromMe: true,
    );

    state = state.copyWith(chats: [newChat, ...state.chats]);
  }

  /// Conversation’dan sonra listeyi güncellemek için
  void upsertLastMessage({
    required SpecialistId id,
    required String lastMessage,
    required DateTime time,
    required bool isFromMe,
  }) {
    final idx = state.chats.indexWhere((c) => c.specialistId == id);

    if (idx == -1) {
      final newItem = ChatItem(
        specialistId: id,
        lastMessage: lastMessage,
        time: time,
        unreadCount: 0,
        isFromMe: isFromMe,
      );
      state = state.copyWith(chats: [newItem, ...state.chats]);
      return;
    }

    final updated = state.chats[idx].copyWith(
      lastMessage: lastMessage,
      time: time,
      isFromMe: isFromMe,
    );

    final list = [...state.chats]..removeAt(idx);
    state = state.copyWith(chats: [updated, ...list]);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
