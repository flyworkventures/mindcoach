# PostHog Entegrasyon Raporu — MindCoach

**Tarih:** 2026-05-15
**Versiyon:** 1.0.1+6
**Region:** US Cloud (`https://us.i.posthog.com`)
**Project ID:** 376947

---

## 1. Yönetici Özeti

MindCoach Flutter uygulamasına PostHog ürün analitiği platformu entegre edilmiştir. Sistem; kullanıcı davranışlarını, premium dönüşüm hunisini (funnel), randevu/görüşme metriklerini ve içerik kullanımını ölçer. **26 farklı event**, **8 person property** ve **5 super property** ile zengin bir analitik altyapı kurulmuştur. KVKK/GDPR uyumluluğu için kullanıcıya opt-out kontrolü sunulmuştur.

**Sonuç:** Ürün ekibi artık veri-temelli kararlar (paywall optimizasyonu, retention analizi, drop-off tespiti) alabilir; production'a çıkışta dashboard ve cohort tanımları için PostHog paneli üzerinden son kurulum yapılacaktır.

---

## 2. Teknik Mimari

### 2.1 SDK Kurulumu
- **Paket:** `posthog_flutter: ^5.24.0` ([pubspec.yaml](pubspec.yaml))
- **Initialization:** Uygulama açılışında ilk işlem olarak `main.dart` içinde tetiklenir
- **Native auto-init kapalı:** iOS `Info.plist` ve Android `AndroidManifest.xml`'de `AUTO_INIT=false` — initialization tam kontrolümüzde, Flutter tarafından çalıştırılır

