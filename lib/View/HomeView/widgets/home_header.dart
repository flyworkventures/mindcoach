import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isPremium = ref.watch(AllProviders.premiumProvider);
    final userModel = ref.watch(AllProviders.userProvider);
    final userName = userModel?.username ?? '';
    final ppPath = userModel?.profilePhotoUrl ?? '';

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          // Profile photo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1),
              color: Colors.white,
              image: ppPath.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(ppPath),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: ppPath.isEmpty
                ? ClipOval(
                    child: SvgPicture.asset(
                      'assets/icons/ic_mind_profile.svg',
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.welcome}, $userName',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 20 / 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l.howAreYouFeelIngToday,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF96989C),
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),

          // Premium crown icon (only for premium users)
          if (isPremium)
            GestureDetector(
              onTap: () async {
                await RevenueCatUI.presentPaywall();
              },
              child: SvgPicture.asset("assets/icons/ic_prof_badge.svg"),
            ),
          if (isPremium) const SizedBox(width: 8),

          // Notification bell
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, PageRoutes.notifications);
            },
            child: SvgPicture.asset("assets/icons/ic_not.svg"),
          ),
        ],
      ),
    );
  }
}
