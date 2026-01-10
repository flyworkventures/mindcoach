# JWT Token Rehberi - Detaylı Açıklama

## JWT Token Nedir?

JWT (JSON Web Token), kullanıcı authentication için kullanılan güvenli bir token formatıdır. MindCoach API'de kullanıcıların kimlik doğrulaması ve yetkilendirmesi için JWT token kullanılır.

## Token Nasıl Çalışır?

### 1. Token Oluşturma (Token Generation)

Kullanıcı ilk kez Google/Facebook/Apple ile oturum açtığında, API otomatik olarak bir JWT token oluşturur ve döner.

**Ne Zaman Oluşturulur?**
- `POST /auth/google` - Google ile oturum açıldığında
- `POST /auth/facebook` - Facebook ile oturum açıldığında
- `POST /auth/apple` - Apple ile oturum açıldığında

**Token İçeriği:**
```json
{
  "userId": 1,
  "iat": 1234567890,
  "exp": 1235172690,
  "iss": "mindcoach-api",
  "aud": "mindcoach-app"
}
```

**Token Formatı:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImlhdCI6MTIzNDU2Nzg5MCwiZXhwIjoxMjM1MTcyNjkwfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

Token 3 bölümden oluşur:
1. **Header**: Token tipi ve algoritma bilgisi
2. **Payload**: Kullanıcı bilgileri (userId, iat, exp, vb.)
3. **Signature**: Token'ın doğruluğunu kontrol eden imza

### 2. Token Kullanımı

Token oluşturulduktan sonra, kullanıcı her API isteğinde bu token'ı göndermelidir.

**Request Header'da:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Kullanıldığı Endpoint'ler:**
- `PUT /auth/profile` - Profil güncelleme
- `GET /auth/me` - Kullanıcı bilgilerini alma
- `GET /auth/verify` - Token doğrulama

### 3. Token Doğrulama (Token Verification)

Her istekte token doğrulanır:

1. **Token Format Kontrolü**: Token geçerli bir JWT formatında mı?
2. **Signature Kontrolü**: Token imzası doğru mu? (JWT_SECRET ile kontrol edilir)
3. **Expiration Kontrolü**: Token süresi dolmuş mu?
4. **User Kontrolü**: Token'daki userId'ye sahip kullanıcı database'de var mı?

**Başarılı Doğrulama:**
- Kullanıcı bilgileri `req.user` ve `req.userId` olarak request'e eklenir
- İstek devam eder

**Başarısız Doğrulama:**
- `401 Unauthorized` hatası döner
- İstek reddedilir

## Token Özellikleri

### Token Expiration (Süre Sınırı)

**Varsayılan Süre:** 7 gün

Token oluşturulduktan 7 gün sonra geçersiz olur. Kullanıcı yeniden oturum açmalıdır.

**Süre Ayarlama:**
`.env` dosyasında:
```env
JWT_EXPIRES_IN=7d
```

Diğer seçenekler:
- `1h` - 1 saat
- `24h` - 24 saat
- `7d` - 7 gün
- `30d` - 30 gün

### Token Payload

Token içinde şu bilgiler saklanır:

```json
{
  "userId": 1,              // Kullanıcı ID'si (database'deki id)
  "iat": 1234567890,         // Token oluşturulma zamanı (issued at)
  "exp": 1235172690,         // Token sona erme zamanı (expiration)
  "iss": "mindcoach-api",    // Token'ı oluşturan (issuer)
  "aud": "mindcoach-app"     // Token'ın hedefi (audience)
}
```

**Önemli:** Token içinde hassas bilgiler (şifre, email, vb.) saklanmaz. Sadece kullanıcı ID'si ve metadata bilgileri vardır.

## Token Güvenliği

### 1. JWT_SECRET

Token'lar `JWT_SECRET` ile imzalanır. Bu secret key:
- Sadece server'da bilinir
- Token'ın sahte olup olmadığını kontrol eder
- Asla client'a gönderilmez

