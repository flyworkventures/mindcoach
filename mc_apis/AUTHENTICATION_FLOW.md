# Authentication Flow - İki Aşamalı Kayıt Süreci

## Genel Bakış

MindCoach API, **iki aşamalı bir kayıt süreci** kullanır:

1. **İlk Oturum Açma**: Google/Facebook/Apple ile temel authentication
2. **Profil Tamamlama**: Kullanıcı soruları cevapladıktan sonra profil bilgileri tamamlanır

## Aşama 1: İlk Oturum Açma

### Ne Zaman?
Kullanıcı uygulamayı ilk kez açtığında ve "Google ile Giriş Yap" butonuna tıkladığında.

### Ne Gönderilir?
Sadece provider token'ı:
- Google: `idToken`
- Facebook: `accessToken`
- Apple: `identityToken` + `userIdentifier`

### Ne Kaydedilir?
Database'e sadece temel bilgiler kaydedilir:
- ✅ `credential` (google/facebook/apple)
- ✅ `credentialData` (providerId, email, id)
- ✅ `profilePhotoUrl` (varsa)
- ⚠️ `username` (geçici: `temp_google_user_id_123456_1234567890`)
- ❌ `answerData` (null - henüz yok)
- ❌ `nativeLang` (null)
- ❌ `gender` (unknown)

### Response
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "temp_google_user_id_123456_1234567890",
      "answerData": null,
      ...
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

## Aşama 2: Profil Tamamlama

### Ne Zaman?
Kullanıcı ilk oturum açtıktan sonra, uygulama içinde soruları cevapladıktan sonra.

### Ne Gönderilir?
JWT token + profil bilgileri:
```json
{
  "username": "my_username",
  "nativeLang": "tr",
  "gender": "male",
  "answerData": {
    "avaibleDays": ["monday", "tuesday"],
    "avaibleHours": ["09:00", "10:00"],
    "supportArea": "anxiety",
    "agentSpeakStyle": "supportive"
  }
}
```

### Ne Güncellenir?
- ✅ `username` (geçici username'den gerçek username'e)
- ✅ `answerData` (QuestionAnswers objesi)
- ✅ `nativeLang` (opsiyonel)
- ✅ `gender` (opsiyonel)

### Response
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "my_username",
      "answerData": {
        "avaibleDays": ["monday", "tuesday"],
        "avaibleHours": ["09:00", "10:00"],
        "supportArea": "anxiety",
        "agentSpeakStyle": "supportive"
      },
      ...
    }
  },
  "message": "Profile updated successfully"
}
```

## Akış Diyagramı

```
┌─────────────────┐
│  Kullanıcı      │
│  Uygulamayı     │
│  Açar           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  "Google ile    │
│  Giriş Yap"     │
│  Butonuna Tıklar│
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  POST /auth/google              │
│  { idToken: "..." }             │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Database'e Temel Bilgiler      │
│  Kaydedilir                      │
│  - credential                    │
│  - credentialData               │
│  - username (temp_)             │
│  - answerData (null)             │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  JWT Token Döner                │
│  Kullanıcı Authenticated        │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Uygulama İçinde Sorular        │
│  Gösterilir                     │
│  - Username seçimi              │
│  - Available days/hours        │
│  - Support area                 │
│  - Agent speak style            │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  PUT /auth/profile              │
│  Authorization: Bearer <token>  │
│  {                              │
│    username: "...",             │
│    answerData: {...}            │
│  }                              │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Profil Tamamlanır              │
│  Kullanıcı Sisteme Giriş Yapar  │
└─────────────────────────────────┘
```

## Endpoint'ler

### 1. İlk Oturum Açma
- `POST /auth/google` - Google ile giriş
- `POST /auth/facebook` - Facebook ile giriş
- `POST /auth/apple` - Apple ile giriş

**Response:** User object + JWT token

### 2. Profil Tamamlama
- `PUT /auth/profile` - Profil bilgilerini güncelle

**Headers:** `Authorization: Bearer <token>`

**Body:** 
```json
{
  "username": "required",
  "answerData": {
    "supportArea": "required",
    "agentSpeakStyle": "required",
    "avaibleDays": "optional",
    "avaibleHours": "optional"
  },
  "nativeLang": "optional",
  "gender": "optional"
}
```

## Flutter Örnek Kodu

```dart
// 1. Google ile oturum aç
final authResult = await signInWithGoogle(googleIdToken);
final token = authResult['token'];
final user = authResult['user'];

// Token'ı sakla
await saveToken(token);

// 2. Profil tamamlanmış mı kontrol et
bool isProfileComplete = user.username != null && 
                         !user.username.startsWith('temp_') &&
                         user.answerData != null;

if (!isProfileComplete) {
  // Profil tamamlama ekranına yönlendir
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ProfileCompletionScreen()),
  );
}

// 3. Profil tamamlama ekranında
final updatedUser = await completeProfile(
  token: token,
  username: usernameController.text,
  answerData: {
    'avaibleDays': selectedDays,
    'avaibleHours': selectedHours,
    'supportArea': selectedSupportArea,
    'agentSpeakStyle': selectedStyle,
  },
);
```

## Önemli Notlar

1. **İlk oturum açmada** sadece credential bilgileri kaydedilir
2. **Username** geçici olarak `temp_` ile başlar, profil tamamlandığında gerçek username set edilir
3. **answerData** ilk oturum açmada `null`'dur, profil tamamlandığında doldurulur
4. **JWT token** ilk oturum açmada döner, profil tamamlama için kullanılır
5. **Profil tamamlama** opsiyoneldir - kullanıcı isterse sonra da yapabilir
6. **Username unique** olmalıdır - eğer alınmışsa hata döner

## Validation Kuralları

### Username
- Minimum 3 karakter
- Sadece harf, rakam ve alt çizgi
- Unique olmalı

### answerData
- `supportArea`: String, required
- `agentSpeakStyle`: String, required
- `avaibleDays`: Any (array, string, object)
- `avaibleHours`: Any (array, string, object)

### gender
- "male", "female", veya "unknown"

### nativeLang
- String, max 10 karakter (örn: "tr", "en")

