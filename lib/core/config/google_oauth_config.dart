/// Google Sign-In kimlikleri — `android/app/google-services.json` ile senkron tutun.
///
/// Play Store kullanıcıları **Uygulama imzalama anahtarı** (App signing key) ile imzalanır;
/// Firebase'de bu SHA-1 için `client_type: 1` oauth_client satırı zorunludur.
class GoogleOAuthConfig {
  GoogleOAuthConfig._();

  /// Web client (`client_type: 3`) — Android'de idToken için [serverClientId].
  static const String webClientId =
      '705277804468-b3a82f9k2c3moht7m388lf7mkgu5oo9u.apps.googleusercontent.com';

  /// SHA-1 `5D:9A:2B:CC:...` — Play Console → Uygulama imzalama anahtarı.
  static const String playStoreAndroidClientId =
      '705277804468-9i3qsghcfocevhbm98vmq9oq0r9a44ol.apps.googleusercontent.com';

  /// SHA-1 `79:7E:06:14:...` — Yükleme anahtarı (yerel release AAB).
  static const String uploadKeyAndroidClientId =
      '705277804468-4fctl8jn0t0f7i5g2sfaql2ldtdssmss.apps.googleusercontent.com';

  /// SHA-1 `58:4B:19:66:...` — Debug keystore.
  static const String debugAndroidClientId =
      '705277804468-dr9uncu85f72h4crufv38cpk5pr4n660.apps.googleusercontent.com';

  static const String packageName = 'com.flywork.mindcoach';

  /// Play Console → Uygulama imzalama anahtarı SHA-1 (Firebase'e eklenmeli).
  static const String playAppSigningSha1 =
      '5D:9A:2B:CC:12:F4:46:D0:E6:61:E4:A8:75:8D:39:58:E8:4A:01:A9';
}
