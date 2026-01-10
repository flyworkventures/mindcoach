# OneSignal Bildirim Sorun Giderme Rehberi

## Sorun: OneSignal Bildirimleri Gelmiyor

### 1. Flutter Tarafı Kontrolleri

#### OneSignal Initialize Edildi mi?

`lib/main.dart` dosyasında OneSignal initialize edilmeli:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // OneSignal initialize
  final notificationService = NotificationService();
  await notificationService.initiializeOnesignal();
  
  runApp(const ProviderScope(child: MyApp()));
}
```

**Kontrol:** Uygulama açıldığında console'da şu log görünmeli:
```
[ONESIGNAL] ✅ OneSignal initialized with App ID: b3ba2ab4-03a9-45dc-a303-f0a92d7d1410
[ONESIGNAL] Permission granted: true/false
```

#### Kullanıcı OneSignal'e Kayıtlı mı?

Kullanıcı login olduğunda `registerUser()` çağrılmalı:

```dart
await notificationService.registerUser(userId.toString());
```

**Kontrol:** Console'da şu log görünmeli:
```
[ONESIGNAL] ✅ User registered with External User ID: 123
[ONESIGNAL] OneSignal User ID: abc123-def456...
```

#### OneSignal App ID Doğru mu?

`lib/core/utils/app_constants.dart` dosyasında:
```dart
static const String onesignalId = "b3ba2ab4-03a9-45dc-a303-f0a92d7d1410";
```

Bu ID, OneSignal Dashboard'daki App ID ile eşleşmeli.

### 2. Backend Tarafı Kontrolleri

#### Environment Variables

`.env` dosyasında şunlar olmalı:
```env
ONESIGNAL_APP_ID=b3ba2ab4-03a9-45dc-a303-f0a92d7d1410
ONESIGNAL_REST_API_KEY=your_rest_api_key_here
```

**Kontrol:** Server loglarında şu hata görünmemeli:
```
❌ OneSignal configuration is missing. Please check ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY environment variables.
```

#### OneSignal REST API Key

OneSignal Dashboard'dan REST API Key alınmalı:
1. OneSignal Dashboard'a giriş yapın
2. **Settings > Keys & IDs** bölümüne gidin
3. **REST API Key**'i kopyalayın
4. `.env` dosyasına ekleyin

#### External User ID

Backend'de bildirim gönderilirken `include_external_user_ids` kullanılıyor:
```javascript
include_external_user_ids: userIdArray.map(id => id.toString())
```

**Önemli:** Kullanıcının Flutter uygulamasında `OneSignal.login(userId)` ile kayıtlı olması gerekiyor.

### 3. Test Adımları

#### Adım 1: OneSignal Initialize Kontrolü

Uygulamayı açın ve console loglarını kontrol edin:
```bash
# Flutter console'da şunları görmelisiniz:
[ONESIGNAL] ✅ OneSignal initialized with App ID: ...
[ONESIGNAL] Permission granted: true
```

#### Adım 2: Kullanıcı Kayıt Kontrolü

Login olduktan sonra:
```bash
[ONESIGNAL] ✅ User registered with External User ID: 123
[ONESIGNAL] OneSignal User ID: abc123...
```

#### Adım 3: Backend Bildirim Gönderme Testi

Backend'den test bildirimi gönderin:
```bash
curl -X POST http://localhost:3014/notifications/send \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userIds": 123,
    "title": "Test Bildirimi",
    "subtitle": "Bu bir test bildirimidir",
    "type": "system_notification"
  }'
