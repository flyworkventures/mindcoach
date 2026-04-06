# Periyodik Local Notification Yapısı

Bu dokümantasyon, uygulamada kullanılan periyodik local notification sisteminin yapısını ve kullanımını açıklar.

## 📁 Yapı

```
lib/Services/NotificationsService/
├── local_notification_service.dart          # Local notification servisi (flutter_local_notifications wrapper)
├── periodic_notification_scheduler.dart     # Periyodik bildirimleri zamanlayan ana servis
├── models/
│   ├── notification_content.dart           # Bildirim içerikleri (title, body)
│   └── notification_preferences.dart      # Kullanıcı tercihleri (enabled/disabled, start time)
└── notification_service.dart               # OneSignal servisi (mevcut)
```

## 🎯 Özellikler

### Periyodik Bildirimler
- **2 saatte bir**: Kullanıcıyı düzenli kontrol etmeye teşvik eder
- **4 saatte bir**: Gün içinde düzenli hatırlatmalar
- **8 saatte bir**: Günlük rutin kontrolü
- **24 saatte bir**: Günlük hatırlatıcı

### Bildirim İçerikleri
Her periyot için özel içerikler tanımlanmıştır:
- **2 saat**: "Kendinizi kontrol etmek için biraz zaman ayırın"
- **4 saat**: "Bugün nasıl geçiyor? Düşüncelerinizi paylaşmak ister misiniz?"
- **8 saat**: "Gününüzü değerlendirmek için birkaç dakika ayırın"
- **24 saat**: "Günlük rutininizi tamamlamak için zaman ayırın"

## 🔧 Kullanım

### 1. Initialization

Uygulama başlatıldığında `main.dart` içinde local notification servisi initialize edilir:

```dart
// main.dart
final localNotificationService = LocalNotificationService();
await localNotificationService.initialize();
```

Kullanıcı authenticated olduğunda `app_status_notifier.dart` içinde periyodik bildirimler başlatılır:

```dart
// app_status_notifier.dart
final scheduler = PeriodicNotificationScheduler();
await scheduler.initializeAndSchedule();
```

### 2. Bildirimleri Yönetme

#### Tüm Bildirimleri Aktif/Pasif Yapma

```dart
final scheduler = PeriodicNotificationScheduler();

// Bildirimleri kapat
await scheduler.setNotificationsEnabled(false);

// Bildirimleri aç
await scheduler.setNotificationsEnabled(true);
```

#### Belirli Bir Periyodu Aktif/Pasif Yapma

```dart
final scheduler = PeriodicNotificationScheduler();

// 2 saatlik bildirimi kapat
await scheduler.setIntervalEnabled(2, false);

// 4 saatlik bildirimi aç
await scheduler.setIntervalEnabled(4, true);
```

#### Bildirimleri Güncelleme

Tercihler değiştiğinde:

```dart
final scheduler = PeriodicNotificationScheduler();
await scheduler.updateSchedule();
```

### 3. Bildirim İçeriklerini Özelleştirme

`notification_content.dart` dosyasında içerikleri düzenleyebilirsiniz:

```dart
static const NotificationContent twoHour = NotificationContent(
  title: 'Mind Coach Hatırlatıcı',
  body: 'Özelleştirilmiş mesajınız',
  payload: 'reminder_2h',
);
```

### 4. Kullanıcı Tercihlerini Okuma

```dart
final preferences = NotificationPreferences();

// Bildirimler açık mı?
final enabled = await preferences.areNotificationsEnabled();

// 2 saatlik bildirim açık mı?
final twoHourEnabled = await preferences.isIntervalEnabled(2);

// Başlangıç zamanı
final startTime = await preferences.getStartTime();
```

## 📱 Bildirim ID'leri

Her periyot için sabit ID'ler kullanılır:
- **2 saat**: `1001`
- **4 saat**: `1002`
- **8 saat**: `1003`
- **24 saat**: `1004`

Bu ID'ler `NotificationPreferences` sınıfında tanımlıdır.

## 🔄 Çalışma Mantığı

### 24 Saatlik Bildirim
- `RepeatInterval.daily` kullanılır
- Her gün aynı saatte bildirim gönderilir
- Başlangıç zamanından itibaren hesaplanır

### 2, 4, 8 Saatlik Bildirimler
- `zonedSchedule` ile belirli zamanlarda bildirim gönderilir
- `matchDateTimeComponents: DateTimeComponents.time` ile her gün aynı saatte tekrarlanır
- İlk bildirim zamanı hesaplanır ve sonraki bildirimler otomatik olarak zamanlanır

