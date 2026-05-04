import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';

/// Trial kotası aşıldığında atılır. UI bunu yakalayıp uygun paywall'ı açar.
enum TrialQuotaType { message, voice, video }

class TrialQuotaExceededException implements Exception {
  final TrialQuotaType type;
  TrialQuotaExceededException(this.type);

  factory TrialQuotaExceededException.message() =>
      TrialQuotaExceededException(TrialQuotaType.message);
  factory TrialQuotaExceededException.voice() =>
      TrialQuotaExceededException(TrialQuotaType.voice);
  factory TrialQuotaExceededException.video() =>
      TrialQuotaExceededException(TrialQuotaType.video);

  @override
  String toString() => 'TrialQuotaExceededException(${type.name})';
}

/// Non-premium kullanıcılar için cihaz başına deneme süresi sayaçları.
///
/// Kurallar (kullanıcı tarafından tanımlandı):
/// • 20 adet mesaj
/// • 3 dk (= 180 sn) sesli arama
/// • Görüntülü görüşme premium'dur; non-premium için toplam **60 sn** ücretsiz
///   görüntülü deneme hakkı vardır ([trialVideoSecondsUsed]). Kullanım
///   [VideoCallRealtimeScreen] içinde `isTrial` oturumlarında sayılır.
///
/// Sayaçlar `SharedPreferences` üzerinde tutulur — kullanıcı app'i yeniden
/// kurarsa sayaçlar sıfırlanır; bu kabul edilebilir bir davranış (RC paywall
/// dönüşüm hunisinin baskın olduğu trial mantığı).
class TrialQuotaService {
  TrialQuotaService._();
  static final TrialQuotaService instance = TrialQuotaService._();

  static const int messageLimit = 20;
  static const int voiceCallSecondLimit = 3 * 60; // 180 sn = 3 dk
  static const int videoTrialSecondLimit = 60; // 1 dk ücretsiz görüntülü (toplam)

  final LocalDbService _db = LocalDbService();

  // ── Mesaj kotası ──────────────────────────────────────────────────────

  Future<int> messagesUsed() async {
    return (await _db.getInt(key: LocalDbKeys.trialMessagesUsed)) ?? 0;
  }

  Future<int> messagesRemaining() async {
    final used = await messagesUsed();
    final remaining = messageLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  Future<bool> canSendMessage() async {
    return (await messagesRemaining()) > 0;
  }

  Future<void> incrementMessage() async {
    final used = await messagesUsed();
    await _db.setInt(key: LocalDbKeys.trialMessagesUsed, value: used + 1);
  }

  // ── Sesli arama kotası ────────────────────────────────────────────────

  Future<int> voiceSecondsUsed() async {
    return (await _db.getInt(key: LocalDbKeys.trialVoiceSecondsUsed)) ?? 0;
  }

  Future<int> voiceSecondsRemaining() async {
    final used = await voiceSecondsUsed();
    final remaining = voiceCallSecondLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  Future<bool> canStartVoiceCall() async {
    return (await voiceSecondsRemaining()) > 0;
  }

  /// Çağrı esnasında her saniye veya her N saniyede çağrılabilir.
  /// Paniğe gerek yok — `setInt` async ama UI'i bloklayacak kadar yavaş değil.
  Future<void> addVoiceSeconds(int seconds) async {
    if (seconds <= 0) return;
    final used = await voiceSecondsUsed();
    await _db.setInt(
      key: LocalDbKeys.trialVoiceSecondsUsed,
      value: used + seconds,
    );
  }

  // ── Yardımcı: kullanıcı premium'a geçtiyse sayaçları sıfırla ──────────
  // Çağrı yeri opsiyonel; kullanıcı premium'a geçince sayaçları temizlemek
  // istersek (örn. premium iptali sonrası tekrar trial vermemek için
  // sıfırlamayız) ya da temizleriz — bu fonksiyon sadece olanağı sunar.

  Future<void> resetMessages() async {
    await _db.setInt(key: LocalDbKeys.trialMessagesUsed, value: 0);
  }

  Future<void> resetVoiceSeconds() async {
    await _db.setInt(key: LocalDbKeys.trialVoiceSecondsUsed, value: 0);
  }

  // ── Görüntülü deneme (toplam 60 sn, non-premium) ───────────────────────

  Future<int> videoTrialSecondsUsed() async {
    return (await _db.getInt(key: LocalDbKeys.trialVideoSecondsUsed)) ?? 0;
  }

  Future<int> videoTrialSecondsRemaining() async {
    final used = await videoTrialSecondsUsed();
    final remaining = videoTrialSecondLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// Premium değilse ve henüz 60 sn dolmadıysa true.
  Future<bool> canAccessVideoTrial() async {
    return (await videoTrialSecondsRemaining()) > 0;
  }

  /// Görüntülü deneme oturumu bittiğinde veya erken kapatıldığında çağrılır.
  Future<void> addVideoTrialSeconds(int seconds) async {
    if (seconds <= 0) return;
    final used = await videoTrialSecondsUsed();
    final next = (used + seconds).clamp(0, videoTrialSecondLimit);
    await _db.setInt(key: LocalDbKeys.trialVideoSecondsUsed, value: next);
  }
}