```

**Backend loglarında şunu görmelisiniz:**
```
✅ OneSignal notification sent successfully. Recipients: 1, OneSignal ID: abc123...
```

#### Adım 4: OneSignal Dashboard Kontrolü

1. OneSignal Dashboard'a giriş yapın
2. **Delivery** sekmesine gidin
3. Son gönderilen bildirimleri kontrol edin
4. Bildirim durumunu kontrol edin (Delivered, Failed, etc.)

### 4. Yaygın Sorunlar ve Çözümleri

#### Sorun 1: "OneSignal configuration is missing"

**Çözüm:**
- `.env` dosyasında `ONESIGNAL_APP_ID` ve `ONESIGNAL_REST_API_KEY` olduğundan emin olun
- Server'ı yeniden başlatın: `pm2 restart all`

#### Sorun 2: "No players found with external_user_ids"

**Çözüm:**
- Kullanıcının Flutter uygulamasında `OneSignal.login(userId)` ile kayıtlı olduğundan emin olun
- OneSignal Dashboard'da **Audience > Users** bölümünden kullanıcının kayıtlı olup olmadığını kontrol edin
- External User ID'nin doğru olduğundan emin olun (string olarak gönderilmeli)

#### Sorun 3: Bildirimler geliyor ama görünmüyor

**Çözüm:**
- iOS: Bildirim izinleri verilmiş mi kontrol edin
- Android: Bildirim kanalları oluşturulmuş mu kontrol edin
- Uygulama foreground'dayken bildirim gösterilmiyor olabilir (OneSignal ayarlarından kontrol edin)

#### Sorun 4: Permission denied

**Çözüm:**
- iOS: Ayarlar > Uygulama > Bildirimler'den izin verin
- Android: Uygulama ayarlarından bildirim izinlerini kontrol edin
- `OneSignal.Notifications.requestPermission(true)` ile tekrar izin isteyin

### 5. Debug Modu

OneSignal debug modunu açın:
```dart
OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
```

Bu, tüm OneSignal işlemlerini detaylı loglar.

### 6. OneSignal Dashboard Test

OneSignal Dashboard'dan direkt test bildirimi gönderebilirsiniz:

1. OneSignal Dashboard'a giriş yapın
2. **Messages > New Push** tıklayın
3. **Send to Specific Users** seçin
4. **External User ID** olarak kullanıcı ID'sini girin (örn: "123")
5. Bildirim gönderin

Bu, backend'den bağımsız olarak OneSignal'in çalışıp çalışmadığını test eder.

### 7. Kontrol Listesi

- [ ] OneSignal App ID doğru mu?
- [ ] OneSignal REST API Key doğru mu?
- [ ] `.env` dosyasında değişkenler var mı?
- [ ] Server yeniden başlatıldı mı?
- [ ] Flutter uygulamasında OneSignal initialize edildi mi?
- [ ] Kullanıcı OneSignal'e kayıtlı mı? (`OneSignal.login()`)
- [ ] Bildirim izinleri verilmiş mi?
- [ ] Backend'den bildirim gönderilirken hata var mı?
- [ ] OneSignal Dashboard'da bildirim görünüyor mu?

### 8. Log Kontrolü

**Backend Logları:**
```bash
# PM2 loglarını kontrol edin
pm2 logs

# Veya direkt server loglarını
tail -f /path/to/server/logs
```

**Flutter Logları:**
```bash
# Flutter console'da OneSignal loglarını kontrol edin
flutter run --verbose
```

### 9. OneSignal API Response Kontrolü

Backend'de OneSignal API'den dönen response'u kontrol edin:

```javascript
// mc_apis/services/oneSignalService.js içinde
console.log('OneSignal response:', JSON.stringify(response.data, null, 2));
```

Response'da şunlar olmalı:
- `id`: OneSignal notification ID
- `recipients`: Bildirim gönderilen kullanıcı sayısı
- `errors`: Hata varsa burada görünür

### 10. Son Kontrol

Eğer hala çalışmıyorsa:

1. **OneSignal Dashboard'da test bildirimi gönderin** (External User ID ile)
2. **Backend loglarını kontrol edin** (OneSignal API response)
3. **Flutter console loglarını kontrol edin** (OneSignal initialize ve user registration)
4. **Cihaz bildirim ayarlarını kontrol edin** (iOS/Android)

