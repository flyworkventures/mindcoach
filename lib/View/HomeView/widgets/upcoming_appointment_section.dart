import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;

import 'package:mindcoach/core/global_constants/month_strings.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/theme/app_colors.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/utils/time_format_utils.dart';

import 'package:mindcoach/View/appointments/appointments_notifier.dart';
import 'package:mindcoach/View/appointments/appointment_detail_screen.dart';
import 'package:mindcoach/View/specialists_screen/specialists_notifier.dart';

class UpcomingAppointmentSection extends ConsumerWidget {
  const UpcomingAppointmentSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    
    developer.log("🏠 UpcomingAppointmentSection.build() çağrıldı");
    
    // AppointmentsProvider'ı watch et (countdown ve randevu bilgisi için)
    final appointmentsState = ref.watch(appointmentsProvider);
    
    developer.log("📊 AppointmentsState: isLoading=${appointmentsState.isLoading}, appointments count=${appointmentsState.appointments.length}");
    
    // Randevular yükleniyor mu kontrol et
    if (appointmentsState.isLoading) {
      developer.log("⏳ Randevular yükleniyor, widget gizleniyor");
      // Randevular yükleniyor, loading göster veya gizle
      return const SizedBox.shrink();
    }
    
    // Randevular yüklendi ama boş mu kontrol et
    if (appointmentsState.appointments.isEmpty) {
      developer.log("⚠️ Randevular yüklendi ama boş");
      // Randevu yok
      return const SizedBox.shrink();
    }
    
    developer.log("🔍 Yaklaşan randevu aranıyor...");
    // AppointmentsNotifier'dan yaklaşan randevuyu bul
    final next = ref.read(appointmentsProvider.notifier).findNextAppointment();

    if (next == null) {
      developer.log("❌ Yaklaşan randevu bulunamadı");
      // Yaklaşan randevu yok
      return const SizedBox.shrink();
    }

    final DateTime date = next.key;
    final AppointmentInfo info = next.value;
    developer.log("✅ UpcomingAppointmentSection: Randevu bulundu, date = $date, remainingDays = ${appointmentsState.remainingDays}");

    return Padding(
      padding: EdgeInsets.only(left: 31.w, right: 31.w, top: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.upcomingMeetingTitle,
            style: GoogleFonts.quicksand(
              fontSize: 17.w,
              fontWeight: FontWeight.w700,
              height: 24.h / 17.w,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            l.timeRemainingTitle,
            style: GoogleFonts.quicksand(
              fontSize: 14.w,
              fontWeight: FontWeight.w500,
              height: 24.h / 14.w,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 15.h),
          _RemainingTimeCard(),
          SizedBox(height: 15.h),
          _AppointmentCard(date: date, info: info),
        ],
      ),
    );
  }
}

class _RemainingTimeCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(appointmentsProvider);

    return Container(
      width: 327.w,
      height: 84.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.w),
        boxShadow: [
          BoxShadow(
            color: Color(0xffC4E0FE).withValues(alpha: 0.4),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TimeItem(value: s.remainingDays, label: l.days),
          _Separator(),
          _TimeItem(value: s.remainingHours, label: l.hours),
          _Separator(),
          _TimeItem(value: s.remainingMinutes, label: l.minutes),
          _Separator(),
          _TimeItem(value: s.remainingSeconds, label: l.seconds),
        ],
      ),
    );
  }
}

