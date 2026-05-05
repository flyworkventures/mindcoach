import 'dart:io'; // Platform kontrolü için eklendi
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/ProfileView/notifiers/notification_notifier.dart';
import 'package:mindcoach/app/my_app.dart';
import 'package:mindcoach/app/navbar_provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routes/page_routes.dart';
import '../../../core/utils/context_l10n_extensions.dart';
import '../../../core/widgets/future_progress_dialog.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  // Figma'daki özel renk tanımları
  static const Color textSecondary = Color(0xFF96989C);
  static const Color primaryGreen = Color(0xFF21BC87);
  static const Color borderLight = Color(0x0D000000); // 5% Black

  // --- RATE US (MAĞAZA YÖNLENDİRME) METODU ---
  Future<void> _rateApp() async {
    String urlStr = '';

    if (Platform.isIOS) {
      // iOS için App Store linki (action=write-review direkt yorum ekranını açar)
      urlStr = 'https://apps.apple.com/app/id6757151529?action=write-review';
    } else if (Platform.isAndroid) {
      // Android için Google Play Store linki
      urlStr =
          'https://play.google.com/store/apps/details?id=com.flywork.mindcoachapp';
    }

    if (urlStr.isNotEmpty) {
      final Uri url = Uri.parse(urlStr);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          debugPrint("Could not launch $urlStr");
        }
      } catch (e) {
        debugPrint("Rate app error: $e");
      }
    }
  }

  // --- SHARE FRIEND DIALOG METODU ---
  void _showShareFriendSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ShareFriendBottomSheet(),
    );
  }

  // --- LOGOUT DIALOG METODU ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      // Sadece hafif bir siyahlık veriyoruz ki blur çok çiğ durmasın, yazılar okunsun
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        // İŞTE BÜYÜ BURADA: Arka planı blurlayan widget
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0,
            sigmaY: 8.0,
          ), // Blur yoğunluğu (Değerleri artırırsan daha çok bulanıklaşır)
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                24,
              ), // Ana çerçevenin ovalliği
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Sadece içindekiler kadar yer kapla
                children: [
                  // 1. Tepe İkonu (Kırmızı açık kapı/ok)
                  Center(
                    child: SvgPicture.asset(
                      'assets/icons/ic_log.svg', // Mevcut çıkış ikonunu kullandım
                      width: 48,
                      height: 48,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFF383C), // #FF383C (Figma Accents/Red)
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Başlık
                  Text(
                    context.l10n.logoutDialogTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w600, // SemiBold
                      letterSpacing: -0.3, // Figma'daki -0.3px spacing
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3. Alt Başlık
                  Text(
                    context.l10n.logoutDialogSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w300, // Light
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. Cancel Butonu (Kırmızı)
                  SizedBox(
                    width: double.infinity,
                    height: 50, // Figma height
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Diyaloğu kapat
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF383C), // #FF383C
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // Figma 16px radius
                        ),
                      ),
                      child: Text(
                        context.l10n.cancel,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // Gap 10px
                  // 5. Logout Butonu (Gri)
                  SizedBox(
                    width: double.infinity,
                    height: 50, // Figma height
                    child: ElevatedButton(
                      onPressed: () async {
                        final l10n = context.l10n;
                        Navigator.of(context).pop(); // Dialog'u kapat
                        final rootCtx = navigatorKey.currentContext;
                        ref.read(bottomNavProvider.notifier).reset();
                        try {
                          if (rootCtx != null) {
                            await showFutureProgressDialog<void>(
                              context: rootCtx,
                              message: l10n.pleaseWait,
                              action: () =>
                                  ref.read(AllProviders.authProvider.notifier).logout(),
                            );
                          } else {
                            await ref.read(AllProviders.authProvider.notifier).logout();
                          }
                          navigatorKey.currentState?.pushNamedAndRemoveUntil(
                            PageRoutes.login,
                            (route) => false,
                          );
                        } catch (e) {
                          debugPrint('❌ [LOGOUT] Hata: $e');
                          navigatorKey.currentState?.pushNamedAndRemoveUntil(
                            PageRoutes.login,
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF96989C,
                        ), // #96989C Text Secondary
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            16,
                          ), // Figma 16px radius
                        ),
                      ),
                      child: Text(
                        context.l10n.logout,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notificationsEnabled = ref.watch(
      notificationSettingsProvider.select((s) => s.enabled),
    );
    final userState = ref.watch(AllProviders.userProvider);
    final userModel = ref.watch(AllProviders.userProvider);
    final isPremium = ref.watch(AllProviders.premiumProvider);
    final ppPath = userModel?.profilePhotoUrl ?? '';
    final isGuest = (userState?.credential.toLowerCase() ?? '') == 'guest';
    final credentialData = userState?.credentialData;
    final emailFromCredential = credentialData is Map
        ? credentialData['email']?.toString()
        : null;
    final idString = (userState?.id ?? 0).toString().padLeft(5, '0');
    final idLastFive = idString.length > 5
        ? idString.substring(idString.length - 5)
        : idString;
    final profileEmail = isGuest
        ? '$idLastFive@mindcoach.com'
        : (emailFromCredential?.isNotEmpty == true
              ? emailFromCredential!
              : '$idLastFive@mindcoach.com');

    return Scaffold(
      // Figma arka planı genelde temiz beyaz veya çok açık gridir (tasarıma göre #F9F9F9 vs. yapabilirsin)
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. KULLANICI BİLGİSİ VE PREMİUM BADGE KISMI ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 1),
                      color: Colors.white,
                      image: ppPath.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(ppPath),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState?.username ?? "Jhon Doe",
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 20,
                            fontWeight: FontWeight.w600, // SemiBold
                            color: Colors.black,
                            height: 22 / 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profileEmail,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            fontWeight: FontWeight.w400, // Regular
                            color: textSecondary,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Premium Badge
                  isPremium
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // 10px radius
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Premium İkonu (Asset'ini doğru yola göre ayarlamalısın)
                              SvgPicture.asset(
                                'assets/icons/ic_king.svg', // Crown / Premium ikonu
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.l10n.premiumBadge,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700, // Bold
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),

              const SizedBox(height: 32),

              // --- 2. HESAP AYARLARI (ACCOUNT SETTINGS) GRUBU ---
              _buildSectionTitle(l10n.sectionAccountSettings),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderLight, width: 1), // 5% black
                ),
                child: Column(
                  children: [
                    _buildListItem(
                      iconAsset: 'assets/icons/ic_profile.svg',
                      title: l10n.profileSettings,
                      onTap: () => Navigator.pushNamed(
                        context,
                        PageRoutes.profileSettings,
                      ),
                      isFirst: true,
                    ),
                    _buildListItem(
                      iconAsset: 'assets/icons/ic_bell.svg',
                      title: l10n.notifications,
                      trailing: Transform.scale(
                        scale: 00.8,
                        child: Padding(
                          padding: EdgeInsets.zero,
                          child: CupertinoSwitch(
                            value: notificationsEnabled,
                            activeTrackColor: primaryGreen,
                            onChanged: (val) {
                              ref
                                  .read(notificationSettingsProvider.notifier)
                                  .setEnabled(val);
                            },
                          ),
                        ),
                      ),
                    ),
                    _buildListItem(
                      iconAsset: 'assets/icons/ic_flag.svg', // Varsa dil ikonu
                      title: l10n.language,
                      onTap: () => Navigator.pushNamed(
                        context,
                        PageRoutes.languageSelection,
                      ),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. GENEL (GENERAL) GRUBU ---
              _buildSectionTitle(l10n.sectionGeneral),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderLight, width: 1),
                ),
                child: Column(
                  children: [
                    _buildListItem(
                      iconAsset:
                          'assets/icons/ic_award.svg', // Varsa premium menü ikonu
                      title: l10n.menuItemPremium,
                      trailingText: l10n.premiumStatusActive,
                      trailingTextColor: primaryGreen,
                      onTap: () async {
                        await RevenueCatUI.presentPaywall();
                      },
                      isFirst: true,
                    ),
                    _buildListItem(
                      iconAsset: 'assets/icons/ic_share.svg',
                      title: l10n.shareWithFriends,
                      onTap: () => _showShareFriendSheet(context),
                    ),
                    _buildListItem(
                      iconAsset: 'assets/icons/ic_rate.svg', // Rate us ikonu
                      title: l10n.menuItemRateUs,
                      onTap: _rateApp, // GÜNCELLENEN KISIM BURASI
                    ),
                    _buildListItem(
                      iconAsset: 'assets/icons/ic_faq.svg',
                      title: l10n.faq,
                      onTap: () => Navigator.pushNamed(context, PageRoutes.faq),
                    ),
                    _buildListItem(
                      iconAsset: 'assets/icons/ic_post.svg',
                      title: l10n.appointments,
                      onTap: () =>
                          Navigator.pushNamed(context, PageRoutes.appointments),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 4. ÇIKIŞ YAP (LOGOUT) BUTONU ---
              GestureDetector(
                onTap: _showLogoutDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFECEC,
                          ), // Kırmızımsı arka plan
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/ic_log.svg', // Çıkış ikonu
                          colorFilter: const ColorFilter.mode(
                            Colors.redAccent,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.logout,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w500, // Medium
          color: textSecondary, // #96989C
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF5F5F5), // Çok açık gri çizgi
      indent:
          56, // İkonun altını boş bırakıp yazıdan başlatmak için (Figma stilinde ise ayarlarsın)
      endIndent: 16,
    );
  }

  Widget _buildListItem({
    required String iconAsset,
    required String title,
    Widget? trailing,
    String? trailingText,
    Color? trailingTextColor,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // İkon Kutusu
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                iconAsset,
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(
                  primaryGreen,
                  BlendMode.srcIn,
                ), // İkonları yeşil yapar
                fit: BoxFit.scaleDown,
              ),
            ),
            const SizedBox(width: 16),

            // Başlık
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),

            // Sağ taraf (Switch, Ok veya Aktif Yazısı)
            if (trailing != null)
              trailing // SADECE BU KADAR! Başka hiçbir şeye sarmaya gerek yok.
            else if (trailingText != null)
              Row(
                children: [
                  Text(
                    trailingText,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: trailingTextColor ?? textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset("assets/icons/ic_righta.svg"),
                ],
              )
            else
              SvgPicture.asset("assets/icons/ic_righta.svg"),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// YENİ ADIM: SHARE FRIEND BOTTOM SHEET
// -----------------------------------------------------------------------------
class _ShareFriendBottomSheet extends StatelessWidget {
  const _ShareFriendBottomSheet();

  final String shareUrl = "https://fly-work.com/mindcoach/download/";

  /// Eski davranış kutuya basınca linki tarayıcıda açıyordu (mağaza /
  /// indirme sayfası). Yeni davranış: native iOS/Android paylaşım sheet'ini
  /// açar, kullanıcı linki istediği uygulamada (WhatsApp, Mesaj, Mail,
  /// Twitter, vb.) paylaşabilir.
  Future<void> _shareLink(BuildContext context) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final Rect? sharePositionOrigin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    await SharePlus.instance.share(
      ShareParams(
        text: shareUrl,
        subject: 'Mind Coach',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareUrl));
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    final messenger = ScaffoldMessenger.of(rootContext);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.linkCopied),
        backgroundColor: const Color(0xFF21BC87),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          20 + MediaQuery.of(rootContext).viewPadding.bottom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Üst Sürükleme Çubuğu (Handle)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  width: 33,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF96989C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Başlık ve Çarpı İkonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.shareFriend,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 14 / 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF96989C), // Gri kenarlık
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF96989C),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Link Kutusu Alanı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () => _shareLink(context),
                child: Container(
                  padding: const EdgeInsets.all(10), // Padding 10px
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      999,
                    ), // Tam yuvarlak (Pill)
                    border: Border.all(
                      color: Colors.black.withOpacity(
                        0.50,
                      ), // 1px Siyah %50 Opaklık
                      width: 1,
                    ),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      // Soldaki Link İkonu
                      const Icon(Icons.link, size: 20, color: Colors.black),
                      const SizedBox(width: 10), // Gap 10px
                      // Link Yazısı
                      Expanded(
                        child: Text(
                          shareUrl,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14,
                            fontWeight: FontWeight.w400, // Regular
                            color: Colors.black,
                            height: 20 / 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 10), // Gap 10px
                      // Kopyala Butonu
                      GestureDetector(
                        onTap: () =>
                            _copyLink(context), // İkona basınca kopyalar
                        child: Container(
                          color: Colors
                              .transparent, // Tıklama alanını genişletmek için
                          padding: const EdgeInsets.only(left: 4),
                          child: const Icon(
                            Icons
                                .content_paste_outlined, // Resimdeki clipboard ikonuna benzer
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
