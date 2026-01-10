import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';
import 'package:mindcoach/models/consultant_model.dart';

import '../../../../core/routes/page_routes.dart';
import '../../../../core/utils/screen_size_extensions.dart';
import '../../../specialists_screen/constants/specialists_strings.dart';
import '../../../specialists_screen/specialists_notifier.dart';
import '../../chat_notifier.dart';

class NewChatSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewChatSheetBody(),
    );
  }
}

class _NewChatSheetBody extends ConsumerWidget {
  const _NewChatSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialists = ref.watch(specialistsProvider).specialists;

    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 14.h,
        bottom: 18.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.w)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6E6),
              borderRadius: BorderRadius.circular(10.w),
            ),
          ),
          SizedBox(height: 14.h),

          Text(
            'Start a new chat',
            style: GoogleFonts.quicksand(
              fontSize: 16.w,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: specialists!.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final id = specialists[index];
                return _SpecialistRow(
                  name: id.names[ref.read(localeProvider)?.languageCode ?? "en"],
                  job: id.job,
                  avatarPath: id.photoURL,
                  onTap: () {
                    // attokmak
                  //  ref.read(chatProvider.notifier).startChatWith(id);
                    Navigator.pop(context);

                    Navigator.pushNamed(
                      context,
                      PageRoutes.conversationScreen,
                      arguments: id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialistRow extends StatelessWidget {
  final String name;
  final String job;
  final String avatarPath;
  final VoidCallback onTap;

  const _SpecialistRow({
    required this.name,
    required this.job,
    required this.avatarPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final title = job;
    final avatar = avatarPath;

    return InkWell(
      borderRadius: BorderRadius.circular(18.w),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFF),
          borderRadius: BorderRadius.circular(18.w),
          border: Border.all(color: const Color(0xFFEDEDED)),
        ),
        child: Row(
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2BD383), width: 2),
              ),
              child: ClipOval(
                child: Image.network(avatar, fit: BoxFit.cover),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.quicksand(
                      fontSize: 14.w,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 12.w,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54),
          ],
        ),
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

String _titleFor(BuildContext context, SpecialistId id) {
  switch (id) {
    case SpecialistId.aura:
      return SpecialistsStrings.auraTitle(context);
    case SpecialistId.zen:
      return SpecialistsStrings.zenTitle(context);
    case SpecialistId.elara:
      return SpecialistsStrings.elaraTitle(context);
    case SpecialistId.orion:
      return SpecialistsStrings.orionTitle(context);
    case SpecialistId.cyra:
      return SpecialistsStrings.cyraTitle(context);
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