class _TimeItem extends StatelessWidget {
  const _TimeItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 40.w,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0.0, -5.h),
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 11.w,
              fontWeight: FontWeight.w600,
              height: 1.0,
              color: AppColors.appointmentTimeLabel,
            ),
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0.0, -5.h),
      child: Text(
        ':',
        style: GoogleFonts.quicksand(
          fontSize: 20.w,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: AppColors.separatorGrey.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({
    required this.date,
    required this.info,
  });

  final DateTime date;
  final AppointmentInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dil kodunu al
    final langCode = context.langCode;
    
    // Consultant bilgisini al (dil bazlı isim için)
    final consultantId = info.consultantId;
    final consultantJob = info.job ?? '';
    String consultantDisplayName = info.specialistName; // Fallback
    String photoURL = '';
    
    // Consultant bilgisini ref'ten al (eğer consultantId varsa)
    if (consultantId != null) {
      try {
        final consultantsState = ref.watch(specialistsProvider);
        final consultants = consultantsState.specialists;
        
        // Eğer consultants listesi boşsa, provider henüz yükleniyor demektir
        // Widget rebuild olacak ve consultants yüklendiğinde otomatik güncellenecek
        if (consultants == null || consultants.isEmpty) {
          // Log sadece ilk birkaç kez göster (spam'i önlemek için)
          // State değiştiğinde widget rebuild olacak
        } else {
          try {
            final consultant = consultants.firstWhere(
              (c) => c.id == consultantId,
              orElse: () => consultants.first, // Fallback: ilk consultant
            );
            // Dil koduna göre ismi al (en, tr, de)
            consultantDisplayName = consultant.names[langCode] as String? ?? 
                                     consultant.names['en'] as String? ?? 
                                     consultant.names.values.first.toString();
            photoURL = consultant.photoURL;
          } catch (e) {
            // Consultant bulunamadı, fallback kullan
            developer.log("⚠️ Consultant bulunamadı (ID: $consultantId): $e");
          }
        }
      } catch (e) {
        // Provider hatası, fallback kullan
        developer.log("⚠️ SpecialistsProvider hatası: $e");
      }
    }
    
    // Tarih ve saat bilgisi
    final appointmentDateTime = info.appointmentDateTime ?? date;
    final monthLabel = MonthStrings.name(context, appointmentDateTime.month);
    final formattedTime = TimeFormatUtils.formatTime(context, appointmentDateTime);
    final dateTimeText = '$monthLabel ${appointmentDateTime.day} | $formattedTime';
    
    // Status bilgisi (pending de scheduled olarak göster)
    final status = info.status ?? 'scheduled';
    final statusText = _getStatusText(context, status == 'pending' ? 'scheduled' : status);
    
    // Stil sabitleri
    const Color _kLightGreyText = Color(0xFFA6A6A6);

    return GestureDetector(
      onTap: () {
        // Randevu detay ekranına git
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AppointmentDetailScreen(
              appointment: info,
            ),
          ),
        );
      },
      child: Container(
        width: 327.w,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xffC4E0FE).withValues(alpha: 0.4),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Sol tarafta: Koç fotoğrafı
            Container(
              width: 68.w,
              height: 68.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2BD383),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: photoURL.isNotEmpty
                    ? Image.network(
                        photoURL,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 40.w, color: Colors.grey[600]),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.person, size: 40.w, color: Colors.grey[600]),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Sağ tarafta: Koç görevi, isim, tarih/saat, durum
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Koç görevi (üstte)
                  if (consultantJob.isNotEmpty)
                    Text(
                      () {
                        try {
                          return JobConvert(consultantJob, context).call();
                        } catch (e) {
                          debugPrint("⚠️ JobConvert hatası: $e");
                          return consultantJob;
                        }
                      }(),
                      style: GoogleFonts.quicksand(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 24.h / 17.h,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (consultantJob.isNotEmpty) const SizedBox(height: 2),
                  // Koç ismi (görevin altında)
                  Text(
                    consultantDisplayName,
                    style: GoogleFonts.quicksand(
                      fontSize: consultantJob.isNotEmpty ? 14 : 17,
                      fontWeight: FontWeight.w500,
                      height: consultantJob.isNotEmpty ? 20.h / 14.h : 24.h / 17.h,
                      color: consultantJob.isNotEmpty ? _kLightGreyText : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Tarih ve saat
                  Text(
                    dateTimeText,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 18.h / 12.h,
                      color: _kLightGreyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Durum
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.quicksand(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Status metnini döndürür
  String _getStatusText(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
      case 'pending':
        return 'Planlandı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  /// Status rengini döndürür
  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'scheduled':
      case 'pending':
        return const Color(0xFF2BD383); // Yeşil
      case 'completed':
        return const Color(0xFF7B7B7B); // Gri
      case 'cancelled':
        return Colors.red;
      default:
        return const Color(0xFFA6A6A6);
    }
  }
}
