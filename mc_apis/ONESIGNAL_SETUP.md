# OneSignal Bildirim Entegrasyonu

Bu dokümantasyon, OneSignal ile push notification gönderme ve veritabanına kaydetme işlemlerini açıklar.

## Kurulum

### 1. Environment Variables

`.env` dosyanıza aşağıdaki OneSignal değişkenlerini ekleyin:

```env
# OneSignal Configuration
ONESIGNAL_APP_ID=your_onesignal_app_id
ONESIGNAL_REST_API_KEY=your_onesignal_rest_api_key
```

### 2. OneSignal App ID ve REST API Key Alma

1. [OneSignal Dashboard](https://app.onesignal.com/)'a giriş yapın
2. Uygulamanızı seçin veya yeni bir uygulama oluşturun
3. **Settings > Keys & IDs** bölümüne gidin
4. **REST API Key**'i kopyalayın
5. **App ID**'yi kopyalayın
6. Bu değerleri `.env` dosyanıza ekleyin

### 3. Database Migration

Notifications tablosunu oluşturmak için migration dosyasını çalıştırın:

```bash
mysql -u root -p mindcoach < database/migrations/013_create_notifications_table.sql
```

Veya phpMyAdmin gibi bir tool kullanarak SQL dosyasını çalıştırın.

## API Endpoints

### 1. Belirli Kullanıcı(lar)a Bildirim Gönderme

**Endpoint:** `POST /notifications/send`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "userIds": 123,  // veya [123, 456] (tek kullanıcı veya array)
  "title": "Yeni Mesaj",
  "subtitle": "Size yeni bir mesaj geldi",
  "type": "system_notification",  // veya "announcement" (opsiyonel, default: "system_notification")
  "metadata": {  // opsiyonel
    "chatId": 1,
    "consultantId": 2
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 1,
        "userId": 123,
        "type": "system_notification",
        "title": "Yeni Mesaj",
        "subtitle": "Size yeni bir mesaj geldi",
        "metadata": {
          "chatId": 1,
          "consultantId": 2,
          "oneSignalId": "abc123"
        },
        "sentTime": "2025-01-01T12:00:00.000Z"
      }
    ],
    "oneSignal": {
      "success": true,
      "oneSignalId": "abc123",
      "recipients": 1,
      "data": { ... }
    }
  },
  "message": "Notification sent to 1 user(s)"
}
```

### 2. Tüm Kullanıcılara Broadcast Bildirim Gönderme

**Endpoint:** `POST /notifications/broadcast`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "Yeni Özellik",
  "subtitle": "Uygulamaya yeni özellikler eklendi!",
  "type": "announcement",  // opsiyonel, default: "announcement"
  "metadata": {  // opsiyonel
    "feature": "new_chat_feature"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "oneSignal": {
      "success": true,
      "oneSignalId": "abc123",
      "recipients": "all",
      "data": { ... }
    }
  },
  "message": "Broadcast notification sent successfully"
}
```

### 3. Kullanıcının Bildirimlerini Getirme

**Endpoint:** `GET /notifications`

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (opsiyonel, default: 50) - Sonuç sayısı
- `offset` (opsiyonel, default: 0) - Sayfalama için offset

**Response:**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 1,
        "userId": 123,
        "type": "system_notification",
        "title": "Yeni Mesaj",
        "subtitle": "Size yeni bir mesaj geldi",
        "metadata": {
          "chatId": 1
        },
        "sentTime": "2025-01-01T12:00:00.000Z"
      }
    ],
    "count": 1
  }
}
```

### 4. Belirli Bir Bildirimi Getirme

**Endpoint:** `GET /notifications/:id`

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "notification": {
      "id": 1,
      "userId": 123,
      "type": "system_notification",
      "title": "Yeni Mesaj",
      "subtitle": "Size yeni bir mesaj geldi",
      "metadata": {
        "chatId": 1
      },
      "sentTime": "2025-01-01T12:00:00.000Z"
    }
  }
}
```

## Kullanım Örnekleri

### Örnek 1: Tek Kullanıcıya Bildirim Gönderme

```javascript
const axios = require('axios');

const response = await axios.post(
  'http://your-api-url/notifications/send',
  {
    userIds: 123,
    title: 'Yeni Randevu',
    subtitle: 'Randevunuz başarıyla oluşturuldu',
    type: 'system_notification',
    metadata: {
      appointmentId: 456
    }
  },
  {
    headers: {
      'Authorization': 'Bearer your_token_here',
      'Content-Type': 'application/json'
    }
  }
);
```

### Örnek 2: Birden Fazla Kullanıcıya Bildirim Gönderme

```javascript
const response = await axios.post(
  'http://your-api-url/notifications/send',
  {
    userIds: [123, 456, 789],
    title: 'Yeni Duyuru',
    subtitle: 'Sistem bakımı yapılacaktır',
    type: 'announcement',
    metadata: {
      maintenanceDate: '2025-01-15'
    }
  },
  {
    headers: {
      'Authorization': 'Bearer your_token_here',
      'Content-Type': 'application/json'
    }
  }
);
```

### Örnek 3: Broadcast Bildirim

```javascript
const response = await axios.post(
  'http://your-api-url/notifications/broadcast',
  {
    title: 'Yeni Özellik',
    subtitle: 'Uygulamaya yeni sohbet özellikleri eklendi!',
    type: 'announcement',
    metadata: {
      version: '2.0.0'
    }
  },
  {
    headers: {
      'Authorization': 'Bearer your_token_here',
      'Content-Type': 'application/json'
    }
  }
);
```

## Hata Yönetimi

### OneSignal Hatası

Eğer OneSignal API'si hata verirse:
- Bildirim veritabanına kaydedilmeye devam eder
- OneSignal hatası loglanır ama işlem durmaz
- Response'da `oneSignal` alanı `null` olabilir

### Veritabanı Hatası

Eğer veritabanına kaydetme sırasında hata olursa:
- OneSignal bildirimi gönderilmiş olsa bile veritabanına kaydedilmeyebilir
- Hata loglanır ve response'da sadece başarılı kayıtlar döner

## Notlar

1. **OneSignal External User IDs**: OneSignal'e gönderilen `userIds` değerleri, OneSignal dashboard'unda "External User IDs" olarak ayarlanmalıdır. Flutter uygulamasında OneSignal SDK'sını initialize ederken kullanıcı ID'sini set etmelisiniz.

2. **Notification Types**: 
   - `system_notification`: Sistem bildirimleri (mesaj, randevu, vb.)
   - `announcement`: Duyurular (yeni özellik, bakım, vb.)

3. **Metadata**: Metadata alanı JSON formatında saklanır ve bildirim içeriğine ek bilgiler eklemek için kullanılabilir (örneğin: chatId, appointmentId, vb.).

4. **Authentication**: Tüm endpoint'ler authentication gerektirir. Bearer token ile istek yapılmalıdır.

