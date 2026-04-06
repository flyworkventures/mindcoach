import 'package:flutter/material.dart';

import '../../../auth/domain/social_login_provider.dart';
import 'social_button.dart';
import '../../../../core/utils/screen_size_extensions.dart';
import '../../../../l10n/app_localizations.dart';

/// OnboardingSocialButtons
/// ------------------------------------------------------------
/// Platform'a göre buton kombinasyonunu gösterir.
/// - Android: üstte Google, altta Facebook + Apple
/// - iOS: üstte Apple, altta Facebook + Google
///
/// ⚠️ Login işlemi burada yapılmaz.
/// Dışarıdan `onLogin(provider)` callback'i ile tetiklenir.
class OnboardingSocialButtons extends StatelessWidget {
  const OnboardingSocialButtons({
    super.key,
    required this.isIOS,
    required this.isAndroid,
    required this.onLogin,
  });

  final bool isIOS;
  final bool isAndroid;
  final Future<void> Function(SocialLoginProvider provider) onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: 278.w,
            child: isAndroid
                ? SocialButton.google(onPressed: () => onLogin(SocialLoginProvider.google))
                : SocialButton.apple(onPressed: () => onLogin(SocialLoginProvider.apple)),
          ),
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /*
              SizedBox(
                width: 136.61.w,
                child: SocialButton.facebook(
                  onPressed: () => onLogin(SocialLoginProvider.facebook),
                ),
              ),

              */
              
              const SizedBox(width: 8),
              SizedBox(
                width: 278.w, //136.61
                child: isIOS
                    ? SocialButton.google(onPressed: () => onLogin(SocialLoginProvider.google))
                    : SocialButton.apple(onPressed: () => onLogin(SocialLoginProvider.apple)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Misafir girişi butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: 278.w,
            child: SocialButton.guest(
              onPressed: () => onLogin(SocialLoginProvider.guest),
              label: l10n.continueAsGuest,
            ),
          ),
        ),
      ],
    );
  }
}
