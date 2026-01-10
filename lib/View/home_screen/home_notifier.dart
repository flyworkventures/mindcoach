import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/repo/appointment_repo.dart';
import 'package:mindcoach/core/repo/consultant_repo.dart';
import 'package:mindcoach/core/repo/mood_repo.dart';
import 'package:mindcoach/View/appointments/appointments_notifier.dart';
import 'package:mindcoach/Riverpod/providers/user_provider.dart';
import 'domain/mood.dart';

class HomeState {
  final int quickActionPageIndex;
  final Mood? selectedMood;
  final bool hasTodayMood; // Bugünkü mood kaydı var mı?
  final bool hasUpcomingAppointment; // Yaklaşan randevu var mı?

  const HomeState({
    this.quickActionPageIndex = 0,
    this.selectedMood,
    this.hasTodayMood = false,
    this.hasUpcomingAppointment = false,
  });

  HomeState copyWith({
    int? quickActionPageIndex,
    Mood? selectedMood,
    bool? hasTodayMood,
    bool? hasUpcomingAppointment,
  }) {
    return HomeState(
      quickActionPageIndex: quickActionPageIndex ?? this.quickActionPageIndex,
      selectedMood: selectedMood ?? this.selectedMood,
      hasTodayMood: hasTodayMood ?? this.hasTodayMood,
      hasUpcomingAppointment: hasUpcomingAppointment ?? this.hasUpcomingAppointment,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  MoodRepo? _moodRepo;
  AppointmentRepo? _appointmentRepo;

  MoodRepo get moodRepo {
    _moodRepo ??= MoodRepo(ref);
    return _moodRepo!;
  }

  AppointmentRepo get appointmentRepo {
    _appointmentRepo ??= AppointmentRepo(ref);
    return _appointmentRepo!;
  }

  @override
  HomeState build() {
    // Sayfa açıldığında bugünkü mood'u ve yaklaşan randevuyu kontrol et
    Future(() {
      if (!ref.mounted) return;
      _checkTodayMood();
      _checkUpcomingAppointment();
    });
    
    return const HomeState();
  }

  /// Bugünkü mood kaydını kontrol et
  Future<void> _checkTodayMood() async {
    final userId = ref.read(userProvider)?.id;
    if (userId == null) return;

    try {
      final todayMood = await moodRepo.getTodayMood(userId);
      if (todayMood != null) {
        // Bugünkü mood var
        state = state.copyWith(hasTodayMood: true);
      } else {
        // Bugünkü mood yok
        state = state.copyWith(hasTodayMood: false);
      }
    } catch (e) {
      // Hata durumunda varsayılan olarak mood yok say
      state = state.copyWith(hasTodayMood: false);
    }
  }

  void setQuickActionPageIndex(int index) {
    state = state.copyWith(quickActionPageIndex: index);
  }

  /// Mood seçildiğinde API'ye kaydet
  Future<void> setMood(Mood mood) async {
    final userId = ref.read(userProvider)?.id;
    if (userId == null) return;

    // Mood değerini sayıya çevir
    final moodValue = _moodToNumber(mood);
    
    // Bugünkü tarihi YYYY-MM-DD formatında al (local timezone)
    final today = DateTime.now();
    final dateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    try {
      // API'ye kaydet
      final success = await moodRepo.createOrUpdateMood(
        date: dateString,
        mood: moodValue,
      );

      if (success) {
        // Başarılı ise state'i güncelle ve bugünkü mood'u tekrar kontrol et
        state = state.copyWith(
          selectedMood: mood,
          hasTodayMood: true, // Artık bugünkü mood var
        );
        
        // State güncellendikten sonra tekrar kontrol et (güvenlik için)
        await _checkTodayMood();
      }
    } catch (e) {
      // Hata durumunda sadece state'i güncelle (UI'da gösterilir)
      state = state.copyWith(selectedMood: mood);
    }
  }

  /// Mood enum'ını sayıya çevir
  int _moodToNumber(Mood mood) {
    switch (mood) {
      case Mood.great:
        return 5;
      case Mood.good:
        return 4;
      case Mood.neutral:
        return 3;
      case Mood.bad:
        return 2;
      case Mood.terrible:
        return 1;
    }
  }

  /// Yaklaşan randevuyu kontrol et ve AppointmentsNotifier'a ekle
  Future<void> _checkUpcomingAppointment() async {
    final userId = ref.read(userProvider)?.id;
    if (userId == null) return;

    try {
      final upcomingAppointment = await appointmentRepo.getUpcomingAppointment(userId);
      if (upcomingAppointment != null) {
        // Yaklaşan randevu var
        state = state.copyWith(hasUpcomingAppointment: true);
        
        // API'den gelen randevuyu AppointmentsNotifier'a ekle
        try {
          final appointmentDateStr = upcomingAppointment["appointment_date"] as String?;
          final consultantId = upcomingAppointment["consultant_id"] as int?;
          
          if (appointmentDateStr != null) {
            // ISO format tarihini parse et
            final appointmentDate = DateTime.parse(appointmentDateStr).toLocal();
            
            // Consultant ID'den specialist name'i bul
            final specialistName = await _getSpecialistNameFromConsultantId(consultantId ?? 0);
            
            // Consultant bilgisini bul (job için)
            String? consultantJob;
            if (consultantId != null) {
              final consultantRepo = ConsultantRepo(ref);
              final consultants = await consultantRepo.getAllConsultant();
              if (consultants != null && consultants.isNotEmpty) {
                try {
                  final consultant = consultants.firstWhere(
                    (c) => c.id == consultantId,
                    orElse: () => consultants.first, // Fallback: ilk consultant
                  );
                  consultantJob = consultant.job;
                } catch (e) {
                  // Consultant bulunamadı
                  log("⚠️ Consultant job bulunamadı: $e");
                }
              }
            }
            
            // AppointmentInfo oluştur
            final appointmentInfo = AppointmentInfo(
              specialistName: specialistName,
              topicKey: 'feelingGood', // Varsayılan topic
              appointmentDateTime: appointmentDate, // Tam tarih + saat
              status: upcomingAppointment["status"] as String? ?? 'scheduled', // Status bilgisi
              consultantId: consultantId, // Consultant ID
              job: consultantJob, // Consultant'ın görevi
            );
            
            // AppointmentsNotifier'a ekle
            ref.read(appointmentsProvider.notifier).upsertAppointment(appointmentDate, appointmentInfo);
          }
        } catch (e) {
          // Parse hatası - sadece state'i güncelle
          state = state.copyWith(hasUpcomingAppointment: true);
        }
      } else {
        // Yaklaşan randevu yok
        state = state.copyWith(hasUpcomingAppointment: false);
      }
    } catch (e) {
      // Hata durumunda varsayılan olarak randevu yok say
      state = state.copyWith(hasUpcomingAppointment: false);
    }
  }

  /// Consultant ID'den specialist name'i döndür
  Future<String> _getSpecialistNameFromConsultantId(int consultantId) async {
    try {
      // ConsultantRepo'dan consultant listesini al
      final consultantRepo = ConsultantRepo(ref);
      final consultants = await consultantRepo.getAllConsultant();
      
      if (consultants != null && consultants.isNotEmpty) {
        // Consultant ID'ye göre bul
        final consultant = consultants.firstWhere(
          (c) => c.id == consultantId,
          orElse: () => consultants.first,
        );
        
        // Consultant'ın names map'inden İngilizce ismini al (key olarak kullanılacak)
        // Varsayılan olarak 'en' key'ini kullan, yoksa ilk key'i al
        final nameKey = consultant.names['en'] ?? consultant.names.values.first ?? 'aura';
        // Name key'ini lowercase'e çevir (specialist name formatı için)
        return nameKey.toString().toLowerCase();
      }
    } catch (e) {
      // Hata durumunda basit mapping kullan
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

  MapEntry<DateTime, AppointmentInfo>? findNextAppointment() {
    return ref.read(appointmentsProvider.notifier).findNextAppointment();
  }

  void addAppointment(DateTime dateTime, AppointmentInfo info) {
    ref.read(appointmentsProvider.notifier).upsertAppointment(dateTime, info);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