### 2.2 Merkezi Servis: `AnalyticsService`
Singleton yapı, [lib/Services/Analytics/analytics_service.dart](lib/Services/Analytics/analytics_service.dart). Tüm event çağrıları bu servis üzerinden geçer. Sağladıkları:
- `initialize()` — SDK setup, opt-out kontrolü, super property kaydı
- `identifyDevice(deviceId)` — anonim cihaz kimliği
- `identifyUser(userId, ...)` — login sonrası kullanıcı kimliği
- `capture(eventName, properties)` — generic event gönderimi
- `trackLoginStarted/Completed/Failed` — convenience helper'ları
- `trackPremiumTransition` — premium state geçişlerini tek noktadan ateşler (duplicate event'leri önler)
- `optIn()` / `optOut()` — KVKK opt-out kontrolü, disk'te kalıcı

### 2.3 Native Konfigürasyon

| Platform | Eklendi |
|---|---|
| **iOS** ([Info.plist](ios/Runner/Info.plist)) | `com.posthog.posthog.AUTO_INIT = false` + `NSUserTrackingUsageDescription` (App Store gereksinimi) |
| **Android** ([AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)) | `com.posthog.posthog.AUTO_INIT = false` |

### 2.4 Otomatik Ekran Takibi
[`PosthogObserver`](lib/app/my_app.dart) `MaterialApp.navigatorObservers` listesine eklenmiştir — her route geçişi otomatik olarak `$screen` event'i olarak gönderilir. Manuel ekran takibi gerekmez.

---

## 3. Event Taksonomisi — 26 Event

Tüm event isimleri **snake_case + geçmiş zaman** kuralına uyar (PostHog standardı). Aşağıdaki tablo her event'in tetiklendiği akışı gösterir.

### 3.1 Uygulama Yaşam Döngüsü

| Event | Açıklama | Tetiklendiği yer |
|---|---|---|
| `app_opened` | Uygulama her açıldığında | [main.dart](lib/main.dart) |
| `session_restored` | Mevcut token ile oturum geri yüklendi | [splash_controller.dart](lib/Riverpod/Controllers/SplashController/splash_controller.dart) |

### 3.2 Auth Akışı

| Event | Property'ler | Tetiklendiği yer |
|---|---|---|
| `login_started` | `provider` (google/facebook/apple/guest) | [auth_provider.dart](lib/Riverpod/Providers/auth_provider.dart) |
| `login_completed` | `provider`, `user_id`, `has_completed_profile` | aynı dosya |
| `login_failed` | `provider`, `reason` | aynı dosya |
| `logout_completed` | — | aynı dosya |
| `account_deleted` | — | [auth_controller.dart](lib/View/auth/presentation/controller/auth_controller.dart) |

### 3.3 Profil Kurulumu

| Event | Property'ler |
|---|---|
| `profile_setup_completed` | `user_id`, `gender`, `support_area`, `available_days_count` |
| `language_changed` | `from`, `to`, `is_system_default` |

### 3.4 Navigasyon

| Event | Property'ler |
|---|---|
| `tab_selected` | `tab_index` |

### 3.5 Premium / Subscription — Funnel

| Event | Tetiklendiği yer | Not |
|---|---|---|
| `paywall_viewed` | [revenuecat_paywalls.dart](lib/core/utils/revenuecat_paywalls.dart) | Paywall gösterildi |
| `paywall_dismissed` | aynı dosya | Paywall kapandı |
| `trial_activated` | premium state listener | 3 günlük trial başladı |
| `premium_purchased` | premium state listener | Gerçek satın alma |
| `premium_deactivated` | premium state listener | Premium iptal/expire |
| `subscription_failed` | revenuecat_paywalls | Purchase sırasında hata |

⚠️ **Önceki bug:** Uygulama her açılışta hayalî `premium_purchased`/`premium_deactivated` event'leri atıyordu (state hydration sırasında). Düzeltildi: `_premiumHydrated` flag ile init tamamlanmadan transition tracking kapalı tutulur.

### 3.6 Coach & Randevu Akışı

| Event | Property'ler |
|---|---|
| `coach_profile_viewed` | `consultant_id`, `consultant_name`, `is_online` |
| `appointment_slot_selected` | `consultant_id`, `slot_time` |
| `appointment_created` | `consultant_id`, `slot_time` |
| `appointment_create_failed` | `consultant_id`, `status_code`, `error_type` |
| `appointment_call_started` | `appointment_id`, `call_type` |

### 3.7 Görüşme / Mesajlaşma

| Event | Kaynak dosya |
|---|---|
| `video_call_started`, `video_call_ended` | [video_call_realtime_screen.dart](lib/View/chat_screen/conversation/video_call/video_call_realtime_screen.dart) |
| `voice_call_started`, `voice_call_ended` | [voice_call_view.dart](lib/View/chat_screen/conversation/voice_call/voice_call_view.dart) |
| `message_sent` | [conversation_page.dart](lib/View/chat_screen/conversation/conversation_page.dart) |
| `conversation_opened` | aynı dosya |

### 3.8 İçerik & Test

| Event | Property'ler |
|---|---|
| `mental_test_started` | `test_name`, `total_questions` |
| `mental_test_completed` | `test_name`, `score`, `level`, `answered_questions` |
| `relaxing_sound_played` | `title`, `audio_path`, `playlist_index` |

---

## 4. Identify & Property Stratejisi

### 4.1 Kullanıcı Kimliği Akışı

```
App açılır
  → identifyDevice("device_<uuid>")        # Anonim
Login yapılır
  → identifyUser(userId, {credential, has_completed_profile, is_premium, ...})
Logout yapılır
  → reset() + identifyDevice tekrar         # Anonim'e döner
```

Bu sayede aynı kullanıcı **birden fazla cihazda** veya **login öncesi/sonrası** PostHog'da tek bir kişi olarak birleşir (person merging).

### 4.2 Super Properties (Her event'e otomatik eklenir)

| Property | Değer örneği |
|---|---|
| `app_name` | `mindcoach` |
| `app_version` | `1.0.1+6` |
| `platform` | `ios` / `android` |
| `build_mode` | `debug` / `release` |
| `locale` | `tr-TR`, `en-US` (sistemin dili) |

### 4.3 Person Properties

| Property | Ne zaman güncellenir |
|---|---|
| `credential` | Login (provider tipi) |
| `has_completed_profile` | Login + profile setup completion |
| `is_premium` | Her premium state değişiminde |
| `is_purchased_premium` | Trial vs purchased ayrımı |
| `premium_days_remaining` | Premium aktif iken |
| `is_authenticated` | Login/logout |

---

## 5. KVKK / GDPR Uyumluluğu

✅ **Opt-out toggle uygulanmıştır.** Kullanıcı Profil Ayarları ekranından "Analitik takibi" anahtarını kapatabilir.

- Karar **disk'te kalıcı** olur (`LocalDbKeys.analyticsOptedOut`)
- Opt-out yapıldığında SDK seviyesinde `Posthog().disable()` çağrılır — hiçbir event ağa çıkmaz
- Sonraki açılışlarda tercih hatırlanır ve uygulanır
- 12 dilde lokalize: Title + açıklama metni (TR, EN, DE, ES, FR, HI, IT, JA, KO, PT, RU, ZH)

iOS App Store reddi riskini önlemek için `NSUserTrackingUsageDescription` Info.plist'e eklendi.

---

## 6. Bildirim Lokalizasyonu (İlişkili Düzeltme)

PostHog entegrasyonu sırasında randevu bildirim sisteminde de tespit edilen sorun düzeltildi:

- 30 dakika öncesi randevu hatırlatması artık **12 dilde** doğru çevirisiyle gönderilir
- Önceden hardcoded switch-case ile yapılan çeviri, **ARB tabanlı l10n sistemine** taşındı
- Türkçe diakritik hataları giderildi ("hatirlatmasi" → "hatırlatması")
- Hindi'de yanlışlıkla İngilizce dönen metin düzeltildi

İlgili dosya: [appointments_notifier.dart](lib/View/appointments/appointments_notifier.dart)

---

## 7. Veri Kalitesi Korumaları

Entegrasyon sırasında tespit edilen ve düzeltilen sorunlar:

| Sorun | Çözüm |
|---|---|
| Açılışta phantom premium event'leri (her cold-start) | Hydration flag eklendi, init bitene kadar tracking kapalı |
| `premium_purchased` aynı satın almada 2× ateşleniyordu | Manuel capture silindi, tek noktadan tetikleniyor |
| `logoutCompleted` iki yerden tetikleniyordu | Tek noktaya (auth_provider) indirgendi |
| `identifyDevice` 3 farklı yerden çağrılıyordu | Tek noktaya indirgendi |
| `appVersion` super property'si pubspec ile uyumsuzdu | Senkronize edildi |
| `PosthogObserver` API key yokken bile aktifti | Koşullu eklenme (sadece `isEnabled` ise) |

---

## 8. PostHog Panelinde Sonraki Adımlar (Production Hazırlığı)

Kod tarafı tamam; aşağıdakiler dashboard tarafı görevlerdir:

### 8.1 Hemen Yapılacaklar
- [ ] **Internal users filter** — Geliştirici/test kullanıcılarını dashboard'lardan dışla
- [ ] **Event taxonomy** — Data Management → Events: her event'e açıklama yaz (ekibin başkalarının da anlaması için)

### 8.2 Dashboard Kurulumu (Öneriler)
- [ ] **Activation Dashboard** — DAU/MAU, 1-7 gün retention, profile setup funnel
- [ ] **Premium Funnel** — `paywall_viewed → trial_activated → premium_purchased` dönüşüm oranı
- [ ] **Coach Funnel** — `coach_profile_viewed → appointment_slot_selected → appointment_created`
- [ ] **Engagement** — Kullanıcı başına `message_sent`, `voice_call_started`, `video_call_started` sayıları
- [ ] **Content** — `mental_test_completed` skorlarının dağılımı, top 10 `relaxing_sound_played`

### 8.3 Cohort Tanımları
- [ ] Premium aktif kullanıcılar (`is_premium = true`)
- [ ] Trial kullanıcıları (`is_premium = true AND is_purchased_premium = false`)
- [ ] Profili tamamlamamış kullanıcılar (`has_completed_profile = false`)
- [ ] Power users (son 7 günde `message_sent ≥ 10`)

### 8.4 Alerts
- [ ] `login_failed` günlük sayım kritik eşiği aşarsa e-mail
- [ ] `premium_purchased` günlük 0'a düşerse uyarı (ödeme sistemi bozuk olabilir)

---

## 9. Bu Aşamada Yapılmayan / Sonraki Faz

| Konu | Durum | Neden |
|---|---|---|
| **Feature Flags** | Yapılmadı | Kod hazır ama ilk fazda gerek yok; A/B test fikri netleşince eklenecek |
| **A/B Experiments** | Yapılmadı | Feature flags'in üstüne inşa edilir |
| **Session Replay** | Bilinçli olarak yapılmadı | Mobile'da consent UI ek iş gerektirir; faz 2 |
| **Onboarding-özel event'ler** | N/A | Doküman'daki "coach swipe / demo call" UI'ları bu projede yok |

---

## 10. Maliyet / Limit

PostHog **Free Tier** üzerinde başlanmıştır:
- **Events:** 1.000.000 / ay ücretsiz
- **Session Recordings:** 5.000 / ay ücretsiz (şu an kapalı)
- **Feature Flags:** 1.000.000 request / ay ücretsiz

Tahmini kullanım: 100 aktif kullanıcı × ~50 event/gün = ~150.000 event/ay → free tier'da rahat oturur.

DAU 1.000'i aşınca **Paid plan**'a geçiş gerekebilir (~$450/ay başlangıç).

---

## 11. Erişim & Hesap

- **Panel URL:** https://us.posthog.com/project/376947
- **Project Token (write-only, kodda gömülü):** `phc_CyQ8mrzY5kZ3Mhg6Aa6YvJCb2fHufwyMG7YHcnccJ8P2`
- **Region:** US Cloud

> ⚠️ Project token write-only olduğu için kod tabanında olması güvenlidir ([PostHog dokümanı](https://posthog.com/docs/getting-started/install) "Safe to use in public apps" der). Repo private; ekstra güvenlik için ileride `--dart-define` ile build-time injection yapılabilir.

---

## 12. Doğrulama

`flutter run` sonrası uygulamayı açtığımızda PostHog **Activity → Live** sekmesinde aşağıdaki event'ler 1-2 saniye içinde görüldü:

- ✅ `app_opened`
- ✅ `$screen` (her ekran geçişinde)
- ✅ `coach_profile_viewed`
- ✅ `conversation_opened`
- ✅ `video_call_started` / `video_call_ended`
- ✅ Person properties doğru set ediliyor

---

## Ekler

- Modifiye edilen dosya sayısı: **20+**
- Yeni dosyalar:
  - [lib/Services/Analytics/analytics_service.dart](lib/Services/Analytics/analytics_service.dart) — Merkezi servis
  - [lib/core/analytics/analytics_events.dart](lib/core/analytics/analytics_events.dart) — Event isim sabitleri
- Lokalizasyon: 12 dilde 3 yeni key (`appointmentReminderTitle`, `appointmentReminderBody`, `appointmentReminderFallbackName`, `analyticsTrackingTitle`, `analyticsTrackingDescription`)

---

**Hazırlayan:** Furkan Kazım Çam ile Claude Code yardımıyla
**İletişim:** furkan@fly-work.com
