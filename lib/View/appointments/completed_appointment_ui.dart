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

const Color _kCompletedGrey = Color(0xFF96989C);
const List<Color> _kThemeColors = [
  Color(0xFF21BC87),
  Color(0xFFA855F7),
  Color(0xFFDC2626),
];

/// Tamamlanan randevuların card tasarımı - SimplifiedVersion
class CompletedAppointmentCardUi extends ConsumerWidget {
  final AppointmentUiItem item;

  const CompletedAppointmentCardUi({super.key, required this.item});

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
    final int colorIndex = consultantId != null
        ? (consultantId - 1).abs() % _kThemeColors.length
        : (item.info.hashCode).abs() % _kThemeColors.length;
    final Color selectedColor = _kThemeColors[colorIndex];

    // Tamamlanan tarih: d MMM formatında uppercase (örn. "5 FEB")
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final String completedDateText = DateFormat(
      'd MMM',
      localeTag,
    ).format(appointmentDateTime).toUpperCase();

    return Opacity(
      opacity: 0.64,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SOL İNCE RENKLİ ŞERİT (AppointmentCardUi ile aynı mantık)
                Container(width: 6, color: selectedColor),

                // 2. ANA İÇERİK ALANI
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
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
                                  fontWeight: FontWeight.w600,
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
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF96989C),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 3. SAĞ TARAF: TARİH KAPSÜLÜ (Sade tasarım)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tamamlanan icon
                              SvgPicture.asset(
                                'assets/icons/ic_comp.svg',
                                width: 16,
                                height: 16,
                                colorFilter: const ColorFilter.mode(
                                  _kCompletedGrey,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Tamamlanan tarih (d MMM format)
                              Text(
                                completedDateText,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kCompletedGrey,
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
      ),
    );
  }
}
