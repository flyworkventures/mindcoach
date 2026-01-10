# MindCoach API Dokümantasyonu

## Genel Bakış

MindCoach API, mobil uygulama için authentication servisleri sağlar. Google, Facebook ve Apple ile OAuth authentication destekler.

**Base URL:** `http://localhost:3000`

---

## Authentication Endpoints

### 1. Google Authentication (İlk Oturum Açma)

Google ile kullanıcı girişi yapar. **İlk oturum açmada sadece temel bilgiler (credential, credentialData, profilePhotoUrl) database'e kaydedilir.** Username, answerData ve diğer bilgiler sonradan profil tamamlama ile eklenir.

**Endpoint:** `POST /auth/google`

**Request Body:**
```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij..."
}
```

**Response (Success - 200) - Yeni Kullanıcı:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "credential": "google",
      "credentialData": {
        "providerId": "google",
        "email": "user@example.com",
        "id": "google_user_id_123456"
      },
      "username": "temp_google_user_id_123456_1234567890",
      "nativeLang": null,
      "gender": "unknown",
      "answerData": null,
      "lastPsychologicalProfile": null,
      "userAgentNotes": null,
      "leastSessions": null,
      "psychologicalProfileBasedOnMessages": null,
      "accountCreatedDate": "2024-01-01T00:00:00.000Z",
      "generalProfile": null,
      "generalPsychologicalProfile": null,
      "profilePhotoUrl": "https://example.com/photo.jpg"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "New user created and authenticated successfully"
}
```

**Not:** İlk oturum açmada `username` geçici bir değer olarak oluşturulur (`temp_` ile başlar). Kullanıcı profil tamamlama yaptığında gerçek username set edilir.

**Response (Success - 200) - Mevcut Kullanıcı:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "credential": "google",
      "credentialData": {
        "providerId": "google",
        "email": "user@example.com",
        "id": "google_user_id_123456"
      },
      "username": "my_username",
      "nativeLang": "tr",
      "gender": "male",
      "answerData": {
        "avaibleDays": ["monday", "tuesday"],
        "avaibleHours": ["09:00", "10:00"],
        "supportArea": "anxiety",
        "agentSpeakStyle": "supportive"
      },
      ...
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "User authenticated successfully"
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "error": "idToken is required for Google authentication"
}
```

---

### 2. Facebook Authentication

Facebook ile kullanıcı girişi yapar.

**Endpoint:** `POST /auth/facebook`

**Request Body:**
```json
{
  "accessToken": "EAABwzLix..."
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "credential": "facebook",
      "credentialData": {
        "providerId": "facebook",
        "email": "user@example.com",
        "id": "facebook_user_id"
      },
      "username": "User Name",
      "nativeLang": null,
      "gender": "unknown",
      "answerData": null,
      "lastPsychologicalProfile": null,
      "userAgentNotes": null,
      "leastSessions": null,
      "psychologicalProfileBasedOnMessages": null,
      "accountCreatedDate": "2024-01-01T00:00:00.000Z",
      "generalProfile": null,
      "generalPsychologicalProfile": null,
      "profilePhotoUrl": "https://example.com/photo.jpg"
    }
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "error": "accessToken is required for Facebook authentication"
}
```

---

### 3. Apple Authentication

Apple ile kullanıcı girişi yapar.

**Endpoint:** `POST /auth/apple`

**Request Body:**
```json
{
  "identityToken": "eyJraWQiOiJlWGF1...",
  "userIdentifier": "001234.567890abcdef.1234",
  "authorizationCode": "c1234567890abcdef..." // optional
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "credential": "apple",
      "credentialData": {
        "providerId": "apple",
        "email": "user@example.com",
        "id": "apple_user_id"
      },
      "username": "user",
      "nativeLang": null,
      "gender": "unknown",
      "answerData": null,
      "lastPsychologicalProfile": null,
      "userAgentNotes": null,
      "leastSessions": null,
      "psychologicalProfileBasedOnMessages": null,
      "accountCreatedDate": "2024-01-01T00:00:00.000Z",
      "generalProfile": null,
      "generalPsychologicalProfile": null,
      "profilePhotoUrl": null
    }
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "error": "identityToken or userIdentifier is required for Apple authentication"
}
```

---

### 4. Profile Completion (Profil Tamamlama)

Kullanıcı ilk oturum açtıktan sonra, uygulama içinde soruları cevaplayıp profil bilgilerini tamamlar. Bu endpoint ile username, answerData ve diğer bilgiler güncellenir.