**Güvenlik:**
- Güçlü bir secret key kullanın (en az 32 karakter)
- Secret key'i asla public repository'lere commit etmeyin
- Production'da farklı bir secret key kullanın

### 2. HTTPS

Production'da mutlaka HTTPS kullanın. HTTP üzerinden token göndermek güvenli değildir.

### 3. Token Storage

**Flutter'da Token Saklama:**
- `flutter_secure_storage` paketi kullanın
- Token'ı SharedPreferences'da saklamayın (güvenli değil)
- Token'ı memory'de tutmayın (uygulama kapanınca kaybolur)

**Önerilen:**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

// Token kaydet
await storage.write(key: 'jwt_token', value: token);

// Token oku
String? token = await storage.read(key: 'jwt_token');
```

## Token İşlem Akışı

### 1. İlk Oturum Açma

```
Kullanıcı → POST /auth/google { idToken }
           ↓
        Server token verify eder
           ↓
        Database'de kullanıcı kontrol edilir/oluşturulur
           ↓
        JWT token oluşturulur (userId ile)
           ↓
        Token kullanıcıya döner
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 2. Token ile İstek Yapma

```
Kullanıcı → GET /auth/me
           Authorization: Bearer <token>
           ↓
        Server token'ı verify eder
           ↓
        Token geçerli mi? (signature, expiration, user)
           ↓
        Kullanıcı bilgileri request'e eklenir
           ↓
        İstek işlenir ve response döner
```

### 3. Token Süresi Dolduğunda

```
Kullanıcı → GET /auth/me
           Authorization: Bearer <expired_token>
           ↓
        Server token'ı verify eder
           ↓
        Token süresi dolmuş!
           ↓
        401 Unauthorized hatası döner
           ↓
        Kullanıcı yeniden oturum açmalı
```

## Flutter'da Token Kullanımı

### 1. Token Kaydetme

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Future<void> saveToken(String token) async {
  await storage.write(key: 'jwt_token', value: token);
}
```

### 2. Token Okuma

```dart
Future<String?> getToken() async {
  return await storage.read(key: 'jwt_token');
}
```

### 3. Token ile İstek Yapma

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> getUserProfile() async {
  final token = await getToken();
  
  if (token == null) {
    throw Exception('No token found. Please login again.');
  }

  final response = await http.get(
    Uri.parse('http://your-api-url/auth/me'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else if (response.statusCode == 401) {
    // Token geçersiz veya süresi dolmuş
    await storage.delete(key: 'jwt_token');
    throw Exception('Token expired. Please login again.');
  } else {
    throw Exception('Failed to get user profile');
  }
}
```

### 4. Token Kontrolü ve Otomatik Yeniden Giriş

```dart
class AuthService {
  static final storage = FlutterSecureStorage();

  // Token var mı ve geçerli mi kontrol et
  static Future<bool> isAuthenticated() async {
    final token = await storage.read(key: 'jwt_token');
    if (token == null) return false;

    try {
      // Token'ı verify et
      final response = await http.get(
        Uri.parse('http://your-api-url/auth/verify'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Token'ı temizle (logout)
  static Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
  }

  // Token ile istek yap (otomatik error handling)
  static Future<http.Response> authenticatedRequest(
    String method,
    Uri url,
    {Map<String, String>? headers, Object? body}
  ) async {
    final token = await storage.read(key: 'jwt_token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final requestHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      ...?headers,
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(url, headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(url, headers: requestHeaders, body: body);
        break;
      case 'PUT':
        response = await http.put(url, headers: requestHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: requestHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method');
    }

    // Token expired ise logout yap
    if (response.statusCode == 401) {
      await logout();
      throw Exception('Token expired. Please login again.');
    }

    return response;
  }
}
```

## Token Hata Durumları

### 1. Token Yok

**Hata:**
```json
{
  "success": false,
  "error": "No token provided. Please provide a valid JWT token in Authorization header."
}
```

