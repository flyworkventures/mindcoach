# Randevu Webhook API Dokümantasyonu

## Genel Bakış

Randevu Webhook API'si, AI asistan veya harici sistemler tarafından kullanıcılar için randevu oluşturmak için kullanılır. Randevu oluşturulduğunda otomatik olarak kullanıcıya bildirim gönderilir.

**Base URL:** `http://localhost:3014` (veya production URL'iniz)

---

## Endpoint

### Randevu Oluşturma (Webhook)

**Endpoint:** `POST /appointments/webhook`

**Açıklama:** AI asistan veya harici sistemler tarafından kullanıcı için randevu oluşturur. Randevu oluşturulduğunda otomatik olarak:
- Kullanıcıya OneSignal push notification gönderilir
- Bildirim veritabanına kaydedilir
- Bildirim mesajı: `"$koçun adı, sizin için randevu oluşturdu"`

**Authentication:** Gerekli değil (webhook için public endpoint)

---

## Request

### Headers

```
Content-Type: application/json
```

### Request Body

```json
{
  "userId": 123,
  "consultantId": 1,
  "appointmentDate": "2025-01-15T14:30:00.000Z"
}
```

### Request Parameters

| Parametre | Tip | Zorunlu | Açıklama |
|-----------|-----|---------|----------|
| `userId` | `number` | ✅ Evet | Randevuyu alan kullanıcının ID'si |
| `consultantId` | `number` | ✅ Evet | Randevuyu veren koçun ID'si |
| `appointmentDate` | `string` | ✅ Evet | Randevu tarihi (ISO 8601 formatında) |

### Tarih Formatı

`appointmentDate` parametresi **ISO 8601** formatında olmalıdır:

- ✅ **Geçerli:** `"2025-01-15T14:30:00.000Z"`
- ✅ **Geçerli:** `"2025-01-15T14:30:00Z"`
- ✅ **Geçerli:** `"2025-01-15T14:30:00+03:00"`
- ❌ **Geçersiz:** `"2025-01-15 14:30:00"`
- ❌ **Geçersiz:** `"15/01/2025 14:30"`

---

## Response

### Success Response (201 Created)

```json
{
  "success": true,
  "message": "Randevunuz oluşturuldu",
  "appointment": {
    "id": 1,
    "userId": 123,
    "consultantId": 1,
    "appointmentDate": "2025-01-15T14:30:00.000Z",
    "status": "pending",
    "createdAt": "2025-01-10T10:00:00.000Z"
  }
}
```

### Error Responses

#### 400 Bad Request - Eksik Parametreler

```json
{
  "success": false,
  "error": "Missing required fields: userId, consultantId, and appointmentDate are required"
}
```

#### 500 Internal Server Error - Kullanıcı Bulunamadı

```json
{
  "success": false,
  "error": "User not found"
}
```

#### 500 Internal Server Error - Koç Bulunamadı

```json
{
  "success": false,
  "error": "Consultant not found"
}
```

#### 500 Internal Server Error - Geçersiz Tarih Formatı

```json
{
  "success": false,
  "error": "Invalid appointment date format. Expected ISO 8601 format."
}
```

#### 500 Internal Server Error - Genel Hata

```json
{
  "success": false,
  "error": "Internal server error"
}
```

---

## Bildirim Sistemi

Randevu oluşturulduğunda otomatik olarak:

1. **OneSignal Push Notification** gönderilir (eğer yapılandırılmışsa)
2. **Bildirim veritabanına kaydedilir**

### Bildirim İçeriği

- **Başlık:** `"Yeni Randevu"`
- **Mesaj:** `"$koçun adı, sizin için randevu oluşturdu"`
  - Koçun adı, koçun `names` objesinden alınır (tr, en, de dillerinden biri)
  - Eğer koçun adı bulunamazsa, varsayılan olarak `"Koç"` kullanılır

### Bildirim Metadata

Bildirim veritabanına şu metadata ile kaydedilir:

```json
{
  "type": "appointment",
  "appointmentId": 1,
  "consultantId": 1,
  "timestamp": "2025-01-10T10:00:00.000Z",
  "oneSignalId": "abc123-def456-ghi789" // OneSignal notification ID (varsa)
}
```

---

## Kullanım Örnekleri

### cURL Örneği

```bash
curl -X POST http://localhost:3014/appointments/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 123,
    "consultantId": 1,
    "appointmentDate": "2025-01-15T14:30:00.000Z"
  }'
```

### JavaScript (Node.js) Örneği

```javascript
const axios = require('axios');

async function createAppointment(userId, consultantId, appointmentDate) {
  try {
    const response = await axios.post(
      'http://localhost:3014/appointments/webhook',
      {
        userId: userId,
        consultantId: consultantId,
        appointmentDate: appointmentDate
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Randevu oluşturuldu:', response.data);
    return response.data;
  } catch (error) {
    if (error.response) {
      console.error('❌ Hata:', error.response.data);
    } else {
      console.error('❌ Hata:', error.message);
    }
    throw error;
  }
}

// Kullanım
createAppointment(123, 1, '2025-01-15T14:30:00.000Z');
```

### Python Örneği

```python
import requests
from datetime import datetime

def create_appointment(user_id, consultant_id, appointment_date):
    url = 'http://localhost:3014/appointments/webhook'
    
    payload = {
        'userId': user_id,
        'consultantId': consultant_id,
        'appointmentDate': appointment_date
    }
    
    headers = {
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        
        data = response.json()
        print(f'✅ Randevu oluşturuldu: {data}')
        return data
    except requests.exceptions.RequestException as e:
        print(f'❌ Hata: {e}')
        if hasattr(e.response, 'json'):
            print(f'Hata detayı: {e.response.json()}')
        raise

# Kullanım
create_appointment(123, 1, '2025-01-15T14:30:00.000Z')
```

### Flutter/Dart Örneği

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> createAppointment({
  required int userId,
  required int consultantId,
  required String appointmentDate,
}) async {
  final url = Uri.parse('http://localhost:3014/appointments/webhook');
  
  final body = jsonEncode({
    'userId': userId,
    'consultantId': consultantId,
    'appointmentDate': appointmentDate,
  });
  
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: body,
  );
  
  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    print('✅ Randevu oluşturuldu: $data');
    return data;
  } else {
    final error = jsonDecode(response.body);
    print('❌ Hata: ${error['error']}');
    throw Exception(error['error'] ?? 'Randevu oluşturulamadı');
  }
}

