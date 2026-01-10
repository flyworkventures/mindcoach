# JWT Secret Key Rehberi

## JWT_SECRET Nedir?

`JWT_SECRET`, JWT (JSON Web Token) token'larınızı imzalamak ve doğrulamak için kullanılan gizli bir anahtardır. Bu key, token'ların güvenliğini sağlar ve sadece sizde olmalıdır.

## Secret Key Nasıl Oluşturulur?

### Yöntem 1: Otomatik Script (Önerilen)

Projede hazır bir script var:

```bash
npm run generate-secret
```

Bu komut güvenli bir 256-bit random key oluşturur ve size gösterir. Çıktı şöyle olacak:

```
✅ JWT Secret Key oluşturuldu!

Aşağıdaki key'i .env dosyanıza ekleyin:

JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6...

⚠️  ÖNEMLİ: Bu key'i güvenli bir yerde saklayın ve asla public repository'lere commit etmeyin!
```

### Yöntem 2: Node.js ile Manuel

Terminal'de şu komutu çalıştırın:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Yöntem 3: OpenSSL ile

```bash
openssl rand -hex 32
```

### Yöntem 4: Online Generator (Dikkatli kullanın!)

Güvenlik açısından önerilmez, ama acil durumlarda kullanılabilir:
- https://randomkeygen.com/
- https://www.allkeysgenerator.com/Random/Security-Encryption-Key-Generator.aspx

## Secret Key'i .env Dosyasına Eklemek

1. Proje root'unda `.env` dosyası oluşturun (yoksa)

2. Oluşturduğunuz key'i ekleyin:

```env
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
```

3. Server'ı yeniden başlatın:

```bash
npm start
```

## Güvenlik Önerileri

### ✅ Yapılması Gerekenler

1. **Güçlü Key Kullanın**
   - En az 32 karakter (256 bit)
   - Random ve tahmin edilemez olmalı

2. **Güvenli Saklama**
   - `.env` dosyasında saklayın
   - `.env` dosyasını `.gitignore`'a ekleyin
   - Production'da environment variables olarak ayarlayın

3. **Farklı Ortamlar İçin Farklı Key'ler**
   - Development için bir key
   - Production için farklı bir key
   - Test için farklı bir key

4. **Düzenli Değiştirme**
   - Güvenlik ihlali şüphesi varsa değiştirin
   - Yılda bir kez değiştirmeyi düşünün

### ❌ Yapılmaması Gerekenler

1. **Asla Commit Etmeyin**
   - `.env` dosyasını git'e commit etmeyin
   - Secret key'leri kod içine yazmayın
   - Public repository'lere yüklemeyin

2. **Zayıf Key Kullanmayın**
   - "secret", "password", "123456" gibi key'ler kullanmayın
   - Kısa key'ler kullanmayın
   - Tahmin edilebilir key'ler kullanmayın

3. **Paylaşmayın**
   - Key'leri email, chat, vs. ile paylaşmayın
   - Sadece güvenilir ekip üyeleriyle paylaşın

## .gitignore Kontrolü

`.env` dosyanızın git'e commit edilmediğinden emin olun. `.gitignore` dosyanızda şu satır olmalı:

```
.env
.env.local
.env.*.local
```

## Production Ortamında

Production'da (örneğin Heroku, AWS, DigitalOcean):

1. **Environment Variables Olarak Ayarlayın**
   - Platform'un environment variables ayarlarından ekleyin
   - `.env` dosyası kullanmayın

2. **Örnek (Heroku):**
   ```bash
   heroku config:set JWT_SECRET=your_production_secret_key
   ```

3. **Örnek (AWS/DigitalOcean):**
   - Platform'un dashboard'undan environment variables ekleyin

## Key Değiştirme

Eğer key'inizi değiştirmeniz gerekiyorsa:

1. Yeni bir key oluşturun: `npm run generate-secret`
2. `.env` dosyasındaki `JWT_SECRET` değerini güncelleyin
3. **ÖNEMLİ:** Eski key ile oluşturulmuş tüm token'lar geçersiz olacak
4. Tüm kullanıcılar yeniden login olmak zorunda kalacak

## Sorun Giderme

### "JWT_SECRET is not defined" Hatası

**Çözüm:**
1. `.env` dosyasının proje root'unda olduğundan emin olun
2. `JWT_SECRET` değişkeninin doğru yazıldığından emin olun
3. Server'ı yeniden başlatın

### Token Doğrulama Hatası

**Çözüm:**
1. `JWT_SECRET` değerinin doğru olduğundan emin olun
2. Token'ın aynı secret ile oluşturulduğundan emin olun
3. Environment variable'ın yüklendiğinden emin olun

## Örnek .env Dosyası

```env
# Server
PORT=3000

# Database
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=mindcoach

# JWT (npm run generate-secret ile oluşturun)
JWT_SECRET=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
JWT_EXPIRES_IN=7d
JWT_ISSUER=mindcoach-api
JWT_AUDIENCE=mindcoach-app
```

## Özet

1. **Oluştur:** `npm run generate-secret`
2. **Kopyala:** Çıktıdaki key'i kopyala
3. **Yapıştır:** `.env` dosyasına `JWT_SECRET=...` olarak ekle
4. **Kontrol Et:** `.env` dosyasının `.gitignore`'da olduğundan emin ol
5. **Başlat:** Server'ı yeniden başlat

Bu kadar! 🎉

