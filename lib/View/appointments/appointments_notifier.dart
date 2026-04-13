/// lib/features/appointments/appointments_notifier.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/repo/appointment_repo.dart';
import 'package:mindcoach/core/repo/consultant_repo.dart';
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
  Timer? _timer;
  AppointmentRepo? _appointmentRepo;
  ConsultantRepo? _consultantRepo;

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
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    // İlk state - boş map ile başla, loading true
    final initialState = AppointmentsState(
      appointments: {},
      isLoading: true,
    );

    // ✅ ÖNEMLİ: provider build sırasında state değiştirmiyoruz
    // API'den randevuları çek ve countdown'u widget build bittikten sonra başlatıyoruz.
    log("🏗️ AppointmentsNotifier.build() çağrıldı");
    Future(() {
      if (!ref.mounted) {
        log("⚠️ Ref mounted değil, randevular yüklenemiyor");
        return;
      }
      log("✅ Ref mounted, randevular yükleniyor...");
      _loadAppointmentsFromAPI();
      _startCountdown();
    });

    return initialState;
  }

  /// API'den tüm randevuları yükle
  Future<void> _loadAppointmentsFromAPI() async {
    log("🚀 _loadAppointmentsFromAPI başlatıldı");
    
    final userId = ref.read(AllProviders.userProvider)?.id;
    log("👤 User ID: $userId");
    
    if (userId == null) {
      log("❌ User ID null, randevular yüklenemiyor");
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Loading başladı
      log("⏳ Randevular yükleniyor...");
      state = state.copyWith(isLoading: true);
      
      log("📞 appointmentRepo.getAllAppointments çağrılıyor...");
      final appointmentsList = await appointmentRepo.getAllAppointments(userId);
      log("📥 getAllAppointments sonucu: ${appointmentsList.length} randevu");
      
      if (appointmentsList.isEmpty) {
        log("ℹ️ API'den randevu bulunamadı");
        state = state.copyWith(isLoading: false);
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
          final status = appointmentData["status"] as String?;
          final appointmentId = appointmentData["id"] as int?;
          
          // Debug: Raw data logla
          log("📋 Raw appointment data: id=$appointmentId, appointment_date=$appointmentDateStr (type: ${appointmentDateStr.runtimeType}), consultant_id=$consultantId, status=$status");
          
          // NOT: İptal edilmiş randevuları da yükle (3 saniye geri alma için)
          // Calendar screen'de filtreleme yapılacak
          
          // appointment_date null veya boş mu kontrol et
          if (appointmentDateStr == null || appointmentDateStr.toString().trim().isEmpty) {
            log("⚠️ appointment_date null veya boş, randevu atlandı: consultantId=$consultantId");
            continue;
          }
          
          // String'e çevir (eğer değilse)
          final dateStr = appointmentDateStr.toString().trim();
          
          try {
            // ISO format tarihini parse et ve local timezone'a çevir
            final appointmentDateTime = DateTime.parse(dateStr).toLocal();
            log("✅ Tarih parse edildi: $dateStr -> $appointmentDateTime (local)");
            
            // Sadece tarih kısmını al (saat bilgisi olmadan) - map key için
            final dateOnly = DateTime(appointmentDateTime.year, appointmentDateTime.month, appointmentDateTime.day);
            
            // Consultant ID'den specialist name'i bul
            final specialistName = await _getSpecialistNameFromConsultantId(consultantId ?? 0, consultants);
            
            // Consultant bilgisini bul (job için)
            String? consultantJob;
            if (consultants != null && consultantId != null && consultants.isNotEmpty) {
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
              topicKey: 'feelingGood', // Varsayılan topic (API'de topic bilgisi yoksa)
              appointmentDateTime: appointmentDateTime, // Tam tarih + saat
              status: status ?? 'scheduled', // Status bilgisi
              consultantId: consultantId, // Consultant ID
              job: consultantJob, // Consultant'ın görevi
              appointmentId: appointmentId, // Appointment ID (iptal/geri alma için)
            );
            
            // Map'e ekle
            if (appointmentsMap.containsKey(dateOnly)) {
              appointmentsMap[dateOnly]!.add(appointmentInfo);
            } else {
              appointmentsMap[dateOnly] = [appointmentInfo];
            }
            
            log("✅ Randevu eklendi: dateOnly=$dateOnly, appointmentDateTime=$appointmentDateTime, consultantId=$consultantId");
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
      state = state.copyWith(
        appointments: appointmentsMap,
        isLoading: false,
      );
      
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
  Future<String> _getSpecialistNameFromConsultantId(int consultantId, List<ConsultantModel>? consultants) async {
    try {
      if (consultants != null && consultants.isNotEmpty) {
        // Consultant ID'ye göre bul
        try {
          final consultant = consultants.firstWhere(
            (c) => c.id == consultantId,
            orElse: () => consultants.first, // Fallback: ilk consultant
          );
          
          // Consultant'ın names map'inden İngilizce ismini al (key olarak kullanılacak)
          final nameKey = consultant.names['en'] ?? consultant.names.values.first ?? 'aura';
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

        if (bestDateTime == null || appointmentDateTime.isBefore(bestDateTime)) {
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
    final newMap = Map<DateTime, List<AppointmentInfo>>.from(state.appointments);

    // appointmentDateTime varsa onu kullan, yoksa dateTime kullan
    final appointmentDateTime = info.appointmentDateTime ?? dateTime;
    // Sadece tarih kısmını al (saat bilgisi olmadan) - map key için
    final dateOnly = DateTime(appointmentDateTime.year, appointmentDateTime.month, appointmentDateTime.day);

    // Aynı randevu zaten var mı kontrol et (duplicate önleme)
    final existingList = newMap[dateOnly] ?? [];
    final isDuplicate = existingList.any((existingInfo) => 
      existingInfo.consultantId == info.consultantId &&
      existingInfo.appointmentDateTime?.isAtSameMomentAs(appointmentDateTime) == true
    );

    if (!isDuplicate) {
      final list = List<AppointmentInfo>.from(existingList);
      list.add(info);
      newMap[dateOnly] = list;
      
      state = state.copyWith(appointments: newMap);
      log("✅ Randevu eklendi: dateOnly=$dateOnly, appointmentDateTime=$appointmentDateTime, consultantId=${info.consultantId}");
    } else {
      log("⚠️ Duplicate randevu atlandı: dateOnly=$dateOnly, consultantId=${info.consultantId}");
    }

    _tickCountdown();
  }

  /// Randevuları yeniden yükle (public method)
  Future<void> refresh() async {
    await _loadAppointmentsFromAPI();
  }
}

final appointmentsProvider =
NotifierProvider<AppointmentsNotifier, AppointmentsState>(
  AppointmentsNotifier.new,
);