// Kullanım
await createAppointment(
  userId: 123,
  consultantId: 1,
  appointmentDate: '2025-01-15T14:30:00.000Z',
);
```

---

## Randevu Durumları

Randevu oluşturulduğunda varsayılan durum `"pending"` (beklemede) olarak ayarlanır.

### Olası Durumlar

- `"pending"` - Beklemede (varsayılan)
- `"confirmed"` - Onaylandı
- `"cancelled"` - İptal edildi
- `"completed"` - Tamamlandı

---

## Bildirim Akışı

1. **Randevu Oluşturulur**
   - `POST /appointments/webhook` endpoint'ine istek gönderilir
   - Randevu veritabanına kaydedilir

2. **Koç Bilgisi Alınır**
   - Koçun ID'si ile koç bilgileri çekilir
   - Koçun adı (`names.tr`, `names.en`, veya `names.de`) alınır

3. **Bildirim Hazırlanır**
   - Başlık: `"Yeni Randevu"`
   - Mesaj: `"$koçun adı, sizin için randevu oluşturdu"`

4. **OneSignal Bildirimi Gönderilir** (async)
   - OneSignal API'sine bildirim gönderilir
   - Hata olsa bile işlem devam eder

5. **Bildirim Veritabanına Kaydedilir**
   - Bildirim `notifications` tablosuna kaydedilir
   - Metadata ile birlikte saklanır

6. **Flutter Uygulaması Bildirimi Gösterir**
   - Uygulama bildirimleri API'den çeker
   - Yeni randevu bildirimleri otomatik gösterilir

---

## Hata Yönetimi

### OneSignal Hatası

Eğer OneSignal bildirimi gönderilemezse:
- Hata loglanır
- İşlem devam eder (randevu oluşturulur)
- Bildirim veritabanına kaydedilir
- OneSignal ID `null` olarak kaydedilir

### Veritabanı Hatası

Eğer bildirim veritabanına kaydedilemezse:
- Hata loglanır
- Randevu oluşturulmuş olur
- OneSignal bildirimi gönderilmiş olabilir

---

## Güvenlik Notları

⚠️ **Önemli:** Bu endpoint public'tir (authentication gerektirmez). Webhook güvenliği için:

1. **IP Whitelist:** Sadece belirli IP adreslerinden istek kabul edin
2. **API Key:** İsteğe bağlı olarak API key doğrulaması ekleyin
3. **Rate Limiting:** Aynı kullanıcı için çok fazla randevu oluşturulmasını engelleyin
4. **Validation:** Tüm input'ları doğrulayın

---

## Test Senaryoları

### Başarılı Randevu Oluşturma

```bash
curl -X POST http://localhost:3014/appointments/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 123,
    "consultantId": 1,
    "appointmentDate": "2025-01-15T14:30:00.000Z"
  }'
