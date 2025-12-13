import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../specialists_screen/specialists_notifier.dart';

class ChatMessage {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool isFromMe;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.isFromMe,
  });
}

class ConversationsState {
  final Map<SpecialistId, List<ChatMessage>> messagesBySpecialist;

  const ConversationsState({
    this.messagesBySpecialist = const {},
  });

  ConversationsState copyWith({
    Map<SpecialistId, List<ChatMessage>>? messagesBySpecialist,
  }) {
    return ConversationsState(
      messagesBySpecialist: messagesBySpecialist ?? this.messagesBySpecialist,
    );
  }
}

class ConversationsNotifier extends Notifier<ConversationsState> {
  @override
  ConversationsState build() => const ConversationsState();

  List<ChatMessage> messagesOf(SpecialistId id) {
    return state.messagesBySpecialist[id] ?? const [];
  }

  void sendMessage({
    required SpecialistId id,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmed,
      createdAt: DateTime.now(),
      isFromMe: true,
    );

    final current = messagesOf(id);
    state = state.copyWith(
      messagesBySpecialist: {
        ...state.messagesBySpecialist,
        id: [msg, ...current],
      },
    );
  }

  void receiveDummyReply({
    required SpecialistId id,
    String text = "Got it. Tell me more.",
  }) {
    final msg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
      isFromMe: false,
    );

    final current = messagesOf(id);
    state = state.copyWith(
      messagesBySpecialist: {
        ...state.messagesBySpecialist,
        id: [msg, ...current],
      },
    );
  }

  void clearConversation(SpecialistId id) {
    final map = {...state.messagesBySpecialist}..remove(id);
    state = state.copyWith(messagesBySpecialist: map);
  }
}

final conversationsProvider =
NotifierProvider<ConversationsNotifier, ConversationsState>(
  ConversationsNotifier.new,
);
