import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';

import 'package:mindcoach/Riverpod/providers/user_provider.dart';
import 'package:mindcoach/View/ProfileView/notifiers/notification_notifier.dart';
import 'package:mindcoach/View/ProfileView/notifiers/subscription_notifier.dart';
import 'package:mindcoach/View/ProfileView/presentation/widgets/notification_card.dart';
import 'package:mindcoach/View/ProfileView/presentation/widgets/profile_menu_card.dart';

import '../../../../core/routes/page_routes.dart';
import '../../../../core/utils/context_l10n_extensions.dart';
import '../../../../core/utils/screen_size_extensions.dart';





class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const gradientStart = Color(0xFF11998E);
    const gradientEnd = Color(0xFF38EF7D);
    const profileGreen = Color(0xFF2BD383);

    final l10n = context.l10n;

    final userState = ref.watch(AllProviders.userProvider);
    final planType = ref.watch(subscriptionProvider.select((s) => s.plan));
    final notificationsEnabled =
    ref.watch(notificationSettingsProvider.select((s) => s.enabled));

    // Plan metni (free / premium)
    final String planLabel = (planType == PlanType.premium)
        ? 'premium plan'
        : '${l10n.free.toLowerCase()} plan';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // MIND COACH (gradient text)
              Center(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [gradientStart, gradientEnd],
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    );
                  },
                  child: Text(
                    'Mind Coach',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      letterSpacing: -0.1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // HEADER: avatar + name + mail + plan
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar (86x86)
                  Container(
                    width: 86.w,
                    height: 86.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(userState?.profilePhotoUrl??"https://mindcoach.b-cdn.net/1024x1024.jpg"),
                        fit: BoxFit.cover,
                      ),
                      
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState?.username ?? "MindCoach User",
                          style: GoogleFonts.quicksand(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if( userState?.credentialData["email"] != null)
                        Text(
                          userState?.credentialData["email"] ?? "",
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                            color: const Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(height: 10),
                        IntrinsicWidth(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(27.w),
                              border: Border.all(
                                color: const Color(0xFF686868),
                                width: 1.w,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              child: Text(
                                planLabel,
                                style: GoogleFonts.quicksand(
                                  fontSize: 10.w,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                  color: const Color(0xFF5A5A5A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==== CARDS ====
              ProfileMenuCard(
                title: l10n.profileSettings,
                iconAsset: 'assets/svg/profile_icon.svg',
                iconBgColor: const Color(0x692BD383), // #2BD38369
                titleColor: profileGreen,
                borderColor: const Color(0xFFE3E3E3),
                iconStrokeColor: const Color(0xff11998E),
                arrowType: ProfileArrowType.greenOutlined,
                onTap: () => Navigator.pushNamed(context, PageRoutes.profileSettings),
              ),
              const SizedBox(height: 12),
/*
              ProfileMenuCard(
                title: 'Premium!',
                iconAsset: 'assets/svg/premium.svg',
                iconBgColor: const Color(0xFFF4F4F4),
                titleColor: Colors.black,
                borderColor: const Color(0xFFE3E3E3),
                iconStrokeColor: const Color(0xFF505050),
                arrowType: ProfileArrowType.black,
                onTap: () => Navigator.pushNamed(context, PageRoutes.premimum),
              ),

              */
              const SizedBox(height: 12),

              ProfileMenuCard(
                title: l10n.shareWithFriends,
                iconAsset: 'assets/svg/share_with_friends.svg',
                iconBgColor: const Color(0xFFF4F4F4),
                titleColor: Colors.black,
                borderColor: const Color(0xFFE3E3E3),
                iconStrokeColor: const Color(0xFF505050),
                arrowType: ProfileArrowType.black,
                onTap: () => Navigator.pushNamed(context, PageRoutes.invite),
              ),
              const SizedBox(height: 12),

       

              NotificationCard(
                iconAsset: 'assets/svg/notification.svg',
                title: l10n.notifications,
                borderColor: const Color(0xFFE3E3E3),
                value: notificationsEnabled,
                onChanged: (val) {
                  ref.read(notificationSettingsProvider.notifier).setEnabled(val);
                },
              ),
              const SizedBox(height: 12),

              ProfileMenuCard(
                title: l10n.appointments,
                iconAsset: 'assets/svg/past_appointments.svg',
                iconBgColor: const Color(0xFFF4F4F4),
                titleColor: Colors.black,
                borderColor: const Color(0xFFE3E3E3),
                iconStrokeColor: const Color(0xFF505050),
                arrowType: ProfileArrowType.black,
                onTap: () => Navigator.pushNamed(context, PageRoutes.appointments),
              ),
              const SizedBox(height: 12),

              ProfileMenuCard(
                title: l10n.faq,
                iconAsset: 'assets/svg/faq.svg',
                iconBgColor: const Color(0xFFF4F4F4),
                titleColor: Colors.black,
                borderColor: const Color(0xFFE3E3E3),
                iconStrokeColor: const Color(0xFF505050),
                arrowType: ProfileArrowType.black,
                onTap: () => Navigator.pushNamed(context, PageRoutes.faq),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