**HTTP Status:** 401 Unauthorized

**Çözüm:** Token'ı request header'ına ekleyin:
```
Authorization: Bearer <token>
```

### 2. Token Geçersiz (Invalid Token)

**Hata:**
```json
{
  "success": false,
  "error": "Invalid token"
}
```

**HTTP Status:** 401 Unauthorized

**Nedenleri:**
- Token formatı yanlış
- Token imzası hatalı (JWT_SECRET uyuşmuyor)
- Token bozuk

**Çözüm:** Yeni bir token alın (yeniden oturum açın)

### 3. Token Süresi Dolmuş (Token Expired)

**Hata:**
```json
{
  "success": false,
  "error": "Token has expired"
}
```

**HTTP Status:** 401 Unauthorized

**Çözüm:** Yeniden oturum açın:
```dart
// Eski token'ı sil
await storage.delete(key: 'jwt_token');

// Yeniden oturum aç
final authResult = await signInWithGoogle(googleIdToken);
await saveToken(authResult['token']);
```

### 4. Kullanıcı Bulunamadı

**Hata:**
```json
{
  "success": false,
  "error": "User not found"
}
```

**HTTP Status:** 401 Unauthorized

**Nedenleri:**
- Token'daki userId'ye sahip kullanıcı database'de yok
- Kullanıcı silinmiş olabilir

**Çözüm:** Yeniden oturum açın

## Token Best Practices

### ✅ Yapılması Gerekenler

1. **Token'ı Güvenli Saklayın**
   - `flutter_secure_storage` kullanın
   - Token'ı asla log'lara yazdırmayın

2. **Token'ı Her İstekte Gönderin**
   - Authenticated endpoint'ler için mutlaka token gönderin

3. **Token Expiration Kontrolü**
   - Token süresi dolduğunda kullanıcıyı yeniden login ekranına yönlendirin

4. **HTTPS Kullanın**
   - Production'da mutlaka HTTPS kullanın

5. **Token'ı Logout'ta Temizleyin**
   - Kullanıcı logout olduğunda token'ı silin

### ❌ Yapılmaması Gerekenler

1. **Token'ı URL'de Göndermeyin**
   - Token'ı query parameter olarak göndermeyin
   - Sadece Authorization header'da gönderin

2. **Token'ı Public Yerlerde Saklamayın**
   - SharedPreferences kullanmayın
   - LocalStorage kullanmayın (web için)

3. **Token'ı Paylaşmayın**
   - Token'ı başka kullanıcılarla paylaşmayın
   - Token'ı screenshot'larda göstermeyin

4. **Token'ı Decode Etmeyin (Client'ta)**
   - Token'ı client'ta decode edip kullanmayın
   - Token'ı sadece server'a gönderin

## Özet

1. **Token Oluşturma:** Kullanıcı oturum açtığında otomatik oluşturulur
2. **Token Kullanımı:** Her authenticated istekte Authorization header'da gönderilir
3. **Token Doğrulama:** Server her istekte token'ı verify eder
4. **Token Expiration:** 7 gün sonra geçersiz olur
5. **Token Güvenliği:** JWT_SECRET ile imzalanır, HTTPS ile gönderilir

## Örnek Tam Akış

```dart
// 1. Oturum aç ve token al
final authResult = await signInWithGoogle(googleIdToken);
final token = authResult['token'];
await saveToken(token);

// 2. Token ile profil tamamla
await completeProfile(
  token: token,
  username: 'my_username',
  answerData: { ... },
);

// 3. Token ile kullanıcı bilgilerini al
final userProfile = await getUserProfile(); // Token otomatik eklenir

// 4. Token süresi dolduğunda
try {
  await getUserProfile();
} catch (e) {
  if (e.toString().contains('expired')) {
    // Yeniden login ekranına yönlendir
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
```

Bu rehber, JWT token sisteminin nasıl çalıştığını ve nasıl kullanılacağını detaylı bir şekilde açıklar.