**Endpoint:** `PUT /auth/profile`

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "username": "my_username",
  "nativeLang": "tr",
  "gender": "male",
  "answerData": {
    "avaibleDays": ["monday", "tuesday", "wednesday"],
    "avaibleHours": ["09:00", "10:00", "14:00"],
    "supportArea": "anxiety",
    "agentSpeakStyle": "supportive"
  }
}
```

**Field Açıklamaları:**
- `username` (required): Kullanıcı adı (min 3 karakter, sadece harf, rakam ve alt çizgi)
- `nativeLang` (optional): Ana dil kodu (örn: "tr", "en")
- `gender` (optional): Cinsiyet - "male", "female", "unknown"
- `answerData` (optional): QuestionAnswers objesi
  - `avaibleDays`: Müsait günler (array, string veya object olabilir)
  - `avaibleHours`: Müsait saatler (array, string veya object olabilir)
  - `supportArea`: Destek alanı (string, required)
  - `agentSpeakStyle`: Yaklaşım tarzı (string, required)

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "credential": "google",
      "credentialData": {
        "providerId": "google",
        "email": "user@example.com",
        "id": "google_user_id_123456"
      },
      "username": "my_username",
      "nativeLang": "tr",
      "gender": "male",
      "answerData": {
        "avaibleDays": ["monday", "tuesday", "wednesday"],
        "avaibleHours": ["09:00", "10:00", "14:00"],
        "supportArea": "anxiety",
        "agentSpeakStyle": "supportive"
      },
      "profilePhotoUrl": "https://example.com/photo.jpg",
      "accountCreatedDate": "2024-01-01T00:00:00.000Z",
      ...
    }
  },
  "message": "Profile updated successfully"
}
```

**Not:** Username kontrolü yapılmaz. Aynı username birden fazla kullanıcı tarafından kullanılabilir.

**Response (Error - 400) - Validation Error:**
```json
{
  "success": false,
  "error": "Validation failed",
  "errors": [
    "Username must be at least 3 characters long",
    "answerData.supportArea must be a string"
  ]
}
```

**Not:** Tüm field'lar optional'dır, sadece göndermek istediğiniz field'ları gönderebilirsiniz. Örneğin sadece username güncellemek için:
```json
{
  "username": "new_username"
}
```

---

### 5. Token Verification

JWT token'ı verify eder (henüz implement edilmedi).

**Endpoint:** `GET /auth/verify`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Token verification endpoint - to be implemented"
}
```

---

## Stream Call Endpoints

### 1. Stream Call Audio Upload

Ses kaydını yükler, CDN'e yükler ve webhook'a gönderir. Webhook URL'si `/stream-call` endpoint'idir.

**Endpoint:** `POST /stream-call`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Request Body (multipart/form-data):**
- `consultantId` (required): Consultant ID (number)
- `audio` (required): Audio file (File)

**Desteklenen Audio Formatları:**
- `audio/mpeg` (MP3)
- `audio/mp3`
- `audio/wav`
- `audio/ogg`
- `audio/m4a`
- `audio/aac`
- `audio/x-m4a`

**İşlem Akışı:**
1. Audio dosyası CDN'e (Bunny CDN) yüklenir
2. Chat oluşturulur veya mevcut chat bulunur
3. Kullanıcı bilgileri ve chat geçmişi hazırlanır
4. Webhook'a gönderilir (URL: `/stream-call`)
5. Webhook response'undan transcription ve audio content alınır
6. Mesaj database'e kaydedilir
7. Response döndürülür

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "audioURL": "https://mindcoach.b-cdn.net/stream-calls/1/1234567890_audio.m4a",
    "chatId": 1,
    "message": "Audio uploaded and sent to webhook successfully",
    "transcription": "Kullanıcının ses kaydından çıkarılan metin...",
    "audioContent": "Ek audio içeriği (varsa)",
    "webhookResponse": {
      "transcription": "...",
      "audioContent": "..."
    }
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "error": "consultantId is required and must be a number"
}
```

**Response (Error - 400 - Invalid File Type):**
```json
{
  "success": false,
  "error": "Invalid audio file type. Allowed types: audio/mpeg, audio/mp3, audio/wav, audio/ogg, audio/m4a, audio/aac, audio/x-m4a"
}
```

**Webhook Request Format:**
Webhook'a gönderilen data formatı:
```json
{
  "id": 1,
  "chatId": 1,
  "nativeLang": "tr",
  "message": "[Stream Call Audio]",
  "messageType": "voice",
  "voiceURL": "https://mindcoach.b-cdn.net/stream-calls/1/1234567890_audio.m4a",
  "userInfo": {
    "username": "kullanici_adi",
    "phycoProfile": "genel_profil",
    "chatHistory": [
      {
        "sender": "user",
        "message": "Önceki mesaj",
        "sentTime": "01/01/2024",
        "messageType": "text"
      }
    ],
    "aiComments": []
  }
}
```

