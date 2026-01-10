import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/policies_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile_setup/legal_document/legal_doc_screen.dart';

/// OnboardingTermsText
/// ------------------------------------------------------------
/// TapGestureRecognizer kullanmadan, leak riski olmadan linkli metin.
/// - Terms
/// - Privacy
/// - Cookies
///
/// Not: localizedMD() core util'den geliyor.
/// Bu widget sadece navigation yapar.
class OnboardingTermsText extends StatelessWidget {
  const OnboardingTermsText({
    super.key,
    required this.fontSize,
    required this.isGerman,
  });

  final double fontSize;
  final bool isGerman;

  void _openDoc(BuildContext context, String assetKey, String title) {
    final path = localizedMD(assetKey, context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalDocScreen(assetPath: path, title: title),
      ),
    );
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
            onTap: () => _openDoc(context, "terms", l.onboardingTermsOfService),
            child: Text(l.onboardingTermsOfService, style: linkStyle),
          ),

          Text(l.onboardingTermsMiddle, style: baseStyle),

          GestureDetector(
            onTap: () => _openDoc(context, "privacy", l.onboardingPrivacyPolicy),
            child: Text(l.onboardingPrivacyPolicy, style: linkStyle),
          ),

          Text(l.onboardingTermsAnd, style: baseStyle),

          GestureDetector(
            onTap: () => _openDoc(context, "cookies", l.onboardingCookiesPolicy),
            child: Text(l.onboardingCookiesPolicy, style: linkStyle),
          ),

          Text(l.onboardingTermsSuffix, style: baseStyle),
        ],
      ),
    );
  }
}
