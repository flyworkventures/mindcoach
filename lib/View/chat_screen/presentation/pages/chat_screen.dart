import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../specialists_screen/constants/specialists_strings.dart';
import '../../../specialists_screen/specialists_notifier.dart';
import '../../../../core/routes/page_routes.dart';
import '../../../../core/utils/time_format_utils.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../../../models/consultant_model.dart';

import '../../chat_notifier.dart';
import '../../constants/chat_strings.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açıldığında chat listesini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatProvider.notifier).refreshChats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final currentUserName = chatState.currentUserName;

    // Error durumu
    if (chatState.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.90, -1.0),
              end: Alignment(1.0, 1.0),
              colors: [Color(0xFFFBFCFF), Color(0xFFF9FAFF)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    chatState.error!,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(chatProvider.notifier).refreshChats();
                    },
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final uiChats = chatState.chats
        .map(
          (c) => _ChatItem(
        id: c.specialistId,
        consultantId: c.consultantId,
        consultant: c.consultant,
        name: _getNameForChat(context, c),
        lastMessage: c.lastMessage,
        time: c.time,
        unreadCount: c.unreadCount,
        isFromMe: c.isFromMe,
        avatarPath: _getAvatarPathForChat(c),
      ),
    )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.90, -1.0),
                end: Alignment(1.0, 1.0),
                colors: [Color(0xFFFBFCFF), Color(0xFFF9FAFF)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(
                          ChatStrings.greeting(context, currentUserName),
                          style: GoogleFonts.quicksand(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            height: 24 / 32,
                            color: Colors.black,
                          ),
                        )),
                       
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      ChatStrings.screenTitle(context),
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 24 / 20,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Expanded(
                      child: chatState.isLoading && uiChats.isEmpty
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : uiChats.isEmpty
                              ? Center(
                                  child: Text(
                                    'Henüz sohbet yok',
                                    style: GoogleFonts.quicksand(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 96),
                                  itemCount: uiChats.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final chat = uiChats[index];
                                    return _ChatCard(item: chat);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),


/*
          Positioned(
            right: 24.w,
            bottom: 8.h + 2 * kBottomNavigationBarHeight,
            child: GestureDetector(
              onTap: () {
                NewChatSheet.show(context);
              },
              child: Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2BD383), Color(0xFF11998E)],
                  ),
                ),
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, 3),
                    child: SvgPicture.asset(
                      'assets/svg/chat_symbol.svg',
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
          */
        ],
      ),
    );
  }
}

class _ChatItem {
  final SpecialistId id;
  final int consultantId;
  final ConsultantModel? consultant;
  final String name;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final bool isFromMe;
  final String avatarPath;

  _ChatItem({
    required this.id,
    required this.consultantId,
    this.consultant,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isFromMe,
    required this.avatarPath,
  });
}

class _ChatCard extends ConsumerWidget {
  final _ChatItem item;

  const _ChatCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double cardRadius = 24.0;
    const borderColor = Color(0xFFDEDEDE);

