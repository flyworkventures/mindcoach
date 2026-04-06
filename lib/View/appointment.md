# Appointment API Documentation

## Randevu İptal Etme ve Yeniden Aktifleştirme API'leri

Bu dokümantasyon, randevu iptal etme ve iptal edilmiş randevuları yeniden aktifleştirme API'lerini açıklar.

---

## 📋 İçindekiler

1. [Randevu İptal Etme](#randevu-iptal-etme)
2. [Randevu Yeniden Aktifleştirme](#randevu-yeniden-aktifleştirme)
3. [Status Durumları](#status-durumları)
4. [Hata Yönetimi](#hata-yönetimi)
5. [Örnek Kullanımlar](#örnek-kullanımlar)

---

## 🚫 Randevu İptal Etme

### Endpoint
```
DELETE /appointments/:id
```

### Açıklama
Kullanıcı kendi randevusunu iptal edebilir. **ÖNEMLİ:** Randevu veritabanından silinmez, sadece `status` değeri `cancelled` olarak güncellenir. Randevu geçmişte görünmeye devam eder.

### Headers
```
Authorization: Bearer <token>
```

### URL Parameters
- `id` (number, required): İptal edilecek randevunun ID'si

### İptal Edilebilir Durumlar
- ✅ `pending` - Bekleyen randevular iptal edilebilir
- ✅ `confirmed` - Onaylanmış randevular iptal edilebilir
- ❌ `cancelled` - Zaten iptal edilmiş randevular iptal edilemez
- ❌ `completed` - Tamamlanmış randevular iptal edilemez

### Response (Başarılı - 200)
```json
{
  "success": true,
  "message": "Appointment cancelled successfully",
  "data": {
    "id": 1,
    "user_id": 123,
    "consultant_id": 2,
    "appointment_date": "2026-01-16T10:00:00.000Z",
    "status": "cancelled",
    "created_at": "2026-01-15T10:00:00.000Z",
    "updated_at": "2026-01-15T12:00:00.000Z"
  }
}
```

### Hata Durumları

#### 404 - Randevu Bulunamadı
```json
{
  "success": false,
  "error": "Appointment not found"
}
```

#### 403 - Yetkisiz Erişim
```json
{
  "success": false,
  "error": "Unauthorized: Appointment does not belong to user"
}
```

#### 400 - Zaten İptal Edilmiş
```json
{
  "success": false,
  "error": "Appointment is already cancelled"
}
```

#### 400 - Tamamlanmış Randevu
```json
{
  "success": false,
  "error": "Cannot cancel a completed appointment"
}
```

### Örnek Kullanım

#### cURL
```bash
curl -X DELETE \
  http://localhost:3011/appointments/1 \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### JavaScript (Fetch)
```javascript
const response = await fetch('http://localhost:3011/appointments/1', {
  method: 'DELETE',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const data = await response.json();
console.log(data);
```

---

## ✅ Randevu Yeniden Aktifleştirme

### Endpoint
```
PUT /appointments/:id/reactivate
```

### Açıklama
İptal edilmiş (`cancelled`) bir randevuyu tekrar `pending` durumuna getirir. Randevu tarihi hala gelecekte olmalıdır.

### Headers
```
Authorization: Bearer <token>
```

### URL Parameters
- `id` (number, required): Yeniden aktifleştirilecek randevunun ID'si

### Yeniden Aktifleştirilebilir Durumlar
- ✅ `cancelled` - Sadece iptal edilmiş randevular yeniden aktifleştirilebilir
- ❌ `pending` - Zaten bekleyen randevular aktifleştirilemez
- ❌ `confirmed` - Onaylanmış randevular aktifleştirilemez
- ❌ `completed` - Tamamlanmış randevular aktifleştirilemez

### Koşullar
1. Randevu `cancelled` durumunda olmalıdır
2. Randevu tarihi hala gelecekte olmalıdır (geçmiş tarihli randevular aktifleştirilemez)
3. Kullanıcı randevunun sahibi olmalıdır

### Response (Başarılı - 200)
```json
{
  "success": true,
  "message": "Appointment reactivated successfully",
  "data": {
    "id": 1,
    "user_id": 123,
    "consultant_id": 2,
    "appointment_date": "2026-01-16T10:00:00.000Z",
    "status": "pending",
    "created_at": "2026-01-15T10:00:00.000Z",
    "updated_at": "2026-01-15T13:00:00.000Z"
  }
}
```

### Hata Durumları

#### 404 - Randevu Bulunamadı
```json
{
  "success": false,
  "error": "Appointment not found"
}
```

#### 403 - Yetkisiz Erişim
```json
{
  "success": false,
  "error": "Unauthorized: Appointment does not belong to user"
}
```

#### 400 - İptal Edilmemiş Randevu
```json
{
  "success": false,
  "error": "Cannot reactivate appointment with status 'pending'. Only cancelled appointments can be reactivated."
}
```

#### 400 - Geçmiş Tarihli Randevu
```json
{
  "success": false,
  "error": "Cannot reactivate an appointment that has already passed"
}
```

### Örnek Kullanım

#### cURL
```bash
curl -X PUT \
  http://localhost:3011/appointments/1/reactivate \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

#### JavaScript (Fetch)
```javascript
const response = await fetch('http://localhost:3011/appointments/1/reactivate', {
  method: 'PUT',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const data = await response.json();
console.log(data);
```

---

## 📊 Status Durumları

| Status | Açıklama | İptal Edilebilir | Aktifleştirilebilir |
|--------|----------|------------------|---------------------|
| `pending` | Bekleyen randevu | ✅ Evet | ❌ Hayır (zaten aktif) |
| `confirmed` | Onaylanmış randevu | ✅ Evet | ❌ Hayır |
| `cancelled` | İptal edilmiş randevu | ❌ Hayır (zaten iptal) | ✅ Evet (gelecek tarihli ise) |
| `completed` | Tamamlanmış randevu | ❌ Hayır | ❌ Hayır |

### Status Akışı

```
pending → cancelled → pending (reactivate)
confirmed → cancelled → pending (reactivate)
pending → confirmed → completed
```

---

## 🔄 İş Akışı Örneği

### Senaryo: Kullanıcı Randevusunu İptal Edip Sonra Geri Alıyor

1. **Randevu Oluşturuldu**
   ```json
   {
     "id": 1,
     "status": "pending",
     "appointment_date": "2026-01-20T10:00:00.000Z"
   }
   ```

2. **Kullanıcı Randevuyu İptal Etti**
   ```
   DELETE /appointments/1
   ```
   ```json
   {
     "status": "cancelled",
     "updated_at": "2026-01-15T12:00:00.000Z"
   }
   ```

3. **Kullanıcı Fikrini Değiştirdi ve Randevuyu Geri Aldı**
   ```
   PUT /appointments/1/reactivate
   ```
   ```json
   {
     "status": "pending",
     "updated_at": "2026-01-15T13:00:00.000Z"
   }
   ```

---

## 🛡️ Güvenlik

- ✅ Kullanıcı sadece kendi randevularını iptal/aktifleştirebilir
- ✅ Authentication token zorunludur
- ✅ Randevu sahipliği kontrol edilir
- ✅ Status validasyonu yapılır
- ✅ Tarih kontrolü yapılır (geçmiş tarihli randevular aktifleştirilemez)

---

## 📝 Notlar

1. **Veritabanından Silme:** Randevular asla veritabanından silinmez, sadece status güncellenir
2. **Geçmiş Tarihli Randevular:** Geçmiş tarihli iptal edilmiş randevular aktifleştirilemez
3. **Bildirimler:** İptal ve aktifleştirme işlemlerinde kullanıcıya bildirim gönderilir
4. **Audit Trail:** Tüm status değişiklikleri `updated_at` alanında kaydedilir

---

## 🔗 İlgili Endpoint'ler

- `GET /appointments/user/:userId` - Kullanıcının tüm randevularını getir
- `GET /appointments/user/:userId/upcoming` - Kullanıcının yaklaşan randevusunu getir
- `POST /appointments/webhook` - Webhook ile randevu oluştur

---

## 📞 Destek

Sorularınız için lütfen API dokümantasyonunu kontrol edin veya destek ekibiyle iletişime geçin.
