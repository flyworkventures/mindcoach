/// lib/features/appointments/appointments_notifier.dart
library;

import 'dart:async';
import 'dart:developer';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Services/NotificationsService/local_notification_service.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/repo/appointment_repo.dart';
import 'package:mindcoach/core/repo/consultant_repo.dart';
import 'package:mindcoach/l10n/app_localizations.dart';
import 'package:mindcoach/models/consultant_model.dart';

class AppointmentsState {
  final Map<DateTime, List<AppointmentInfo>> appointments;
  final bool isLoading; // Randevular yükleniyor mu?

  final String remainingDays;
  final String remainingHours;
  final String remainingMinutes;
  final String remainingSeconds;

  const AppointmentsState({
    required this.appointments,
    this.isLoading = true, // Başlangıçta loading
    this.remainingDays = '00',
    this.remainingHours = '00',
    this.remainingMinutes = '00',
    this.remainingSeconds = '00',
  });

  AppointmentsState copyWith({
    Map<DateTime, List<AppointmentInfo>>? appointments,
    bool? isLoading,
    String? remainingDays,
    String? remainingHours,
    String? remainingMinutes,
    String? remainingSeconds,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      remainingDays: remainingDays ?? this.remainingDays,
      remainingHours: remainingHours ?? this.remainingHours,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class AppointmentsNotifier extends Notifier<AppointmentsState> {
  static const String _appointmentReminderPayloadPrefix = 'appointment_reminder_30m:';
  Timer? _timer;
  AppointmentRepo? _appointmentRepo;
  ConsultantRepo? _consultantRepo;
  int? _activeUserId;
  /// build() her seferinde boş map dönmesin diye son bilinen liste.
  Map<DateTime, List<AppointmentInfo>>? _cachedAppointments;

  AppointmentRepo get appointmentRepo {
    _appointmentRepo ??= AppointmentRepo(ref);
    return _appointmentRepo!;
  }

  ConsultantRepo get consultantRepo {
    _consultantRepo ??= ConsultantRepo(ref);
    return _consultantRepo!;
  }

  @override
  AppointmentsState build() {
    final userId = ref.watch(AllProviders.userProvider.select((u) => u?.id));

    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    final userChanged = _activeUserId != userId;
    if (userChanged) {
      _activeUserId = userId;
      _timer?.cancel();
      _timer = null;
      _cachedAppointments = null;
    }

    // ✅ ÖNEMLİ: provider build sırasında state değiştirmiyoruz
    // API'den randevuları çek ve countdown'u widget build bittikten sonra başlatıyoruz.
    log("🏗️ AppointmentsNotifier.build() çağrıldı");
    Future(() {
      if (!ref.mounted) {
        log("⚠️ Ref mounted değil, randevular yüklenemiyor");
        return;
      }
      if (userId == null) {
        log("ℹ️ Kullanici yok, randevu state sifirlandi");
        return;
      }
      log("✅ Ref mounted, randevular yükleniyor...");
      _loadAppointmentsFromAPI(silent: _cachedAppointments != null);
      _startCountdown();
    });

    // Rebuild'de boş map dönme — önceki cache varsa anında göster
    if (_cachedAppointments != null && !userChanged) {
      return AppointmentsState(
        appointments: _cachedAppointments!,
        isLoading: false,
      );
    }

    return AppointmentsState(appointments: {}, isLoading: true);
  }

  /// API'den tüm randevuları yükle
  /// [silent] true ise mevcut listeyi silmeden arka planda yeniler (anlık UI için).
  Future<void> _loadAppointmentsFromAPI({bool silent = false}) async {
    log("🚀 _loadAppointmentsFromAPI başlatıldı (silent=$silent)");

    final userId = ref.read(AllProviders.userProvider)?.id;
    log("👤 User ID: $userId");

    if (userId == null) {
      log("❌ User ID null, randevular yüklenemiyor");
      state = state.copyWith(isLoading: false, appointments: {});
      return;
    }

    try {
      final hasExisting = state.appointments.isNotEmpty;
      // Soft refresh: elde veri varken boş ekran göstermemek için loading gösterme
      if (!silent && !hasExisting) {
        log("⏳ Randevular yükleniyor...");
        state = state.copyWith(isLoading: true);
      }

      log("📞 appointmentRepo.getAllAppointments çağrılıyor...");
      final appointmentsList = await appointmentRepo.getAllAppointments(userId);
      log("📥 getAllAppointments sonucu: ${appointmentsList.length} randevu");

      if (appointmentsList.isEmpty) {
        log("ℹ️ API'den randevu bulunamadı — liste temizleniyor");
        _cachedAppointments = {};
        state = state.copyWith(appointments: {}, isLoading: false);
        unawaited(_syncThirtyMinuteReminderNotifications({}));
        _tickCountdown();
        return;
      }

      // Consultant listesini al (specialist name mapping için)
      final consultants = await consultantRepo.getAllConsultant();

      // API'den gelen randevuları Map<DateTime, List<AppointmentInfo>> formatına çevir
      final appointmentsMap = <DateTime, List<AppointmentInfo>>{};

      for (var appointmentData in appointmentsList) {
        try {
          final appointmentDateStr = appointmentData["appointment_date"];
          final consultantId = appointmentData["consultant_id"] as int?;
          final rawStatus = appointmentData["status"];
          final status = rawStatus?.toString().trim().toLowerCase();
          final appointmentId = appointmentData["id"] as int?;

          // Debug: Raw data logla
          log(
            "📋 Raw appointment data: id=$appointmentId, appointment_date=$appointmentDateStr (type: ${appointmentDateStr.runtimeType}), consultant_id=$consultantId, status=$status",
          );

          // NOT: İptal edilmiş randevuları da yükle (3 saniye geri alma için)
          // Calendar screen'de filtreleme yapılacak

          // appointment_date null veya boş mu kontrol et
          if (appointmentDateStr == null ||
              appointmentDateStr.toString().trim().isEmpty) {
            log(
              "⚠️ appointment_date null veya boş, randevu atlandı: consultantId=$consultantId",
            );
            continue;
          }

          // String'e çevir (eğer değilse)
          final dateStr = appointmentDateStr.toString().trim();

          try {
            // ISO format tarihini parse et ve local timezone'a çevir
            final appointmentDateTime = DateTime.parse(dateStr).toLocal();
            log(
              "✅ Tarih parse edildi: $dateStr -> $appointmentDateTime (local)",
            );

            // Sadece tarih kısmını al (saat bilgisi olmadan) - map key için
            final dateOnly = DateTime(
              appointmentDateTime.year,
              appointmentDateTime.month,
              appointmentDateTime.day,
            );

            // Consultant ID'den specialist name'i bul
            final specialistName = await _getSpecialistNameFromConsultantId(
              consultantId ?? 0,
              consultants,
            );

            // Consultant bilgisini bul (job için)
            String? consultantJob;
            if (consultants != null &&
                consultantId != null &&
                consultants.isNotEmpty) {
              try {
                final consultant = consultants.firstWhere(
                  (c) => c.id == consultantId,
                  orElse: () => consultants.first, // Fallback: ilk consultant
                );
                consultantJob = consultant.job;
              } catch (e) {
                log("⚠️ Consultant job bulunamadı: $e");
              }
            }

            // AppointmentInfo oluştur (tam tarih + saat, status, consultantId, job ve appointmentId ile)
            final appointmentInfo = AppointmentInfo(
              specialistName: specialistName,
              topicKey:
                  'feelingGood', // Varsayılan topic (API'de topic bilgisi yoksa)
              appointmentDateTime: appointmentDateTime, // Tam tarih + saat
              status: (status != null && status.isNotEmpty)
                  ? status
                  : 'scheduled', // Status bilgisi
              consultantId: consultantId, // Consultant ID
              job: consultantJob, // Consultant'ın görevi
              appointmentId:
                  appointmentId, // Appointment ID (iptal/geri alma için)
            );

            // Map'e ekle
            if (appointmentsMap.containsKey(dateOnly)) {
              appointmentsMap[dateOnly]!.add(appointmentInfo);
            } else {
              appointmentsMap[dateOnly] = [appointmentInfo];
            }

            log(
              "✅ Randevu eklendi: dateOnly=$dateOnly, appointmentDateTime=$appointmentDateTime, consultantId=$consultantId",
            );
          } catch (e, stackTrace) {
            log("❌ Tarih parse hatası: $e");
            log("❌ Stack trace: $stackTrace");
            log("❌ Raw date string: $dateStr");
          }
        } catch (e, stackTrace) {
          log("❌ Randevu işleme hatası: $e");
          log("❌ Stack trace: $stackTrace");
        }
      }

      // State'i güncelle (loading'i false yap)
      _cachedAppointments = appointmentsMap;
      state = state.copyWith(appointments: appointmentsMap, isLoading: false);
      unawaited(_syncThirtyMinuteReminderNotifications(appointmentsMap));

      // Randevu istatistiklerini hesapla
      final now = DateTime.now();
      int totalAppointments = 0;
      int pastAppointments = 0;
      int upcomingAppointments = 0;

      for (final entry in appointmentsMap.entries) {
        for (final info in entry.value) {
          totalAppointments++;
          final appointmentDateTime = info.appointmentDateTime ?? entry.key;
          if (appointmentDateTime.isBefore(now)) {
            pastAppointments++;
          } else {
            upcomingAppointments++;
          }
        }
      }

      log("✅ RANDEVU İSTATİSTİKLERİ:");
      log("   📊 Toplam randevu: $totalAppointments");
      log("   📅 Geçmiş randevu: $pastAppointments");
      log("   🔮 Gelecek randevu: $upcomingAppointments");
      log("   📆 ${appointmentsMap.length} farklı gün için randevu var");
      log("   ✅ ${appointmentsList.length} randevu API'den yüklendi");

      // Countdown'u güncelle
      _tickCountdown();
    } catch (e) {
      log("❌ _loadAppointmentsFromAPI hatası: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  /// Consultant ID'den specialist name'i döndür
  Future<String> _getSpecialistNameFromConsultantId(
    int consultantId,
    List<ConsultantModel>? consultants,
  ) async {
    try {
      if (consultants != null && consultants.isNotEmpty) {
        // Consultant ID'ye göre bul
        try {
          final consultant = consultants.firstWhere(
            (c) => c.id == consultantId,
            orElse: () => consultants.first, // Fallback: ilk consultant
          );

          // Consultant'ın names map'inden İngilizce ismini al (key olarak kullanılacak)
          final nameKey =
              consultant.names['en'] ?? consultant.names.values.first ?? 'aura';
          // Name key'ini lowercase'e çevir (specialist name formatı için)
          return nameKey.toString().toLowerCase();
        } catch (e) {
          log("⚠️ Consultant ID $consultantId bulunamadı");
        }
      }
    } catch (e) {
      log("⚠️ Consultant name bulunamadı: $e");
    }

    // Fallback: Basit mapping
    switch (consultantId) {
      case 1:
        return 'aura';
      case 2:
        return 'zen';
      case 3:
        return 'elara';
      case 4:
        return 'orion';
      case 5:
        return 'cyra';
      default:
        return 'aura'; // Varsayılan
    }
  }

  // ---------------- COUNTDOWN ---------------- //

  void _startCountdown() {
    if (_timer != null) return;

    _tickCountdown();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCountdown();
    });
  }

  void _tickCountdown() {
    final next = findNextAppointment();

    if (next == null) {
      state = state.copyWith(
        remainingDays: '00',
        remainingHours: '00',
        remainingMinutes: '00',
        remainingSeconds: '00',
      );
      return;
    }

    final target = next.key;
    final now = DateTime.now();

    if (!target.isAfter(now)) {
      state = state.copyWith(
        remainingDays: '00',
        remainingHours: '00',
        remainingMinutes: '00',
        remainingSeconds: '00',
      );
      return;
    }

    final diff = target.difference(now);
    final totalSeconds = diff.inSeconds;

    final days = totalSeconds ~/ (24 * 60 * 60);
    final hours = (totalSeconds % (24 * 60 * 60)) ~/ (60 * 60);
    final minutes = (totalSeconds % (60 * 60)) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int v) => v.toString().padLeft(2, '0');

    state = state.copyWith(
      remainingDays: two(days),
      remainingHours: two(hours),
      remainingMinutes: two(minutes),
      remainingSeconds: two(seconds),
    );
  }

  MapEntry<DateTime, AppointmentInfo>? findNextAppointment() {
    final now = DateTime.now();
    final map = state.appointments;

    DateTime? bestDateTime;
    AppointmentInfo? bestInfo;

    for (final entry in map.entries) {
      final infos = entry.value;
      if (infos.isEmpty) continue;

      for (final info in infos) {
        final appointmentDateTime = info.appointmentDateTime;
        if (appointmentDateTime == null) continue;

        if (!appointmentDateTime.isAfter(now)) continue;

        if (info.status?.toLowerCase() == 'cancelled') continue;

        if (bestDateTime == null ||
            appointmentDateTime.isBefore(bestDateTime)) {
          bestDateTime = appointmentDateTime;
          bestInfo = info;
        }
      }
    }

    return (bestDateTime != null && bestInfo != null)
        ? MapEntry(bestDateTime, bestInfo)
        : null;
  }

  void upsertAppointment(DateTime dateTime, AppointmentInfo info) {
    final newMap = Map<DateTime, List<AppointmentInfo>>.from(
      state.appointments,
    );

    // appointmentDateTime varsa onu kullan, yoksa dateTime kullan
    final appointmentDateTime = info.appointmentDateTime ?? dateTime;
    // Sadece tarih kısmını al (saat bilgisi olmadan) - map key için
    final dateOnly = DateTime(
      appointmentDateTime.year,
      appointmentDateTime.month,
      appointmentDateTime.day,
    );

    // Aynı randevu zaten var mı kontrol et (duplicate önleme)
    final existingList = newMap[dateOnly] ?? [];
    final isDuplicate = existingList.any(
      (existingInfo) =>
          existingInfo.consultantId == info.consultantId &&
          existingInfo.appointmentDateTime?.isAtSameMomentAs(
                appointmentDateTime,
              ) ==
              true,
    );

    if (!isDuplicate) {
      final list = List<AppointmentInfo>.from(existingList);
      list.add(info);
      newMap[dateOnly] = list;

      _cachedAppointments = newMap;
      state = state.copyWith(appointments: newMap, isLoading: false);
      log(
        "✅ Randevu eklendi: dateOnly=$dateOnly, appointmentDateTime=$appointmentDateTime, consultantId=${info.consultantId}",
      );
    } else {
      log(
        "⚠️ Duplicate randevu atlandı: dateOnly=$dateOnly, consultantId=${info.consultantId}",
      );
    }

    _tickCountdown();
    unawaited(_syncThirtyMinuteReminderNotifications(newMap));
  }

  /// Randevuları yeniden yükle (public method).
  /// [silent] true: mevcut listeyi koruyarak arka planda yenile.
  Future<void> refresh({bool silent = true}) async {
    await _loadAppointmentsFromAPI(silent: silent);
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// UI'da anında kaldırmak için yerel state güncellemesi.
  void _removeAppointmentLocally(int appointmentId) {
    final newMap = <DateTime, List<AppointmentInfo>>{};
    for (final entry in state.appointments.entries) {
      final filtered = entry.value
          .where((a) => a.appointmentId != appointmentId)
          .toList();
      if (filtered.isNotEmpty) {
        newMap[entry.key] = filtered;
      }
    }
    state = state.copyWith(appointments: newMap);
    _cachedAppointments = newMap;
    _tickCountdown();
    unawaited(_syncThirtyMinuteReminderNotifications(newMap));
  }

  /// UI'da anında yeni tarihe taşımak için yerel state güncellemesi.
  void _rescheduleAppointmentLocally(int appointmentId, DateTime newDateTime) {
    AppointmentInfo? moved;
    final newMap = <DateTime, List<AppointmentInfo>>{};

    for (final entry in state.appointments.entries) {
      final remaining = <AppointmentInfo>[];
      for (final info in entry.value) {
        if (info.appointmentId == appointmentId) {
          moved = info.copyWith(
            appointmentDateTime: newDateTime,
            status: info.status?.toLowerCase() == 'cancelled'
                ? 'pending'
                : info.status,
          );
        } else {
          remaining.add(info);
        }
      }
      if (remaining.isNotEmpty) {
        newMap[entry.key] = remaining;
      }
    }

    if (moved != null) {
      final key = _dateOnly(newDateTime);
      newMap.putIfAbsent(key, () => []).add(moved);
    }

    state = state.copyWith(appointments: newMap);
    _cachedAppointments = newMap;
    _tickCountdown();
    unawaited(_syncThirtyMinuteReminderNotifications(newMap));
  }

  /// Randevuyu kalıcı olarak sil; önce UI'dan kaldır, sonra API + senkron.
  Future<bool> deleteAppointment(int appointmentId) async {
    _removeAppointmentLocally(appointmentId);

    final ok = await appointmentRepo.deleteAppointment(appointmentId);
    await _loadAppointmentsFromAPI(silent: true);
    return ok;
  }

  /// Randevuyu yeni tarihe ertele; önce UI'ı güncelle, sonra API + senkron.
  Future<bool> rescheduleAppointment(
    int appointmentId,
    DateTime newDateTime,
  ) async {
    _rescheduleAppointmentLocally(appointmentId, newDateTime);

    final ok = await appointmentRepo.rescheduleAppointment(
      appointmentId,
      newDateTime,
    );
    await _loadAppointmentsFromAPI(silent: true);
    return ok;
  }

  int _reminderNotificationId(AppointmentInfo info, DateTime appointmentDateTime) {
    final int base = info.appointmentId ?? appointmentDateTime.millisecondsSinceEpoch;
    return 700000000 + (base % 100000000);
  }

  Future<void> _syncThirtyMinuteReminderNotifications(
    Map<DateTime, List<AppointmentInfo>> appointmentsMap,
  ) async {
    try {
      final service = LocalNotificationService();
      await service.initialize();

      final pending = await service.getPendingNotifications();
      for (final req in pending) {
        final payload = req.payload ?? '';
        if (payload.startsWith(_appointmentReminderPayloadPrefix)) {
          await service.cancelNotification(req.id);
        }
      }

      final now = DateTime.now();
      final localizations = _reminderLocalizations();
      for (final entry in appointmentsMap.entries) {
        for (final info in entry.value) {
          if (info.status?.toLowerCase() == 'cancelled') continue;
          final appointmentDateTime = info.appointmentDateTime ?? entry.key;
          final reminderTime = appointmentDateTime.subtract(
            const Duration(minutes: 30),
          );

          if (!reminderTime.isAfter(now)) continue;

          final id = _reminderNotificationId(info, appointmentDateTime);
          final specialistName = info.specialistName.isNotEmpty
              ? info.specialistName
              : localizations.appointmentReminderFallbackName;

          await service.scheduleOneTimeNotification(
            id: id,
            title: localizations.appointmentReminderTitle,
            body: localizations.appointmentReminderBody(specialistName),
            scheduledTime: reminderTime,
            payload: '$_appointmentReminderPayloadPrefix$id',
          );
        }
      }
    } catch (e) {
      log('⚠️ 30dk randevu bildirimi planlanamadi: $e');
    }
  }

  /// User'ın nativeLang'ına göre AppLocalizations instance'ı döndürür.
  /// Desteklenmeyen dil gelirse `en`'e düşer.
  AppLocalizations _reminderLocalizations() {
    final raw = (ref.read(AllProviders.userProvider)?.nativeLang ?? 'en')
        .toLowerCase()
        .trim();
    final code = raw.contains('-') ? raw.split('-').first : raw;
    final supported = AppLocalizations.supportedLocales
        .any((l) => l.languageCode == code);
    return lookupAppLocalizations(Locale(supported ? code : 'en'));
  }
}

final appointmentsProvider =
    NotifierProvider<AppointmentsNotifier, AppointmentsState>(
      AppointmentsNotifier.new,
    );