**Webhook Response Format (Beklenen):**
Webhook'tan dönen response formatı:
```json
{
  "transcription": "Kullanıcının ses kaydından çıkarılan metin...",
  "audioContent": "Ek audio içeriği (opsiyonel)",
  "response": "AI yanıtı (opsiyonel)"
}
```

**Notlar:**
- Audio dosyası otomatik olarak Bunny CDN'e yüklenir
- Webhook URL'i environment variable'dan alınır (`WEBHOOK_BASE_URL`)
- Webhook hatası olsa bile audio yüklendiği için response döndürülür
- Transcription webhook response'undan alınır (eğer varsa)
- Mesaj database'e kaydedilir (chat history için)

---

## Health Check

**Endpoint:** `GET /health`

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

---

## Error Responses

Tüm hatalar aşağıdaki formatta döner:

```json
{
  "success": false,
  "error": "Error message here"
}
```

**HTTP Status Codes:**
- `200` - Success
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (authentication errors)
- `500` - Internal Server Error

---

## User Model

API'den dönen kullanıcı objesi Flutter'daki `UserModel` ile uyumludur:

```typescript
{
  id: number;
  credential: "google" | "facebook" | "apple";
  credentialData: {
    providerId: string;
    email: string;
    id: string;
  };
  username: string;
  nativeLang: string | null;
  gender: "male" | "female" | "unknown";
  answerData: {
    avaibleDays: any;
    avaibleHours: any;
    supportArea: string;
    agentSpeakStyle: string;
  } | null;
  lastPsychologicalProfile: string | null;
  userAgentNotes: any[] | null;
  leastSessions: any[] | null;
  psychologicalProfileBasedOnMessages: string | null;
  accountCreatedDate: string; // ISO 8601 format
  generalProfile: string | null;
  generalPsychologicalProfile: string | null;
  profilePhotoUrl: string | null;
}
```

---

## Kurulum ve Çalıştırma

### Gereksinimler
- Node.js (v14 veya üzeri)
- npm veya yarn

### Kurulum

```bash
# Dependencies'leri yükle
npm install
```

### Environment Variables

`.env` dosyası oluşturun ve aşağıdaki değişkenleri ekleyin:

```env
PORT=3000
JWT_SECRET=your_jwt_secret_key_here

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id

# Facebook App
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret

# Apple
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
APPLE_CLIENT_ID=your_apple_client_id
```

### Çalıştırma

```bash
# Development mode (nodemon ile)
npm run dev

# Production mode
npm start
```

Server `http://localhost:3000` adresinde çalışacaktır.

---

## İki Aşamalı Kayıt Süreci

### 1. Aşama: İlk Oturum Açma (Google/Facebook/Apple)

Kullanıcı Google, Facebook veya Apple ile oturum açar. Bu aşamada sadece temel bilgiler database'e kaydedilir:
- `credential` (google/facebook/apple)
- `credentialData` (providerId, email, id)
- `profilePhotoUrl` (varsa)
- `username` (geçici: `temp_` ile başlar)
- `answerData` (null - henüz tamamlanmadı)

### 2. Aşama: Profil Tamamlama

Kullanıcı uygulama içinde soruları cevapladıktan sonra profil bilgileri tamamlanır:
- `username` (gerçek kullanıcı adı)
- `answerData` (QuestionAnswers objesi)
- `nativeLang` (opsiyonel)
- `gender` (opsiyonel)

**Akış:**
1. Kullanıcı Google ile oturum açar → `POST /auth/google`
2. JWT token alınır
3. Uygulama içinde sorular gösterilir
4. Kullanıcı soruları cevaplar
5. Profil tamamlanır → `PUT /auth/profile` (token ile)
6. Kullanıcı tam profili ile sisteme giriş yapmış olur

## Flutter Entegrasyonu

### Örnek Kullanım

