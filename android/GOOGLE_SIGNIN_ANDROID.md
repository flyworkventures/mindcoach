# Android Google Sign-In kurulumu

iOS çalışıp Android çalışmıyorsa neredeyse her zaman **imza SHA-1** ile **Firebase / google-services.json** uyumsuzluğudur.

## 1. Bu cihazda hangi SHA kullanılıyor?

Proje kökünden:

```bash
cd android && ./gradlew :app:signingReport
```

`Variant: debug` ve `Variant: release` altındaki **SHA-1** ve **SHA-256** değerlerini kopyala.

Debug keystore (varsayılan):

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
```

## 2. Firebase’e SHA ekle

[Firebase Console](https://console.firebase.google.com/project/mindcoach-748a6/settings/general) → **mindcoach** → Project settings → Android app `com.flywork.mindcoach` → **Add fingerprint**.

Şu an kayıtlı örnekler:

| SHA-1 | Durum |
|--------|--------|
| `58:4B:19:66:...` | Debug (çoğu Mac) — `google-services.json` içinde var |
| `79:7E:06:14:...` | Release — `google-services.json` içinde var |
| `5D:9A:2B:CC:...` | Yeni eklenen — **json’da yoksa giriş çalışmaz** |

**Play Store** kullanıyorsan: Play Console → Setup → App integrity → **App signing key certificate** SHA-1’ini de Firebase’e ekle.

## 3. google-services.json yeniden indir (zorunlu)

SHA ekledikten sonra:

1. Firebase → Android app → **google-services.json** indir
2. `android/app/google-services.json` dosyasının üzerine yaz
3. `oauth_client` içinde **her SHA için** bir `client_type: 1` satırı olmalı

Şu anki dosyada yalnızca 2 Android client var; Firebase’de 3 SHA-1 görünüyorsa json **güncel değil**.

Üçüncü client eklendikten sonra `AndroidManifest.xml` içine o client’ın reversed scheme’ini de ekle:

```xml
<data android:scheme="com.googleusercontent.apps.705277804468-XXXX"/>
```

(`XXXX` = yeni client id’nin `705277804468-` sonrası kısmı, noktasız.)

## 4. Google Cloud ile çift client

Google Cloud’da elle **Android client 2** (`5D:9A:2B:CC...`) oluşturmuş olabilirsin. Uygulama asıl olarak **Firebase’den indirilen** `google-services.json` kullanır. Elle client açmak yerine SHA’yı Firebase’e ekle + json indir yeterli.

**Web client** (server / id token): `705277804468-b3a82f9k2c3moht7m388lf7mkgu5oo9u` — `client_type: 3` json’da mevcut olmalı.

## 5. Firebase Authentication

Authentication → Sign-in method → **Google** → Enabled.

## 6. Temiz build

```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter run
```

SHA değişikliğinden sonra **10–15 dakika** bekle.

## 7. Paket adı

`applicationId` = `com.flywork.mindcoach` (Firebase ile aynı olmalı).

## Sık hatalar

| Belirti | Sebep |
|--------|--------|
| `DEVELOPER_ERROR` / Error 10 | Yanlış veya eksik SHA |
| Hemen “iptal” / Error 16 | Çoğunlukla yanlış OAuth yapılandırması (Credential Manager “canceled” gibi döner) |
| Debug çalışır, release çalışmaz | Release SHA veya release intent-filter eksik |
| Başka PC’de çalışmaz | O makinenin debug SHA’sı Firebase’de yok |

Kod: `lib/core/repo/auth_repository.dart` — Android’de `serverClientId` = Web client (`b3a82f9k...`).

Güncel Android OAuth client’lar (json `client_type: 1`):

| SHA-1 (kısa) | Client suffix |
|--------------|----------------|
| `58:4B:19:66…` (debug) | `dr9uncu85f72h4crufv38cpk5pr4n660` |
| `79:7E:06:14…` (release) | `4fctl8jn0t0f7i5g2sfaql2ldtdssmss` |
| `5D:9A:2B:CC…` | `9i3qsghcfocevhbm98vmq9oq0r9a44ol` |
