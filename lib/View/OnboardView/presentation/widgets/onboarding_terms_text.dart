import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

/// OnboardingTermsText
/// ------------------------------------------------------------
/// TapGestureRecognizer kullanmadan, leak riski olmadan linkli metin.
/// - Terms (Web URL)
/// - Privacy (Web URL)
/// - Cookies (Web URL)
///
/// Tüm linkler web URL'lerini tarayıcıda açar.
class OnboardingTermsText extends StatelessWidget {
  const OnboardingTermsText({
    super.key,
    required this.fontSize,
    required this.isGerman,
  });

  final double fontSize;
  final bool isGerman;

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
      fontSize: fontSize,
      color: const Color(0xFF1D1D1D),
      fontWeight: FontWeight.w400,
      height: isGerman ? 1.3 : 1.5,
    );

    final linkStyle = GoogleFonts.poppins(
      fontSize: fontSize,
      color: const Color(0xFF1D1D1D),
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
    );

    return SizedBox(
      width: 320,
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(l.onboardingTermsPrefix, style: baseStyle),

          GestureDetector(
            onTap: () => _openUrl('https://fly-work.com/mindcoach/terms/'),
            child: Text(l.onboardingTermsOfService, style: linkStyle),
          ),

          Text(l.onboardingTermsMiddle, style: baseStyle),

          GestureDetector(
            onTap: () => _openUrl('https://fly-work.com/mindcoach/privacy-policy/'),
            child: Text(l.onboardingPrivacyPolicy, style: linkStyle),
          ),

          Text(l.onboardingTermsAnd, style: baseStyle),

          GestureDetector(
            onTap: () => _openUrl('https://fly-work.com/mindcoach/cookies/'),
            child: Text(l.onboardingCookiesPolicy, style: linkStyle),
          ),

          Text(l.onboardingTermsSuffix, style: baseStyle),
        ],
      ),
    );
  }
}
