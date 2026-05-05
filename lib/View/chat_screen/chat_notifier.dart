import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import '../../core/repo/chat_repo.dart';
import '../../models/consultant_model.dart';
import '../specialists_screen/specialists_notifier.dart';
import 'notifiers/conversation_notifier.dart';

class ChatItem {
  final SpecialistId specialistId;
  final int consultantId;
  final ConsultantModel? consultant; // Consultant bilgileri
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final bool isFromMe;

  const ChatItem({
    required this.specialistId,
    required this.consultantId,
    this.consultant,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isFromMe,
  });

  ChatItem copyWith({
    SpecialistId? specialistId,
    int? consultantId,
    ConsultantModel? consultant,
    String? lastMessage,
    DateTime? time,
    int? unreadCount,
    bool? isFromMe,
  }) {
    return ChatItem(
      specialistId: specialistId ?? this.specialistId,
      consultantId: consultantId ?? this.consultantId,
      consultant: consultant ?? this.consultant,
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
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.currentUserName,
    required this.chats,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    String? currentUserName,
    List<ChatItem>? chats,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      currentUserName: currentUserName ?? this.currentUserName,
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  bool _isRefreshing = false;
  DateTime? _lastRefreshAt;
  static const Duration _minRefreshInterval = Duration(seconds: 20);
  int? _activeUserId;

  @override
  ChatState build() {
    final user = ref.watch(AllProviders.userProvider);
    final userId = user?.id;
    final userName = user?.username ?? '';

    final userChanged = _activeUserId != userId;
    if (userChanged) {
      _activeUserId = userId;
      _isRefreshing = false;
      _lastRefreshAt = null;
    }

    Future(() {
      if (!ref.mounted) return;
      if (userId == null) return;
      _loadChats();
    });

    return ChatState(
      currentUserName: userName,
      chats: [],
      isLoading: userId != null,
    );
  }

  /// API'den chat'leri yükle
  Future<void> _loadChats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
    
      final specialistsState = ref.read(specialistsProvider);
      var consultants = specialistsState.specialists ?? [];

      if (consultants.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!ref.mounted) return;
        
        final updatedSpecialistsState = ref.read(specialistsProvider);
        consultants = updatedSpecialistsState.specialists ?? [];

        if (consultants.isEmpty) {
          await ref.read(specialistsProvider.notifier).init();
          if (!ref.mounted) return;
          
          final finalSpecialistsState = ref.read(specialistsProvider);
          consultants = finalSpecialistsState.specialists ?? [];
        }
      }
      
      final chatRepo = ChatRepo(ref);
      final chatModels = await chatRepo.getUserChats();
      
      if (!ref.mounted) return;
      

      final chatItems = <ChatItem>[];
      for (final chatModel in chatModels) {

        SpecialistId? specialistId = _consultantIdToSpecialistId(
          chatModel.consultantId,
          consultants,
        );
        

        if (specialistId == null && chatModel.consultantId >= 1 && chatModel.consultantId <= 5) {
          specialistId = SpecialistId.values[chatModel.consultantId - 1];
        }
        

        if (specialistId == null) {
          print('⚠️ Consultant ID ${chatModel.consultantId} için SpecialistId bulunamadı');
          continue;
        }

        DateTime messageTime;
        if (chatModel.lastMessageDate != null) {
          try {
            if (chatModel.lastMessageDate is String) {
              messageTime = DateTime.parse(chatModel.lastMessageDate as String);
            } else if (chatModel.lastMessageDate is DateTime) {
              messageTime = chatModel.lastMessageDate as DateTime;
            } else {
              messageTime = DateTime.now();
            }
          } catch (e) {
            messageTime = DateTime.now();
          }
        } else {
          messageTime = DateTime.now();
        }

        ConsultantModel? consultant;
        if (consultants.isNotEmpty) {
          consultant = consultants.firstWhere(
            (c) => c.id == chatModel.consultantId,
            orElse: () => ConsultantModel(
              id: -1,
              names: {},
              mainPrompt: '',
              photoURL: '',
              creadtedDate: '',
              explanation: '',
              features: [],
              job: '',
            ),
          );
          if (consultant.id == -1) {
            consultant = null;
          }
        }
        
        // ChatItem oluştur
        final chatItem = ChatItem(
          specialistId: specialistId,
          consultantId: chatModel.consultantId,
          consultant: consultant,
          lastMessage: chatModel.lastMessage,
          time: messageTime,
          unreadCount: 0,
          isFromMe: false,
        );
        
        chatItems.add(chatItem);
      }
      
      print(' ${chatItems.length} chat item oluşturuldu');
      
      // Kullanıcı adını güncelle
      final user = ref.read(AllProviders.userProvider);
      final userName = user?.username ?? state.currentUserName;
      
      if (!ref.mounted) return;
      
      state = state.copyWith(
        chats: chatItems,
        currentUserName: userName,
        isLoading: false,
        error: null,
      );
      
      print('State güncellendi: ${state.chats.length} chat gösteriliyor');
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Hata: $e',
      );
    }
  }

  SpecialistId? _consultantIdToSpecialistId(
    int consultantId,
    List<ConsultantModel> consultants,
  ) {

    if (consultants.isNotEmpty) {
      final consultant = consultants.firstWhere(
        (c) => c.id == consultantId,
        orElse: () => ConsultantModel(
          id: -1,
          names: {},
          mainPrompt: '',
          photoURL: '',
          creadtedDate: '',
          explanation: '',
          features: [],
          job: '',
        ),
      );
      

      if (consultant.id != -1) {
        final names = consultant.names;
 
        for (final nameValue in names.values) {
          if (nameValue is String) {
            final nameLower = nameValue.toLowerCase().trim();
            

            if (nameLower.contains('aura') || nameLower == 'aura') {
              return SpecialistId.aura;
            } else if (nameLower.contains('zen') || nameLower == 'zen') {
              return SpecialistId.zen;
            } else if (nameLower.contains('elara') || nameLower == 'elara') {
              return SpecialistId.elara;
            } else if (nameLower.contains('orion') || nameLower == 'orion') {
              return SpecialistId.orion;
            } else if (nameLower.contains('cyra') || nameLower == 'cyra') {
              return SpecialistId.cyra;
            }
          }
        }
      }
    }
    

    if (consultantId >= 1 && consultantId <= 5) {
      return SpecialistId.values[consultantId - 1];
    }
    
    return null;
  }


  Future<void> refreshChats() async {
    final now = DateTime.now();
    final recentlyRefreshed =
        _lastRefreshAt != null &&
        now.difference(_lastRefreshAt!) < _minRefreshInterval;

    if (_isRefreshing || recentlyRefreshed) return;

    _isRefreshing = true;
    try {
      await _loadChats();
      _lastRefreshAt = DateTime.now();
    } finally {
      _isRefreshing = false;
    }
  }


  Future<void> deleteChat(SpecialistId id) async {

    final chatItem = state.chats.firstWhere(
      (c) => c.specialistId == id,
      orElse: () => ChatItem(
        specialistId: id,
        consultantId: id.index + 1,
        lastMessage: '',
        time: DateTime.now(),
        unreadCount: 0,
        isFromMe: false,
      ),
    );
    
    final consultantId = chatItem.consultantId;
    
    try {

      final chatRepo = ChatRepo(ref);
      await chatRepo.deleteChat(consultantId);
      debugPrint(' Chat backend\'de silindi: consultantId=$consultantId');
    } catch (e) {
      debugPrint(' Chat silme API hatası: $e');

    }

    final filtered = state.chats.where((c) => c.specialistId != id).toList();
    state = state.copyWith(chats: filtered);
    

    try {
      final conversationsNotifier = ref.read(conversationsProvider.notifier);
      conversationsNotifier.clearMessages(consultantId);
      debugPrint(' Chat silindi ve mesajlar temizlendi: consultantId=$consultantId');
    } catch (e) {
      debugPrint('Chat silme sırasında mesaj temizleme hatası: $e');
    }
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


    final consultantId = id.index + 1;

    final newChat = ChatItem(
      specialistId: id,
      consultantId: consultantId,
      lastMessage: 'New chat started.',
      time: DateTime.now(),
      unreadCount: 0,
      isFromMe: true,
    );

    state = state.copyWith(chats: [newChat, ...state.chats]);
  }

  void upsertLastMessage({
    required SpecialistId id,
    required String lastMessage,
    required DateTime time,
    required bool isFromMe,
    int? consultantId,
  }) {
    final idx = state.chats.indexWhere((c) => c.specialistId == id);

    // Consultant bilgisini specialistsProvider'dan bul
    ConsultantModel? _lookupConsultant(int cId) {
      final specialists = ref.read(specialistsProvider).specialists ?? [];
      try {
        final found = specialists.firstWhere((c) => c.id == cId);
        return found;
      } catch (_) {
        return null;
      }
    }

    if (idx == -1) {
      final cId = consultantId ?? id.index + 1;
      final consultant = _lookupConsultant(cId);

      final newItem = ChatItem(
        specialistId: id,
        consultantId: cId,
        consultant: consultant,
        lastMessage: lastMessage,
        time: time,
        unreadCount: 0,
        isFromMe: isFromMe,
      );
      state = state.copyWith(chats: [newItem, ...state.chats]);
      return;
    }

    // Varolan item'ı güncelle — consultant yoksa tekrar dene
    final existing = state.chats[idx];
    ConsultantModel? consultant = existing.consultant;
    if (consultant == null) {
      consultant = _lookupConsultant(
        consultantId ?? existing.consultantId,
      );
    }

    final updated = existing.copyWith(
      lastMessage: lastMessage,
      time: time,
      isFromMe: isFromMe,
      consultant: consultant,
    );

    final list = [...state.chats]..removeAt(idx);
    state = state.copyWith(chats: [updated, ...list]);
  }



}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
