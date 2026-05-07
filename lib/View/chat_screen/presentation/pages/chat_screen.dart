import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/routes/page_routes.dart';
import '../../../../core/utils/context_l10n_extensions.dart';
import '../../../../core/utils/job_convert.dart';
import '../../../../core/utils/time_format_utils.dart';
import '../../../../models/consultant_model.dart';
import '../../../specialists_screen/specialists_notifier.dart';
import '../../chat_notifier.dart';
import '../../constants/chat_strings.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  List<ConsultantModel> _quickMessageCoaches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(chatProvider.notifier).refreshChats();
        _pickRandomCoaches();
      }
    });
  }

  void _pickRandomCoaches() {
    final specialists = ref.read(specialistsProvider).specialists ?? [];
    if (specialists.isEmpty) return;

    final shuffled = List<ConsultantModel>.from(specialists)..shuffle(Random());
    setState(() {
      _quickMessageCoaches = shuffled.take(2).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chatState = ref.watch(chatProvider);

    // Quick message koçları henüz yüklenmediyse tekrar dene
    if (_quickMessageCoaches.isEmpty) {
      final specialists = ref.watch(specialistsProvider).specialists ?? [];
      if (specialists.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _quickMessageCoaches.isEmpty) _pickRandomCoaches();
        });
      }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Quick Message ──
              Text(
                l.quickMessage,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 24 / 18,
                ),
              ),
              const SizedBox(height: 16),

              // Quick message coach cards — 2 columns
              if (_quickMessageCoaches.isNotEmpty)
                Row(
                  children: [
                    for (int i = 0; i < _quickMessageCoaches.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _QuickMessageCard(
                          coach: _quickMessageCoaches[i],
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 28),

              // ── History ──
              Text(
                l.chatHistory,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 24 / 18,
                ),
              ),
              const SizedBox(height: 16),

              if (chatState.isLoading && uiChats.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(color: Color(0xFF21BC87)),
                  ),
                )
              else if (uiChats.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      l.noChatHistory,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        color: Color(0xFF96989C),
                      ),
                    ),
                  ),
                )
              else
                ...uiChats.asMap().entries.map((entry) {
                  int index = entry.key;
                  _ChatItem chat = entry.value;

                  return Column(
                    children: [
                      _HistoryChatTile(item: chat),
                      // Son elemanın altına çizgi koymamak için kontrol
                      if (index != uiChats.length - 1)
                        Padding(
                          // Figma'daki Padding (Top 8, Bottom 8, Left 1, Right 1)
                          padding: const EdgeInsets.fromLTRB(1, 4, 1, 4),
                          child: const Divider(
                            height: 0, // Figma: 0px height
                            thickness: 1, // Figma: 0.5px border
                            color: Color(
                              0x1A000000,
                            ), // Figma: %10 Siyah (#000000)
                          ),
                        ),
                    ],
                  );
                }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Message Card ──
// Figma: 195x248 fixed, radius 16, border 1px #000000 5%, padding 10, gap 10

class _QuickMessageCard extends ConsumerWidget {
  final ConsultantModel coach;

  const _QuickMessageCard({required this.coach});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final langCode = context.langCode;

    final name =
        coach.names[langCode] as String? ??
        coach.names['en'] as String? ??
        coach.names.values.first.toString();

    final jobTitle = JobConvert(coach.job, context).call();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          PageRoutes.conversationScreen,
          arguments: coach,
        );
      },
      child: Container(
        height: 248,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF6F6F6), // Üstteki açık gri
                        Color.fromARGB(
                          255,
                          49,
                          43,
                          43,
                        ), // Alttaki koyu siyahımsı renk
                      ],
                    ),
                  ),
                  width: double.infinity,
                  child: _coachImage(
                    coach.photoURL,
                    isMale: _hasMaleRole(coach.roles),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Name — Geist 600, 20px
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 28 / 20,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Job — Geist 400, 12px, #96989C
            Text(
              jobTitle,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF96989C),
                height: 16 / 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Message button — fill width, height 34, radius 8, #21BC87
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  PageRoutes.conversationScreen,
                  arguments: coach,
                );
              },
              child: Container(
                width: double.infinity,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF21BC87),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset("assets/icons/ic_buble.svg"),
                    const SizedBox(width: 4),
                    Text(
                      l.chatMessage,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coachImage(String url, {bool isMale = false}) {
    final isSvg = url.toLowerCase().endsWith('.svg');

    Widget fallback() => Container(
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.person, size: 40, color: Color(0xFF96989C)),
    );

    if (isSvg) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      alignment: isMale ? const Alignment(0, -0.15) : Alignment.topCenter,
      errorWidget: (_, _, _) => fallback(),
      placeholder: (_, _) => const SizedBox.shrink(),
    );
  }

  bool _hasMaleRole(List? roles) {
    if (roles == null || roles.isEmpty) return false;
    return roles.any((r) => r.toString().toLowerCase() == 'male');
  }
}

