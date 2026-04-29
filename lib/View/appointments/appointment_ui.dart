import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../core/utils/context_l10n_extensions.dart';
import '../../core/utils/job_convert.dart';
import '../specialists_screen/specialists_notifier.dart';
import 'appointments_ui_provider.dart';

const Color _kLightGreyText = Color(0xFF96989C);

class AppointmentCardUi extends ConsumerWidget {
  final AppointmentUiItem item;

  const AppointmentCardUi({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = context.langCode;
    final consultantId = item.info.consultantId;
    final consultantJob = item.info.job ?? '';
    String consultantDisplayName = item.info.specialistName;
    String photoURL = item.avatarAsset;

    if (consultantId != null) {
      try {
        final consultantsState = ref.watch(specialistsProvider);
        final consultants = consultantsState.specialists;

        if (consultants != null && consultants.isNotEmpty) {
          final consultant = consultants.firstWhere(
            (c) => c.id == consultantId,
            orElse: () => consultants.first,
          );
          consultantDisplayName =
              consultant.names[langCode] as String? ??
              consultant.names['en'] as String? ??
              consultant.names.values.first.toString();
          photoURL = consultant.photoURL.isNotEmpty
              ? consultant.photoURL
              : photoURL;
        }
      } catch (e) {
        developer.log("⚠️ Provider hatası: $e");
      }
    }

    final appointmentDateTime = item.info.appointmentDateTime ?? item.dateTime;
    final isCompleted =
        (item.info.status ?? 'scheduled').toLowerCase() == 'completed';

    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final String dateTimeText = isCompleted
        ? DateFormat(
            'd MMM',
            localeTag,
          ).format(appointmentDateTime).toUpperCase()
        : DateFormat('HH:mm').format(appointmentDateTime);

    final String iconAsset = isCompleted
        ? 'assets/icons/ic_calendar.svg'
        : 'assets/icons/ic_clock.svg';

    final List<Color> themeColors = [
      const Color(0xFF21BC87),
      const Color(0xFFA855F7),
      const Color.fromARGB(255, 144, 11, 25),
    ];
    final int colorIndex =
        (consultantId?.hashCode ?? item.info.hashCode).abs() %
        themeColors.length;
    final Color selectedColor = themeColors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Figma'daki %5 Siyah Border
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      // Border'ın içinden renk taşmaması için 1 piksel küçük kavisle kırpıyoruz
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          // İçeriğin yüksekliğine göre şeridin uzamasını sağlar
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SOL İNCE RENKLİ ŞERİT
              Container(
                width: 6, // Figma'daki gibi zarif ve ince
                color: selectedColor,
              ),

              // 2. ANA İÇERİK ALANI
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Kartın iç boşluğu
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E2E2), 
                          borderRadius: BorderRadius.circular(12),
                          image: photoURL.startsWith('http')
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(photoURL),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: !photoURL.startsWith('http')
                            ? Icon(Icons.person, color: Colors.grey[400])
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // İsim ve Görev (Orta Kısım)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              consultantDisplayName,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w600, // SemiBold
                                color: Colors.black,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (consultantJob.isNotEmpty)
                              Text(
                                JobConvert(consultantJob, context).call(),
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500, // Medium
                                  color: _kLightGreyText,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 3. SAĞ TARAF: SAAT/TARİH KAPSÜLÜ
                      Container(
                        // Figma'dan attığın birebir boşluk değerleri
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFFF5F5F5) // Geçmiş için gri zemin
                              : selectedColor.withOpacity(
                                  0.1,
                                ), // Yaklaşan için renkli şeffaf zemin
                          borderRadius: BorderRadius.circular(
                            9999,
                          ), // Tam yuvarlak köşeler
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              iconAsset,
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                isCompleted ? _kLightGreyText : selectedColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(
                              width: 6,
                            ), // İkon ve yazı arası boşluk
                            Text(
                              dateTimeText,
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 14,
                                fontWeight: FontWeight.w600, // SemiBold
                                color: isCompleted
                                    ? _kLightGreyText
                                    : selectedColor,
                                height:
                                    1.0, // Kapsülün içinde tam ortalanması için
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