#### 1. Google Authentication (İlk Oturum Açma)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> signInWithGoogle(String idToken) async {
  final response = await http.post(
    Uri.parse('http://your-api-url/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'idToken': idToken}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'user': UserModel.fromMap(data['data']['user']),
      'token': data['data']['token'],
    };
  } else {
    throw Exception('Authentication failed');
  }
}
```

#### 2. Profil Tamamlama

```dart
Future<UserModel> completeProfile({
  required String token,
  required String username,
  String? nativeLang,
  String? gender,
  Map<String, dynamic>? answerData,
}) async {
  final response = await http.put(
    Uri.parse('http://your-api-url/auth/profile'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'username': username,
      if (nativeLang != null) 'nativeLang': nativeLang,
      if (gender != null) 'gender': gender,
      if (answerData != null) 'answerData': answerData,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return UserModel.fromMap(data['data']['user']);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'Profile update failed');
  }
}
```

#### 3. Tam Akış Örneği

```dart
// 1. Google ile oturum aç
final authResult = await signInWithGoogle(googleIdToken);
final user = authResult['user'];
final token = authResult['token'];

// Token'ı sakla (SharedPreferences, SecureStorage, vs.)
await saveToken(token);

// 2. Profil tamamlanmış mı kontrol et
bool isProfileComplete = user.username != null && 
                         !user.username.startsWith('temp_') &&
                         user.answerData != null;

if (!isProfileComplete) {
  // 3. Profil tamamlama ekranına yönlendir
  // Kullanıcı soruları cevaplar...
  
  // 4. Profil tamamla
  final updatedUser = await completeProfile(
    token: token,
    username: 'my_username',
    nativeLang: 'tr',
    gender: 'male',
    answerData: {
      'avaibleDays': ['monday', 'tuesday'],
      'avaibleHours': ['09:00', '10:00'],
      'supportArea': 'anxiety',
      'agentSpeakStyle': 'supportive',
    },
  );
}
```

#### Facebook Authentication (İlk Oturum Açma)

```dart
Future<Map<String, dynamic>> signInWithFacebook(String accessToken) async {
  final response = await http.post(
    Uri.parse('http://your-api-url/auth/facebook'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'accessToken': accessToken}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'user': UserModel.fromMap(data['data']['user']),
      'token': data['data']['token'],
    };
  } else {
    throw Exception('Authentication failed');
  }
}
```

#### Apple Authentication (İlk Oturum Açma)

```dart
Future<Map<String, dynamic>> signInWithApple({
  required String identityToken,
  required String userIdentifier,
  String? authorizationCode,
}) async {
  final response = await http.post(
    Uri.parse('http://your-api-url/auth/apple'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'identityToken': identityToken,
      'userIdentifier': userIdentifier,
      if (authorizationCode != null) 'authorizationCode': authorizationCode,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {
      'user': UserModel.fromMap(data['data']['user']),
      'token': data['data']['token'],
    };
  } else {
    throw Exception('Authentication failed');
  }
}
```

---

## TODO / Gelecek Geliştirmeler

1. **Database Entegrasyonu**
   - MongoDB veya PostgreSQL entegrasyonu
   - User model için database schema
   - Kullanıcı kayıt/güncelleme işlemleri

2. **JWT Token Implementation**
   - Token oluşturma ve verify etme
   - Token refresh mekanizması
   - Token expiration yönetimi

3. **Provider SDK Entegrasyonları**
   - Google OAuth2 client implementasyonu
   - Facebook Graph API entegrasyonu
   - Apple JWT verification

4. **Security**
   - Rate limiting
   - CORS yapılandırması
   - Input sanitization
   - SQL injection / NoSQL injection koruması

5. **Testing**
   - Unit testler
   - Integration testler
   - E2E testler

6. **Logging & Monitoring**
   - Winston veya benzeri logging library
   - Error tracking (Sentry vb.)
   - API monitoring

---

## Proje Yapısı

```
mc_apis/
├── app.js                    # Ana uygulama dosyası
├── package.json             # Dependencies
├── routes/
│   └── auth.js             # Authentication route'ları
├── models/
│   ├── User.js             # User model
│   ├── QuestionAnswers.js  # QuestionAnswers model
│   └── AuthRequest.js      # Auth request modelleri
├── middleware/
│   ├── validation.js       # Request validation
│   └── errorHandler.js     # Error handling
├── services/
│   └── authService.js      # Auth business logic
└── flutter_models/
    ├── user_model.dart     # Flutter User model
    └── consultant_model.dart
```

---

## Notlar

- Şu anki implementasyon mock/placeholder'dır. Gerçek provider SDK'ları entegre edilmelidir.
- Database entegrasyonu yapılmamıştır. Kullanıcı verileri kalıcı olarak saklanmamaktadır.
- JWT token implementasyonu henüz yapılmamıştır.
- Production ortamında HTTPS kullanılmalıdır.
- Environment variables güvenli bir şekilde yönetilmelidir (dotenv vb.).

---

## İletişim ve Destek

Sorularınız için issue açabilir veya geliştirici ekibiyle iletişime geçebilirsiniz.

