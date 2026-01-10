# MySQL Database Kurulum Rehberi

## Özet

Artık authentication sistemi **MySQL database** ile tam entegre çalışıyor. Kullanıcılar database'e kaydediliyor, kontrol ediliyor ve JWT token ile authentication yapılıyor.

## Özellikler

✅ **Kullanıcı Kayıt/Kontrol**: Yeni kullanıcılar otomatik database'e kaydediliyor
✅ **Kullanıcı Kontrolü**: Mevcut kullanıcılar kontrol ediliyor ve güncelleniyor
✅ **JWT Token**: Her authentication'da JWT token oluşturuluyor
✅ **Token Verification**: Token doğrulama endpoint'i çalışıyor
✅ **User Profile**: `/auth/me` endpoint'i ile kullanıcı bilgileri alınabiliyor
✅ **Database Operations**: Tüm CRUD işlemleri repository pattern ile yapılıyor

## Kurulum Adımları

### 1. Dependencies Yükleme

```bash
npm install
```

Yeni paketler:
- `mysql2` - MySQL database driver
- `dotenv` - Environment variables
- `bcryptjs` - Password hashing (gelecekte kullanılabilir)

### 2. MySQL Database Oluşturma

```sql
CREATE DATABASE mindcoach CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. Migration Çalıştırma

```bash
mysql -u root -p mindcoach < database/migrations/001_create_users_table.sql
```

Veya MySQL Workbench, phpMyAdmin gibi bir tool kullanarak SQL dosyasını çalıştırın.

### 4. Environment Variables

`.env` dosyası oluşturun:

```env
# Server
PORT=3000

# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=mindcoach

# JWT Configuration
# JWT_SECRET'i oluşturmak için: npm run generate-secret
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
JWT_EXPIRES_IN=7d
JWT_ISSUER=mindcoach-api
JWT_AUDIENCE=mindcoach-app

# Google OAuth (gelecekte kullanılacak)
GOOGLE_CLIENT_ID=your_google_client_id

# Facebook App (gelecekte kullanılacak)
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret

# Apple (gelecekte kullanılacak)
APPLE_TEAM_ID=your_apple_team_id
APPLE_KEY_ID=your_apple_key_id
APPLE_CLIENT_ID=your_apple_client_id
```

### 5. Server'ı Başlatma

```bash
npm start
```

Console'da `✅ MySQL database connected successfully` mesajını görmelisiniz.

## API Endpoints

### POST /auth/:provider

Kullanıcı authentication yapar ve database'e kaydeder/günceller.

**Örnek Request:**
```json
POST /auth/google
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij..."
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "credential": "google",
      "username": "user_name",
      ...
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "User authenticated successfully"
}
```

### GET /auth/verify

JWT token'ı doğrular.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": { ... },
    "valid": true
  },
  "message": "Token is valid"
}
```

### GET /auth/me

Authenticated kullanıcının bilgilerini döner.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user": { ... }
  }
}
```

## Database Yapısı

### Users Table

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key (AUTO_INCREMENT) |
| credential | VARCHAR(50) | Provider type (google, facebook, apple) |
| credential_data | JSON | Provider-specific data |
| username | VARCHAR(255) | Unique username |
| gender | ENUM | male, female, unknown |
| profile_photo_url | VARCHAR(500) | Profile photo URL |
| account_created_date | DATETIME | Account creation date |
| created_at | TIMESTAMP | Record creation timestamp |
| updated_at | TIMESTAMP | Record update timestamp |

## Kullanıcı İşlemleri

### Yeni Kullanıcı Kaydı

1. Provider'dan token verify edilir
2. Database'de kullanıcı kontrol edilir (credential + provider ID)
3. Kullanıcı yoksa yeni kayıt oluşturulur
4. Username unique olmalı, çakışma durumunda otomatik düzeltilir
5. JWT token oluşturulur ve döndürülür

### Mevcut Kullanıcı Girişi

1. Provider'dan token verify edilir
2. Database'de kullanıcı bulunur
3. Profile photo güncellenebilir
4. JWT token oluşturulur ve döndürülür

## Güvenlik

- ✅ JWT token ile authentication
- ✅ Token expiration (7 gün default)
- ✅ Token verification middleware
- ✅ SQL injection koruması (prepared statements)
- ✅ Input validation
- ✅ Error handling

## Notlar

- Database connection pooling kullanılıyor (max 10 connection)
- JSON fields MySQL 5.7+ gerektirir
- Tüm timestamps UTC formatında
- Username conflicts otomatik çözülüyor

## Sorun Giderme

### Database Bağlantı Hatası

```
❌ MySQL database connection error: ...
```

**Çözüm:**
1. `.env` dosyasındaki database bilgilerini kontrol edin
2. MySQL server'ın çalıştığından emin olun
3. Database'in oluşturulduğundan emin olun
4. Kullanıcı adı ve şifrenin doğru olduğundan emin olun

### Table Not Found

```
Error: Table 'mindcoach.users' doesn't exist
```

**Çözüm:**
Migration dosyasını çalıştırın:
```bash
mysql -u root -p mindcoach < database/migrations/001_create_users_table.sql
```

### JWT Secret Error

```
Error: JWT_SECRET is not defined
```

**Çözüm:**
`.env` dosyasına `JWT_SECRET` ekleyin ve server'ı yeniden başlatın.