// ── History Chat Tile ──

class _HistoryChatTile extends ConsumerWidget {
  final _ChatItem item;

  const _HistoryChatTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultantModel = _resolveConsultant(ref, item);
    final isMale = _hasMaleRole(consultantModel.roles);
    return InkWell(
      onTap: () {
        ref.read(chatProvider.notifier).markChatRead(item.id);
        Navigator.pushNamed(
          context,
          PageRoutes.conversationScreen,
          arguments: consultantModel,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Avatar — circular, 48x48, green border
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF21BC87), width: 2),
              ),
              child: ClipOval(
                child: Transform.translate(
                  offset: Offset(0, isMale ? 0 : 4),
                  child: item.avatarPath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: item.avatarPath,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorWidget: (_, _, _) => Image.asset(
                            'assets/images/profile_avatar.jpeg',
                            fit: BoxFit.contain,
                          ),
                          placeholder: (_, _) => const SizedBox.shrink(),
                        )
                      : Image.asset(item.avatarPath, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + Last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 20 / 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _LastMessageText(item: item),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Time
            Text(
              TimeFormatUtils.formatTime(context, item.time),
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF96989C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ConsultantModel _resolveConsultant(WidgetRef ref, _ChatItem item) {
    if (item.consultant != null) return item.consultant!;

    final specialists = ref.read(specialistsProvider).specialists ?? [];
    final found = specialists.where((c) => c.id == item.consultantId);
    if (found.isNotEmpty) return found.first;

    return ConsultantModel(
      id: item.consultantId,
      names: {'tr': item.name, 'en': item.name},
      mainPrompt: '',
      photoURL: item.avatarPath.startsWith('http') ? item.avatarPath : '',
      creadtedDate: '',
      explanation: '',
      features: [],
      job: '',
    );
  }

  bool _hasMaleRole(List? roles) {
    if (roles == null || roles.isEmpty) return false;
    return roles.any((r) => r.toString().toLowerCase() == 'male');
  }
}

// ── Last Message Text ──

class _LastMessageText extends StatelessWidget {
  final _ChatItem item;
  const _LastMessageText({required this.item});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Geist',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Color(0xFF96989C),
      height: 16 / 12,
    );

    final msg = item.lastMessage.trim();
    if (msg.isEmpty) {
      return Text(
        context.l10n.noChatHistory,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(fontStyle: FontStyle.italic),
      );
    }

    if (!item.isFromMe) {
      return Text(
        msg,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(
            text: ChatStrings.youPrefix(context),
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: msg, style: style),
        ],
      ),
    );
  }
}

// ── Data Models & Helpers ──

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

String _getNameForChat(BuildContext context, ChatItem chatItem) {
  if (chatItem.consultant != null) {
    final names = chatItem.consultant!.names;
    final langCode = Localizations.localeOf(context).languageCode;

    if (names.containsKey(langCode) && names[langCode] is String) {
      return names[langCode] as String;
    }
    if (names.containsKey('tr') && names['tr'] is String) {
      return names['tr'] as String;
    }
    if (names.containsKey('en') && names['en'] is String) {
      return names['en'] as String;
    }
    for (final value in names.values) {
      if (value is String && value.isNotEmpty) return value;
    }
  }

  return _nameForFallback(chatItem.specialistId);
}

String _getAvatarPathForChat(ChatItem chatItem) {
  if (chatItem.consultant != null && chatItem.consultant!.photoURL.isNotEmpty) {
    return chatItem.consultant!.photoURL;
  }
  return _avatarPathFor(chatItem.specialistId);
}

String _nameForFallback(SpecialistId id) {
  switch (id) {
    case SpecialistId.aura:
      return 'Aura';
    case SpecialistId.zen:
      return 'Zen';
    case SpecialistId.elara:
      return 'Elara';
    case SpecialistId.orion:
      return 'Orion';
    case SpecialistId.cyra:
      return 'Cyra';
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
