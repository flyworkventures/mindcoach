import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../specialists_screen/constants/specialists_strings.dart';
import '../../../specialists_screen/specialists_notifier.dart';
import '../../../../core/routes/page_routes.dart';
import '../../../../core/utils/screen_size_extensions.dart';
import '../../../../core/utils/time_format_utils.dart';
import '../../../../core/widgets/top_toast.dart';

import '../../chat_notifier.dart';
import '../../constants/chat_strings.dart';
import '../widgets/new_chat_sheet.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final currentUserName = chatState.currentUserName;

    final uiChats = chatState.chats
        .map(
          (c) => _ChatItem(
        id: c.specialistId,
        name: _nameFor(context, c.specialistId),
        lastMessage: c.lastMessage,
        time: c.time,
        unreadCount: c.unreadCount,
        isFromMe: c.isFromMe,
        avatarPath: _avatarPathFor(c.specialistId),
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
                        Text(
                          ChatStrings.greeting(context, currentUserName),
                          style: GoogleFonts.quicksand(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            height: 24 / 32,
                            color: Colors.black,
                          ),
                        ),
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
                      child: ListView.separated(
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
        ],
      ),
    );
  }
}

class _ChatItem {
  final SpecialistId id;
  final String name;
  final String lastMessage;
  final DateTime time;
  final int unreadCount;
  final bool isFromMe;
  final String avatarPath;

  _ChatItem({
    required this.id,
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

        Navigator.pushNamed(
          context,
          PageRoutes.conversationScreen,
          arguments: item.id,
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
                  onPressed: (context) {
                    ref.read(chatProvider.notifier).deleteChat(item.id);

                    showTopToast(
                      context,
                      ChatStrings.deleteToast(context, item.name),
                    );
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
                      child: Image.asset(
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

    if (!item.isFromMe) {
      return Text(
        item.lastMessage,
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
          TextSpan(text: item.lastMessage, style: baseStyle),
        ],
      ),
    );
  }
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
