import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import '../../../core/utils/context_l10n_extensions.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  final String inviteLink =
      'https://mindlog.app/invite?friend=XXXXX'; // dummy, sonra gerçek link

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final l10n = context.l10n;


    return Scaffold(
      body: Stack(
        children: [
          // FULLSCREEN BACKGROUND IMAGE
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: -50,
            child: Image.asset(
              'assets/images/invite_friends.png',
              fit: BoxFit.cover,
            ),
          ),


          // OVERLAY CONTENT
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // BACK BUTTON
                  // Üst bar: back + title
                  Row(
                    children: [
                      // BACK BUTTON
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svg/arrow_back.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        'Mind Coach',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: -0.1,
                          color: Colors.white,
                        ),
                      ),

                      const Spacer(),

                      const SizedBox(width: 34), // back ile simetrik boşluk
                    ],
                  ),

                  // SizedBox(height: 10),

                  // aşağısı aynı: Invite People, description vs.
                  SizedBox(height: 32),
                  // "Invite People"
                  Text(
                    l10n.invitePeople,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.w700, // Bold
                      height: 30 / 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Alt açıklama
                  Text(
                    l10n.copyLinkInviteFriend,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 22 / 15,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // İKİLİ PILL: LINK + SHARE BUTTON
                  _InviteLinkRow(
                    inviteLink: inviteLink,
                    onShareTap: () {
                      // TODO: burada Share logic / Clipboard vs.
                      // örn: Share.share(inviteLink);
                    },
                    maxWidth: screenWidth * 0.8,
                  ),

                  SizedBox(height: 48.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteLinkRow extends StatelessWidget {
  final String inviteLink;
  final VoidCallback onShareTap;
  final double maxWidth;

  const _InviteLinkRow({
    required this.inviteLink,
    required this.onShareTap,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Container(
        width: 250.w,
        height: 42.h,
        decoration: BoxDecoration(
          color: const Color(0x99FFFFFF), // büyük pill
          borderRadius: BorderRadius.circular(40),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            // SOL: Link alanı (küçük pill için yer bırakmadan)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  inviteLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // SAĞ: Share butonu (tam sağa yapışık)
            GestureDetector(
              onTap: onShareTap,
              child: Container(
                width: 64.w,
                // küçük rectangle genişliği
                height: 42.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2BD383), Color(0xFF11998E)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.share,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
