import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'dart:io';

import '../../../../core/utils/screen_size_extensions.dart';

// Stil Sabitleri
const Color _kRedExit = Color(0xFFDE4141);
const Color _kAppbarGreen = Color(0xFF11998E);
const Color _kLiveText = Color(0xFF111111); // Live yazısı rengi

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // Arka Plan Gradient'i
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFBFCFF), // Hafif beyaz
              Color(0xFFF9FAFF), // Hafif gri
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. ÜST BAŞLIK (Live + İkon)
              _buildLiveHeader(context),

              // 2. ANA VİDEO ALANI (Geniş Kart)
              Expanded(child: _buildVideoCard(context)),

              // 3. ALT KONTROL BUTONLARI
              _buildControlButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Live Başlığı ---
  Widget _buildLiveHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pop(context); // Önceki ekrana geri dön
              },
              icon: SvgPicture.asset(
                  'assets/svg/arrow_back.svg',
                  width: 12.w,
                  colorFilter: const ColorFilter.mode(_kLiveText, BlendMode.srcIn)
              ),
            ),
          ),

          // Orta: Live Yazısı ve İkon (Merkezlenmiş)
          // Tek bir widget olarak gruplayıp, Row içinde Center ile ortalamak daha temizdir.
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Svg Iconu (Video Call)
                SvgPicture.asset(
                    'assets/svg/video_call.svg',
                    width: 22.w,
                    colorFilter: const ColorFilter.mode(_kLiveText, BlendMode.srcIn)
                ),
                SizedBox(width: 6.w),
                // Live Yazısı
                Text(
                  'Live',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 20.w,
                    fontWeight: FontWeight.w500, // Medium
                    letterSpacing: -0.3,
                    height: 1.0, // line-height: 100%
                    color: _kLiveText,
                  ),
                ),
              ],
            ),
          ),

          // Sağ: Boşluk Doldurucu (Simetri için)
          // Sol butona simetri sağlamak için aynı genişlikte boş bir widget
          SizedBox(width: 48.w), // IconButton'ın yaklaşık tıklama alanı
        ],
      ),
    );
  }
  // --- 2. Video Kartı ---
  Widget _buildVideoCard(BuildContext context) {
    // Figma boyutları: 339x619, margin (27, 27)
    const double cardRadius = 24.0;

    // Geçici olarak Figma boyutuna yakın sabit bir Container kullanıyoruz.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 27.w),
      child: Container(
        width: 339.w,
        // Gölgelendirme
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardRadius.w),
          boxShadow: [
            BoxShadow(
              color: const Color(0x40000000), // #00000040
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius.w),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arka Plan Görseli (Placeholder olarak beyaz/gri kullandık, gerçek görsel gelmeli)
              Image.asset(
                'assets/chars/char0.jpg', // Bu kısmı uygun bir asset ile değiştirin.
                fit: BoxFit.cover,
                // Resmin altındaki yeşil gradyanı simüle etmek için
                color: Colors.white.withValues(alpha: 0.9),
                colorBlendMode: BlendMode.dstATop,
              ),

              // Alttan Gelen Yeşil Gradyan
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(43, 211, 131, 0), // rgba(43, 211, 131, 0)
                        _kAppbarGreen, // #11998E
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. Kontrol Butonları ---
  Widget _buildControlButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Live/Video İkonu (Kamera/Video Görüşmesi)
          Expanded(
            child: _buildControlButton(
              iconPath: 'assets/svg/live_icon.svg',
              backgroundColor: Colors.white,
              iconColor: Colors.black,
              iconWidth: 24,
              onTap: () { /* TODO: Kamera/Video Aç/Kapa */ },
            ),
          ),

          SizedBox(width: 12,),
          // 2. Duraklatma İkonu
          Expanded(
            child: _buildControlButton(
              iconPath: 'assets/svg/pause_icon.svg',
              backgroundColor: Colors.white,
              iconColor: Colors.black,
              iconWidth: 12,
              onTap: () { /* TODO: Duraklat/Sürdür */ },
            ),
          ),
          SizedBox(width: 12,),

          // 3. Çıkış İkonu (Kırmızı)
          Expanded(
            child: _buildControlButton(
              iconPath: 'assets/svg/exit.svg',
              backgroundColor: _kRedExit,
              iconColor: Colors.white,
              iconWidth: 18,
              onTap: () {
                Navigator.pop(context); // Geri dönerek görüşmeden çıkış
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tekil Buton Widget'ı
  Widget _buildControlButton({
    required String iconPath,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
    required double iconWidth,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.w),
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: iconWidth,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

