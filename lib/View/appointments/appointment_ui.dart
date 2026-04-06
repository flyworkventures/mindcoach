import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;

import '../../core/global_constants/month_strings.dart';
import '../../core/utils/context_l10n_extensions.dart';
import '../../core/utils/job_convert.dart';
import '../../core/utils/screen_size_extensions.dart';
import '../../core/utils/time_format_utils.dart';
import '../specialists_screen/specialists_notifier.dart';
import 'appointments_ui_provider.dart';

class AppointmentCardUi extends ConsumerWidget {
  final AppointmentUiItem item;

  const AppointmentCardUi({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dil kodunu al
    final langCode = context.langCode;
    
    // Consultant bilgisini al (dil bazlı isim için)
    final consultantId = item.info.consultantId;
    final consultantJob = item.info.job ?? '';
    String consultantDisplayName = item.info.specialistName; // Fallback
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
    
    // Eğer photoURL boşsa, avatarAsset'i kullan (fallback)
    if (photoURL.isEmpty) {
      photoURL = item.avatarAsset;
    }
    
    // Tarih ve saat bilgisi
    final appointmentDateTime = item.info.appointmentDateTime ?? item.dateTime;
    final monthLabel = MonthStrings.name(context, appointmentDateTime.month);
    final formattedTime = TimeFormatUtils.formatTime(context, appointmentDateTime);
    final dateTimeText = '$monthLabel ${appointmentDateTime.day} | $formattedTime';
    
    // Status bilgisi (pending de scheduled olarak göster)
    final status = item.info.status ?? 'scheduled';
    final statusText = _getStatusText(context, status == 'pending' ? 'scheduled' : status);
    
    // Stil sabitleri
    const Color _kLightGreyText = Color(0xFFA6A6A6);

    return Container(
      width: 327.w,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
              child: photoURL.isNotEmpty && photoURL.startsWith('http')
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
                  : photoURL.isNotEmpty && !photoURL.startsWith('http')
                      ? Image.asset(
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
