import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// OnboardingTermsText
/// ------------------------------------------------------------
/// StatefulWidget kullanılarak TapGestureRecognizer'lar dispose ediliyor.
/// Bu sayede LEAK RİSKİ SIFIRLANIR ve RichText kullanıldığı için
/// metinler blok blok atlamak yerine ekrana sığdığı kadar tek satırda kalır.
class OnboardingTermsText extends StatefulWidget {
  const OnboardingTermsText({
    super.key,
    required this.fontSize,
    required this.isGerman,
  });

  final double fontSize;
  final bool isGerman;

  @override
  State<OnboardingTermsText> createState() => _OnboardingTermsTextState();
}

class _OnboardingTermsTextState extends State<OnboardingTermsText> {
  // Tıklama algılayıcılarımızı tanımlıyoruz
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _cookiesRecognizer;

  @override
  void initState() {
    super.initState();
    // Recognizer'ları başlatıp tıklama olaylarını bağlıyoruz
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl('https://fly-work.com/mindcoach/terms/');

    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          _openUrl('https://fly-work.com/mindcoach/privacy-policy/');

    _cookiesRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl('https://fly-work.com/mindcoach/cookies/');
  }

  @override
  void dispose() {
    // SAYFA KAPANINCA LEAK OLMAMASI İÇİN TEMİZLİYORUZ (En önemli kısım)
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _cookiesRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    final baseStyle = GoogleFonts.poppins(
      fontSize: widget.fontSize,
      color: const Color(0xFF96989C),
      fontWeight: FontWeight.w400,
      height: widget.isGerman ? 1.2 : 1.3, // Sıkışık görünüm için
      letterSpacing: -0.3, // Sıkışık görünüm için
    );

    final linkStyle = baseStyle.copyWith(
      color: const Color.fromARGB(255, 55, 55, 55),
      decoration: TextDecoration.underline,
    );

    // RichText kelimeleri bölmez, metnin tek bir paragraf gibi akmasını sağlar.
    return RichText(
      textAlign: TextAlign.center, // Metni ortala
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: l.onboardingTermsPrefix),
          TextSpan(
            text: l.onboardingTermsOfService,
            style: linkStyle,
            recognizer: _termsRecognizer, // Tıklama eklendi
          ),
          TextSpan(text: l.onboardingTermsMiddle),
          TextSpan(
            text: l.onboardingPrivacyPolicy,
            style: linkStyle,
            recognizer: _privacyRecognizer, // Tıklama eklendi
          ),
          TextSpan(text: l.onboardingTermsAnd),
          TextSpan(
            text: l.onboardingCookiesPolicy,
            style: linkStyle,
            recognizer: _cookiesRecognizer, // Tıklama eklendi
          ),
          TextSpan(text: l.onboardingTermsSuffix),
        ],
      ),
    );
  }
}