```

**Beklenen:** 201 Created, randevu oluşturulur ve bildirim gönderilir

### Eksik Parametreler

```bash
curl -X POST http://localhost:3014/appointments/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 123
  }'
```

**Beklenen:** 400 Bad Request, hata mesajı döner

### Geçersiz Tarih Formatı

```bash
curl -X POST http://localhost:3014/appointments/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 123,
    "consultantId": 1,
    "appointmentDate": "2025-01-15 14:30:00"
  }'
```

**Beklenen:** 500 Internal Server Error, geçersiz tarih formatı hatası

### Olmayan Kullanıcı

```bash
curl -X POST http://localhost:3014/appointments/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 99999,
    "consultantId": 1,
    "appointmentDate": "2025-01-15T14:30:00.000Z"
  }'
```

**Beklenen:** 500 Internal Server Error, "User not found" hatası

### Olmayan Koç

```bash
curl -X POST http://localhost:3014/appointments/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 123,
    "consultantId": 99999,
    "appointmentDate": "2025-01-15T14:30:00.000Z"
  }'
```

**Beklenen:** 500 Internal Server Error, "Consultant not found" hatası

---

## İlgili Endpoint'ler

- `GET /appointments/user/:userId` - Kullanıcının tüm randevularını getir
- `GET /appointments/user/:userId/upcoming` - Kullanıcının yaklaşan randevusunu getir
- `GET /notifications` - Kullanıcının bildirimlerini getir

---

## Sorun Giderme

### Bildirim Gönderilmiyor

1. OneSignal yapılandırmasını kontrol edin (`.env` dosyasında `ONESIGNAL_APP_ID` ve `ONESIGNAL_REST_API_KEY`)
2. Kullanıcının OneSignal'e kayıtlı olduğundan emin olun
3. Server loglarını kontrol edin

### Randevu Oluşturulmuyor

1. Kullanıcı ve koç ID'lerinin geçerli olduğundan emin olun
2. Tarih formatının ISO 8601 olduğundan emin olun
3. Server loglarını kontrol edin

### Bildirim Veritabanına Kaydedilmiyor

1. `notifications` tablosunun oluşturulduğundan emin olun
2. Database bağlantısını kontrol edin
3. Server loglarını kontrol edin

---

## Changelog

### v1.0.0 (2025-01-10)
- İlk sürüm
- Randevu oluşturma webhook endpoint'i eklendi
- Otomatik bildirim gönderme özelliği eklendi
- OneSignal entegrasyonu eklendi

