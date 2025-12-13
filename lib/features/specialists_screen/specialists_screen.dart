import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/routes/page_routes.dart';
import '../../core/utils/screen_size_extensions.dart';
import 'constants/specialists_strings.dart';
import 'specialists_notifier.dart';
import 'presentation/widgets/specialists_filter_sheet.dart';

class SpecialistsScreen extends ConsumerWidget {
  const SpecialistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(specialistsProvider);

    // Provider'dan gelen SpecialistId listesini UI view model'e çeviriyoruz
    final specialists = state.specialists
        .map(
          (id) => _SpecialistItem(
        id: id,
        name: _nameFor(context, id),
        title: _titleFor(context, id),
        description: _descriptionFor(context, id),
        avatarPath: _avatarPathFor(id),
      ),
    )
        .toList();

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      SpecialistsStrings.screenTitle(context),
                      style: GoogleFonts.quicksand(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 24 / 17,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final selected = await SpecialistsFilterSheet.show(
                          context,
                          initial: state.filters,
                        );

                        if (selected != null) {
                          ref.read(specialistsProvider.notifier).setFilters(selected);
                        }
                      },
                      icon: SvgPicture.asset(
                        'assets/svg/filter_icon.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // LİSTE
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                      left: 2,
                      right: 2,
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemCount: specialists.length,
                    itemBuilder: (context, index) {
                      final item = specialists[index];
                      return _SpecialistCard(item: item);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// View model sadece UI için
class _SpecialistItem {
  final SpecialistId id;
  final String name;
  final String title;
  final String description;
  final String avatarPath;

  _SpecialistItem({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.avatarPath,
  });
}

class _SpecialistCard extends ConsumerWidget {
  final _SpecialistItem item;

  const _SpecialistCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double cardRadius = 24.0;

    return GestureDetector(
      onTap: () {
        ref.read(specialistsProvider.notifier).selectSpecialist(item.id);

        Navigator.pushNamed(
          context,
          PageRoutes.conversationScreen,
          arguments: item.id,
        );
      },
      child: Container(
        height: 122.h,
        width: double.infinity,
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // AVATAR
              Container(
                width: 81.w,
                height: 81.h,
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

              const SizedBox(width: 14),

              // TEXTS
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
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 18 / 12,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 18 / 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SvgPicture.asset(
                  'assets/svg/right_arrow.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// mapping fonksiyonları aynı (dokunmadım)
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

String _descriptionFor(BuildContext context, SpecialistId id) {
  switch (id) {
    case SpecialistId.aura:
      return SpecialistsStrings.auraDescription(context);
    case SpecialistId.zen:
      return SpecialistsStrings.zenDescription(context);
    case SpecialistId.elara:
      return SpecialistsStrings.elaraDescription(context);
    case SpecialistId.orion:
      return SpecialistsStrings.orionDescription(context);
    case SpecialistId.cyra:
      return SpecialistsStrings.cyraDescription(context);
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
