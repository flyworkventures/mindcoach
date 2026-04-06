# Error 28444: "Developer console is not set up correctly" Çözümü

## 🔴 Hata
```
GoogleSignInException(code GoogleSignInExceptionCode.unknownError, [28444] Developer console is not set up correctly., null)
```

## ✅ Bu Hatanın Nedenleri

Error 28444 genellikle Google Cloud Console'da OAuth yapılandırmasında eksik veya yanlış ayarlar olduğunu gösterir.

## 📋 Adım Adım Çözüm

### 1. Google Cloud Console'da OAuth Client ID Kontrolü

1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials) sayfasına gidin
2. Projenizi seçin
3. **APIs & Services** > **Credentials** bölümüne gidin
4. **OAuth 2.0 Client IDs** listesinde Android client ID'nizi bulun:
   - **Client ID:** `931696780726-9bg4g80lakc05sf5do9a3r3pdru90sj6.apps.googleusercontent.com`
   - Eğer bu Client ID yoksa, **yeni bir Android OAuth Client ID oluşturun**

### 2. OAuth Client ID Ayarlarını Kontrol Edin

**Edit** (Düzenle) butonuna tıklayın ve şunları kontrol edin:

#### ✅ Package Name
- **Olması gereken:** `com.flywork.mindcoach`
- **TAM OLARAK** bu şekilde olmalı (büyük/küçük harf duyarlı)
- Boşluk veya ekstra karakter olmamalı

#### ✅ SHA-1 Certificate Fingerprints
**Her iki SHA-1'i de ekleyin:**
```
C7:A6:48:26:D6:91:7C:31:B6:3E:0E:A9:3D:0A:44:90:EE:9A:5F:FA  (Debug)
79:7E:06:14:86:C9:64:89:87:5F:29:1E:25:81:4A:04:F6:50:70:2A  (Release)
```

#### ✅ SHA-256 Certificate Fingerprints
**Her iki SHA-256'ı da ekleyin:**
```
2C:A9:D3:C7:E1:47:E3:D8:88:E3:FC:70:8B:79:71:10:97:FE:EE:18:F3:FC:84:8B:CC:DE:BC:B4:7F:EB:6F:C0  (Debug)
51:A4:50:FE:A0:AB:58:DA:E5:E8:15:B6:E4:79:09:1A:D2:E5:BF:44:FA:3D:28:8F:8A:8D:46:C4:F5:50:BC:D5  (Release)
```

### 3. OAuth Consent Screen Yapılandırması

1. Google Cloud Console'da **APIs & Services** > **OAuth consent screen** bölümüne gidin
2. **User Type** seçin (Internal veya External)
3. **App information** bölümünü doldurun:
   - App name
   - User support email
   - Developer contact information
4. **Scopes** bölümünde gerekli scope'ları ekleyin (email, profile)
5. **Test users** ekleyin (eğer External ve Testing modundaysa)
6. **Save and Continue** butonlarına tıklayın

### 4. Google Sign-In API'sinin Aktif Olduğundan Emin Olun

1. Google Cloud Console'da **APIs & Services** > **Library** bölümüne gidin
2. "Google Sign-In API" veya "Google+ API" arayın
3. API'nin **ENABLED** olduğundan emin olun
4. Eğer değilse, **ENABLE** butonuna tıklayın

### 5. Değişikliklerin Etkili Olması

- **10-15 dakika bekleyin** (Google Cloud Console değişikliklerinin propagate olması için)
- Uygulamayı **tamamen kapatıp yeniden açın**
- Cihazı **yeniden başlatın** (gerekirse)
- Projeyi **temizleyip yeniden derleyin:**
  ```bash
  flutter clean
  cd android && ./gradlew clean && cd ..
  flutter pub get
  flutter run
  ```

## ✅ Kontrol Listesi

- [ ] Google Cloud Console'da OAuth Client ID var: `931696780726-9bg4g80lakc05sf5do9a3r3pdru90sj6`
- [ ] Package name: `com.flywork.mindcoach` (TAM OLARAK)
- [ ] Debug SHA-1 eklendi
- [ ] Debug SHA-256 eklendi
- [ ] Release SHA-1 eklendi
- [ ] Release SHA-256 eklendi
- [ ] OAuth consent screen yapılandırıldı
- [ ] Google Sign-In API aktif
- [ ] 10-15 dakika bekledim
- [ ] Uygulamayı yeniden başlattım
- [ ] Projeyi temizleyip yeniden derledim

## 🔍 Hala Çalışmıyorsa

1. **OAuth Client ID'nin doğru olduğundan emin olun:**
   - `auth_repository.dart` dosyasındaki Client ID ile Google Cloud Console'daki eşleşmeli

2. **Yeni bir OAuth Client ID oluşturmayı deneyin:**
   - Bazen eski Client ID'ler sorunlu olabilir
   - Yeni bir Android OAuth Client ID oluşturup, `auth_repository.dart` dosyasındaki Client ID'yi güncelleyin

3. **Firebase Console'u kontrol edin (eğer kullanıyorsanız):**
   - Firebase Console > Project Settings > Your Apps
   - Android app'in SHA key'leri eklenmiş mi?

4. **Logları kontrol edin:**
   ```bash
   flutter run --verbose 2>&1 | grep -i "google\|oauth\|client"
   ```

## 📞 Yardım

Sorun devam ederse:
- Google Cloud Console Support
- Flutter Google Sign-In GitHub Issues: https://github.com/flutter/plugins/tree/main/packages/google_sign_in


server {
    server_name hermes.fly-work.com;

    location / {
        proxy_pass http://localhost:3017;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/hermes.fly-work.com/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/hermes.fly-work.com/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

}

server {
    if ($host = hermes.fly-work.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot


    listen 80;
    server_name hermes.fly-work.com;
    return 404; # managed by Certbot


}




