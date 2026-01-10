/// lib/features/appointments/appointments_notifier.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/repo/appointment_repo.dart';
import 'package:mindcoach/core/repo/consultant_repo.dart';
import 'package:mindcoach/models/consultant_model.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart';

class AppointmentsState {
  final Map<DateTime, List<AppointmentInfo>> appointments;

  final String remainingDays;
  final String remainingHours;
  final String remainingMinutes;
  final String remainingSeconds;

  const AppointmentsState({
    required this.appointments,
    this.remainingDays = '00',
    this.remainingHours = '00',
    this.remainingMinutes = '00',
    this.remainingSeconds = '00',
  });

  AppointmentsState copyWith({
    Map<DateTime, List<AppointmentInfo>>? appointments,
    String? remainingDays,
    String? remainingHours,
    String? remainingMinutes,
    String? remainingSeconds,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
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

    // İlk state - boş map ile başla
    final initialState = AppointmentsState(appointments: {});

    // ✅ ÖNEMLİ: provider build sırasında state değiştirmiyoruz
    // API'den randevuları çek ve countdown'u widget build bittikten sonra başlatıyoruz.
    Future(() {
      if (!ref.mounted) return;
      _loadAppointmentsFromAPI();
      _startCountdown();
    });

    return initialState;
  }

  /// API'den tüm randevuları yükle
  Future<void> _loadAppointmentsFromAPI() async {
    final userId = ref.read(userProvider)?.id;
    if (userId == null) return;

    try {
      final appointmentsList = await appointmentRepo.getAllAppointments(userId);
      
      if (appointmentsList.isEmpty) {
        log("ℹ️ API'den randevu bulunamadı");
        return;
      }

      // Consultant listesini al (specialist name mapping için)
      final consultants = await consultantRepo.getAllConsultant();
      
      // API'den gelen randevuları Map<DateTime, List<AppointmentInfo>> formatına çevir
      final appointmentsMap = <DateTime, List<AppointmentInfo>>{};
      
      for (var appointmentData in appointmentsList) {
        try {
          final appointmentDateStr = appointmentData["appointment_date"] as String?;
          final consultantId = appointmentData["consultant_id"] as int?;
          final status = appointmentData["status"] as String?;
          
          // İptal edilmiş randevuları atla
          if (status == 'cancelled') continue;
          
          if (appointmentDateStr != null) {
            // ISO format tarihini parse et ve local timezone'a çevir
            final appointmentDateTime = DateTime.parse(appointmentDateStr).toLocal();
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
            
            // AppointmentInfo oluştur (tam tarih + saat, status, consultantId ve job ile)
            final appointmentInfo = AppointmentInfo(
              specialistName: specialistName,
              topicKey: 'feelingGood', // Varsayılan topic (API'de topic bilgisi yoksa)
              appointmentDateTime: appointmentDateTime, // Tam tarih + saat
              status: status ?? 'scheduled', // Status bilgisi
              consultantId: consultantId, // Consultant ID
              job: consultantJob, // Consultant'ın görevi
            );
            
            // Map'e ekle
            if (appointmentsMap.containsKey(dateOnly)) {
              appointmentsMap[dateOnly]!.add(appointmentInfo);
            } else {
              appointmentsMap[dateOnly] = [appointmentInfo];
            }
          }
        } catch (e) {
          log("⚠️ Randevu parse hatası: $e");
        }
      }
      
      // State'i güncelle
      state = state.copyWith(appointments: appointmentsMap);
      log("✅ ${appointmentsMap.length} gün için ${appointmentsList.length} randevu yüklendi");
      
      // Countdown'u güncelle
      _tickCountdown();
    } catch (e) {
      log("❌ _loadAppointmentsFromAPI hatası: $e");
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

    // Tüm randevuları kontrol et ve en yakın gelecek randevuyu bul
    for (final entry in map.entries) {
      final infos = entry.value;
      if (infos.isEmpty) continue;

      // Her bir AppointmentInfo için appointmentDateTime'ı kontrol et
      for (final info in infos) {
        // appointmentDateTime kullan (tam tarih + saat)
        final appointmentDateTime = info.appointmentDateTime;
        if (appointmentDateTime == null) continue;
        
        // Sadece gelecekteki randevuları kontrol et
        if (!appointmentDateTime.isAfter(now)) continue;
        
        // İptal edilmiş randevuları atla
        if (info.status?.toLowerCase() == 'cancelled') continue;

        // En yakın randevuyu bul
        if (bestDateTime == null || appointmentDateTime.isBefore(bestDateTime)) {
          bestDateTime = appointmentDateTime;
          bestInfo = info;
        }
      }
    }

    if (bestDateTime == null || bestInfo == null) return null;
    return MapEntry(bestDateTime, bestInfo);
  }

  void upsertAppointment(DateTime dateTime, AppointmentInfo info) {
    final newMap = Map<DateTime, List<AppointmentInfo>>.from(state.appointments);

    final list = List<AppointmentInfo>.from(newMap[dateTime] ?? const []);
    list.add(info);
    newMap[dateTime] = list;

    state = state.copyWith(appointments: newMap);

    _tickCountdown();
  }
}

final appointmentsProvider =
NotifierProvider<AppointmentsNotifier, AppointmentsState>(
  AppointmentsNotifier.new,
);