### Başlangıç Zamanı
- Kullanıcı ilk kez authenticated olduğunda `DateTime.now()` olarak kaydedilir
- Bu zaman, tüm periyotların hesaplanması için referans noktasıdır
- `NotificationPreferences.setStartTime()` ile değiştirilebilir

## 🛠️ Teknik Detaylar

### LocalNotificationService
- `flutter_local_notifications` paketini wrap eder
- Timezone yönetimi (Europe/Istanbul)
- Android ve iOS için ayrı ayarlar
- Bildirim tap handling

### PeriodicNotificationScheduler
- Tüm periyodik bildirimleri yönetir
- Kullanıcı tercihlerine göre bildirimleri zamanlar/iptal eder
- Bildirim içeriklerini yönetir

### NotificationPreferences
- `LocalDbService` (SharedPreferences) kullanarak tercihleri saklar
- Her periyot için ayrı enable/disable durumu
- Başlangıç zamanı saklama

## 📝 Örnek Kullanım Senaryoları

### Senaryo 1: Kullanıcı Bildirimleri Kapatıyor

```dart
final scheduler = PeriodicNotificationScheduler();
await scheduler.setNotificationsEnabled(false);
// Tüm bildirimler iptal edilir
```

### Senaryo 2: Sadece 2 Saatlik Bildirimi Kapatıyor

```dart
final scheduler = PeriodicNotificationScheduler();
await scheduler.setIntervalEnabled(2, false);
// Sadece 2 saatlik bildirim iptal edilir, diğerleri devam eder
```

### Senaryo 3: Bildirim İçeriğini Değiştirme

```dart
// notification_content.dart içinde
static const NotificationContent twoHour = NotificationContent(
  title: 'Yeni Başlık',
  body: 'Yeni Mesaj',
  payload: 'reminder_2h',
);

// Sonra schedule'ı güncelle
final scheduler = PeriodicNotificationScheduler();
await scheduler.updateSchedule();
```

## ⚠️ Önemli Notlar

1. **Timezone**: Bildirimler `Europe/Istanbul` timezone'unda çalışır. Farklı bir timezone kullanmak isterseniz `local_notification_service.dart` içinde değiştirebilirsiniz.

2. **Permissions**: iOS'ta bildirim izinleri istenir. Android'de otomatik olarak verilir (Android 13+ için runtime permission gerekebilir).

3. **Bildirim Kanalı**: Android'de `periodic_notifications` adında bir bildirim kanalı oluşturulur. Bu kanalın ayarlarını değiştirmek isterseniz `local_notification_service.dart` içinde `AndroidNotificationDetails`'i düzenleyin.

4. **Bildirim ID'leri**: Her periyot için sabit ID'ler kullanılır. Bu ID'leri değiştirmek isterseniz `NotificationPreferences` sınıfını güncelleyin.

5. **Başlangıç Zamanı**: Kullanıcı authenticated olduğunda otomatik olarak kaydedilir. Bu zamanı değiştirmek isterseniz `NotificationPreferences.setStartTime()` kullanın.

## 🐛 Sorun Giderme

### Bildirimler Gelmiyor
1. Bildirim izinlerinin verildiğinden emin olun
2. `LocalNotificationService.initialize()` çağrıldığından emin olun
3. `PeriodicNotificationScheduler.initializeAndSchedule()` çağrıldığından emin olun
4. Bildirimlerin aktif olduğunu kontrol edin: `NotificationPreferences.areNotificationsEnabled()`

### Bildirimler Yanlış Zamanda Geliyor
1. Timezone ayarını kontrol edin
2. Başlangıç zamanını kontrol edin: `NotificationPreferences.getStartTime()`
3. Cihaz saatini kontrol edin

### Bildirimler Çok Sık Geliyor
1. Periyot ayarlarını kontrol edin
2. `schedulePeriodicNotification` ve `scheduleSpecificTimeNotification` metodlarını kontrol edin
3. Bildirim ID'lerinin doğru kullanıldığından emin olun

## 📚 İlgili Dosyalar

- `lib/main.dart` - Local notification initialize
- `lib/core/config/app_status_notifier.dart` - Periyodik bildirimleri başlatma
- `lib/Services/NotificationsService/local_notification_service.dart` - Local notification servisi
- `lib/Services/NotificationsService/periodic_notification_scheduler.dart` - Periyodik bildirim scheduler
- `lib/Services/NotificationsService/models/notification_content.dart` - Bildirim içerikleri
- `lib/Services/NotificationsService/models/notification_preferences.dart` - Kullanıcı tercihleri
- `lib/core/utils/local_db_keys.dart` - Local storage key'leri