    return InkWell(
      onTap: () {
        ref.read(chatProvider.notifier).markChatRead(item.id);

        // ConsultantModel'i hazırla
        ConsultantModel consultantModel;
        
        // Önce item'dan consultant'ı al
        if (item.consultant != null) {
          consultantModel = item.consultant!;
        } else {
          // Eğer consultant yoksa, consultants listesinden bul
          final specialistsState = ref.read(specialistsProvider);
          final consultants = specialistsState.specialists ?? [];
          
          final foundConsultant = consultants.firstWhere(
            (c) => c.id == item.consultantId,
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
          
          // Eğer consultant bulunduysa kullan, yoksa fallback oluştur
          if (foundConsultant.id != -1) {
            consultantModel = foundConsultant;
          } else {
            // Fallback: Minimal ConsultantModel oluştur
            consultantModel = ConsultantModel(
              id: item.consultantId,
              names: {'tr': item.name, 'en': item.name}, // Mevcut name'i kullan
              mainPrompt: '',
              photoURL: item.avatarPath.startsWith('http') ? item.avatarPath : '',
              creadtedDate: '',
              explanation: '',
              features: [],
              job: '',
            );
          }
        }

        Navigator.pushNamed(
          context,
          PageRoutes.conversationScreen,
          arguments: consultantModel,
        );
      },
      borderRadius: BorderRadius.circular(cardRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          height: 93,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Slidable(
            key: ValueKey(item.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.3,
              children: [
                CustomSlidableAction(
                  onPressed: (context) async {
                    try {
                      await ref.read(chatProvider.notifier).deleteChat(item.id);
                      showTopToast(
                        context,
                        ChatStrings.deleteToast(context, item.name),
                      );
                    } catch (e) {
                      // Hata durumunda kullanıcıya bilgi ver
                      showTopToast(
                        context,
                        'Sohbet silinirken bir hata oluştu',
                      );
                    }
                  },
                  backgroundColor: const Color(0xFFFE4A49),
                  child: SvgPicture.asset(
                    'assets/svg/delete.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 61,
                    height: 61,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2BD383),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: item.avatarPath.startsWith('http')
                          ? Image.network(
                              item.avatarPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/profile_avatar.jpeg',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              item.avatarPath,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.quicksand(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 24 / 17,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _LastMessageText(item: item),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        TimeFormatUtils.formatTime(context, item.time),
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          height: 18 / 10,
                          color: const Color(0xFF2BD383),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (item.unreadCount > 0)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2BD383),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.unreadCount.toString(),
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LastMessageText extends StatelessWidget {
  final _ChatItem item;

  const _LastMessageText({required this.item});

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.quicksand(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 18 / 12,
      color: Colors.black87,
    );

    // Son mesaj boşsa veya null ise placeholder göster
    final lastMessage = item.lastMessage.trim();
    if (lastMessage.isEmpty) {
      return Text(
        'Henüz mesaj yok',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle.copyWith(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (!item.isFromMe) {
      return Text(
        lastMessage,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: ChatStrings.youPrefix(context),
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: lastMessage, style: baseStyle),
        ],
      ),
    );
  }
}

String _getNameForChat(BuildContext context, ChatItem chatItem) {
  // Önce consultant bilgilerini kullan
  if (chatItem.consultant != null) {
    final names = chatItem.consultant!.names;
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;
    
    // Önce mevcut dil kodunu dene (tr, en)
    if (names.containsKey(langCode) && names[langCode] is String) {
      return names[langCode] as String;
    }
    
    // Fallback: tr veya en
    if (names.containsKey('tr') && names['tr'] is String) {
      return names['tr'] as String;
    }
    if (names.containsKey('en') && names['en'] is String) {
      return names['en'] as String;
    }
    
    // İlk bulunan string değeri kullan
    for (final value in names.values) {
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
  }
  
  // Consultant yoksa SpecialistId'ye göre fallback
  return _nameFor(context, chatItem.specialistId);
}

String _getAvatarPathForChat(ChatItem chatItem) {
  // Önce consultant'ın photoURL'ini kullan
  if (chatItem.consultant != null && 
      chatItem.consultant!.photoURL.isNotEmpty) {
    return chatItem.consultant!.photoURL;
  }
  
  // Consultant yoksa SpecialistId'ye göre fallback
  return _avatarPathFor(chatItem.specialistId);
}

String _nameFor(BuildContext context, SpecialistId id) {
  switch (id) {
    case SpecialistId.aura:
      return SpecialistsStrings.auraName(context);
    case SpecialistId.zen:
      return SpecialistsStrings.zenName(context);
    case SpecialistId.elara:
      return SpecialistsStrings.elaraName(context);
    case SpecialistId.orion:
      return SpecialistsStrings.orionName(context);
    case SpecialistId.cyra:
      return SpecialistsStrings.cyraName(context);
  }
}

String _avatarPathFor(SpecialistId id) {
  switch (id) {
    case SpecialistId.aura:
      return 'assets/images/kızıl.png';
    case SpecialistId.zen:
      return 'assets/images/zen.png';
    case SpecialistId.elara:
      return 'assets/images/elara.png';
    case SpecialistId.orion:
      return 'assets/images/orion.png';
    case SpecialistId.cyra:
      return 'assets/images/cyra.png';
  }
}
