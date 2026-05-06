import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/View/appointments/appointments_notifier.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/repo/consultant_repo.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/routes/video_call_route_args.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/explanation_convert.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/revenuecat_paywalls.dart';
import 'package:mindcoach/models/consultant_model.dart';

class SpecialistDetailScreen extends ConsumerStatefulWidget {
  final ConsultantModel specialist;

  /// Onboarding sirasinda (login olmadan) acildiginda true olur.
  /// 1 dakikalik limit yalnizca goruntulu arama baglandiginda baslar
  /// ([VideoCallRealtimeScreen], `connection_success`).
  final bool isTrial;

  const SpecialistDetailScreen({
    super.key,
    required this.specialist,
    this.isTrial = false,
  });

  @override
  ConsumerState<SpecialistDetailScreen> createState() =>
      _SpecialistDetailScreenState();
}

class _SpecialistDetailScreenState
    extends ConsumerState<SpecialistDetailScreen> {
  int? _selectedSlotIndex;
  late ConsultantModel _specialist;

  @override
  void initState() {
    super.initState();
    _specialist = widget.specialist;
    // Polling yerine, detay ekrani acildiginda tek sefer guncel randevu cek.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(appointmentsProvider.notifier).refresh();
    });
  }

  @override
  void didUpdateWidget(covariant SpecialistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.specialist.id != widget.specialist.id) {
      _specialist = widget.specialist;
    }
  }

  Future<void> _refreshSpecialist() async {
    try {
      final repo = ConsultantRepo(null);
      final list = await repo.getAllConsultant() ?? [];
      final updated = list.where((c) => c.id == _specialist.id).toList();
      if (!mounted || updated.isEmpty) return;
      setState(() {
        _specialist = updated.first;
      });
    } catch (_) {
      // Refresh başarısız olsa da mevcut detay ekranı çalışmaya devam etsin.
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsState = ref.watch(appointmentsProvider);
    final l10n = context.l10n;
    final langCode = context.langCode;
    final specialist = _specialist;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final specialistName =
        specialist.names[langCode] as String? ??
        specialist.names['en'] as String? ??
        specialist.names.values.first.toString();

    final jobTitle = JobConvert(specialist.job, context).call();
    final featureConvert = FeatureConvert(context);
    final explanationConvert = ExplanationConvert(context);
    final explanation = explanationConvert.call(specialist.explanation);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom:
            false, // Alt bar için SafeArea'yı kapattık, custom padding kullanıyoruz
        child: Column(
          children: [
            SizedBox(height: kTextTabBarHeight),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ======== TOP HERO SECTION ========
                    SizedBox(
                      height: 350,
                      child: Stack(
                        children: [
                          // Coach photo
                          Positioned(
                            top: 0,
                            right: -30,
                            bottom: 0,
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Builder(
                              builder: (context) {
                                final originalUrl = specialist.photoURL;

                                String url = originalUrl;
                                final dotIndex = originalUrl.lastIndexOf('.');

                                if (dotIndex != -1) {
                                  url =
                                      '${originalUrl.substring(0, dotIndex)}_detail${originalUrl.substring(dotIndex)}';
                                }

                                final isSvg = url.toLowerCase().endsWith(
                                  '.svg',
                                );

                                Widget fallbackIcon() => Container(
                                  color: const Color(0xFFF5F5F5),
                                  child: const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Color(0xFF96989C),
                                  ),
                                );

                                if (isSvg) {
                                  return SvgPicture.network(
                                    url,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (_, _, _) => fallbackIcon(),
                                  );
                                } else {
                                  return CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    placeholder: (_, _) =>
                                        const SizedBox.shrink(),
                                    errorWidget: (_, _, _) => fallbackIcon(),
                                  );
                                }
                              },
                            ),
                          ),

                          // Left content overlay
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // < Back
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/ic_bakc.svg",
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          context.l10n.back,
                                          style: TextStyle(
                                            fontFamily: 'Geist',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Badges: Verified + Rating + Online
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/ic_coach_detail_tick.svg",
                                      ),
                                      const SizedBox(width: 4),
                                      if (specialist.rating > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFFFCC00,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(
                                                "assets/icons/start.svg",
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                specialist.rating
                                                    .toStringAsFixed(2),
                                                style: const TextStyle(
                                                  fontFamily: 'Geist',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFFFCC00),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE2E2E2),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF21BC87),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              l10n.coachDetailOnline,
                                              style: const TextStyle(
                                                fontFamily: 'Geist',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Coach Name
                                  Text(
                                    specialistName,
                                    style: const TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF21BC87),
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Job title
                                  Text(
                                    jobTitle,
                                    style: const TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF96989C),
                                      height: 20 / 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Feature tags
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.50,
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 6,
                                      children: specialist.features
                                          .map(
                                            (f) => _buildFeatureChip(
                                              featureConvert.call(f.toString()),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ======== INFORMATION SECTION (UPDATED CONTAINER) ========
                    Container(
                      width: double.infinity,
                      // Figma'daki 16px padding ve alt taraftan buton boşluğu bırakıldı
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.10,
                            ), // #000000 %10 Gölge
                            blurRadius: 10,
                            offset: const Offset(
                              0,
                              -4,
                            ), // Y ekseninde -4 yukarı doğru
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.coachDetailInformation,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 24 / 18,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _buildExplanationText(explanation, jobTitle),
                          const SizedBox(height: 24),

                          // Info cards row
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: SvgPicture.asset(
                                    "assets/icons/ic_memory.svg",
                                    height: 26,
                                    width: 26,
                                    fit: BoxFit.scaleDown,
                                  ),
                                  title: l10n.coachDetailUnlimitedMemory,
                                  subtitle: l10n.coachDetailMemory,
                                ),
                              ),
                              const SizedBox(width: 10), // Gap: 10px
                              Expanded(
                                child: _buildInfoCard(
                                  icon: SvgPicture.asset(
                                    "assets/icons/ic_lang.svg",
                                  ),
                                  title: l10n.coachDetailMultilingual,
                                  subtitle: l10n.coachDetailLanguage,
                                ),
                              ),
                              const SizedBox(width: 10), // Gap: 10px
                              Expanded(
                                child: _buildInfoCard(
                                  icon: SvgPicture.asset(
                                    "assets/icons/ic_aval.svg",
                                  ),
                                  title: '08:00 - 18:00',
                                  subtitle: l10n.coachDetailAvailability,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          if (!widget.isTrial) ...[
                            // ======== APPOINTMENT SECTION ========
                            Text(
                              l10n.coachDetailAppointment,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 24 / 18,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Appointment card
                            _buildAppointmentCard(
                              _bookedTimeSlotsForCoachToday(
                                appointmentsState.appointments,
                                specialist.id,
                              ),
                            ),
                          ],

                          // Alt Navigation Bar çakışmasını engellemek için boşluk
                          SizedBox(height: 100 + bottomPadding),
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

      // ======== BOTTOM BAR ========
      // Alt barın altında body'nin görünmesini kapat; en alttaki gri/karanlık
      // şerit hissini önler.
      extendBody: false,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: bottomPadding > 0 ? bottomPadding : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isTrial) ...[
              // Chat icon
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/conversation_page',
                    arguments: specialist,
                  );
                },
                child: Container(
                  width: 60,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E2E2)),
                  ),
                  child: SvgPicture.asset(
                    "assets/icons/ic_message.svg",
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],

            // Start Video Call button
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final premiumState = ref.read(AllProviders.premiumProvider);
                  late final bool isTrial;
                  // FindCoachStep'ten gelen her görüşme 1 dk trial — premium olsun olmasın.
                  if (widget.isTrial) {
                    isTrial = true;
                  } else if (premiumState.isPremium) {
                    isTrial = false;
                  } else {
                    await presentProOffersPaywall();
                    return;
                  }
                  if (!context.mounted) return;
                  await Navigator.pushNamed(
                    context,
                    PageRoutes.videoCall,
                    arguments: VideoCallRouteArgs(
                      specialist: specialist,
                      isTrial: isTrial,
                    ),
                  );
                  if (mounted) _refreshSpecialist();
                },
                child: Container(
                  height: 54, // Fixed (54px)
                  padding: const EdgeInsets.all(10), // Padding: 10px
                  decoration: BoxDecoration(
                    color: const Color(0xFF21BC87),
                    borderRadius: BorderRadius.circular(16), // Radius: 16px
                    boxShadow: [
                      BoxShadow(
                        // Drop shadow: X: 0, Y: 0, Blur: 10, #21BC87
                        color: const Color(0xFF21BC87),
                        blurRadius: 10,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset("assets/icons/ic_record.svg"),
                      const SizedBox(width: 10), // Gap: 10px
                      Text(
                        l10n.coachDetailStartVideoCall,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // HELPER WIDGETS
  // ====================================================================

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF898989).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
          height: 14 / 11,
        ),
      ),
    );
  }

  Widget _buildExplanationText(String explanation, String jobTitle) {
    final escapedJob = RegExp.escape(jobTitle);
    final regex = RegExp(escapedJob, caseSensitive: false);
    final match = regex.firstMatch(explanation);

    if (match != null) {
      final before = explanation.substring(0, match.start);
      final matched = explanation.substring(match.start, match.end);
      final after = explanation.substring(match.end);

      return RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Color(0xFF96989C),
            height: 18 / 12,
            letterSpacing: -0.12,
          ),
          children: [
            TextSpan(text: before),
            TextSpan(
              text: matched,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: after),
          ],
        ),
      );
    }

    return Text(
      explanation,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: Color(0xFF96989C),
        height: 18 / 12,
        letterSpacing: -0.12,
      ),
    );
  }

  Widget _buildInfoCard({
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF898989).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF96989C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Set<String> _bookedTimeSlotsForCoachToday(
    Map<DateTime, List<AppointmentInfo>> appointments,
    int consultantId,
  ) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final bookedSlots = <String>{};

    for (final entry in appointments.entries) {
      final keyDate = DateTime(entry.key.year, entry.key.month, entry.key.day);
      if (keyDate != todayDate) continue;

      for (final info in entry.value) {
        if (info.consultantId != consultantId) continue;
        if ((info.status ?? '').toLowerCase() == 'cancelled') continue;

        final dt = info.appointmentDateTime;
        if (dt == null) continue;

        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        bookedSlots.add('$hour:$minute');
      }
    }

    return bookedSlots;
  }

  Widget _buildAppointmentCard(Set<String> bookedSlots) {
    final now = DateTime.now();
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('d MMMM, EEEE', localeTag).format(now);

    // Varsayılan slotlar; DB'de aynı saatte ilgili koçun randevusu varsa pasif/soluk gösterilir.
    final slots = [
      {'time': '08:00'},
      {'time': '09:40'},
      {'time': '10:00'},
      {'time': '12:00'},
      {'time': '14:00'},
      {'time': '14:30'},
      {'time': '15:30'},
      {'time': '16:00'},
      {'time': '16:30'},
      {'time': '17:00'},
      {'time': '17:30'},
      {'time': '18:00'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F6), // Tasarımdaki hafif gri arka plan
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                SvgPicture.asset("assets/icons/ic_cal.svg"),
                const SizedBox(width: 8),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (bookedSlots.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF21BC87).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${context.l10n.appointments}: ${bookedSlots.length}',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF21BC87),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Time slots
          Wrap(
            spacing: 8, // Figma Gap: 10px
            runSpacing: 8,
            children: List.generate(slots.length, (index) {
              final slot = slots[index];
              final time = slot['time'] as String;
              final isAvailable = !bookedSlots.contains(time);
              final isSelected = _selectedSlotIndex == index;

              // Duruma göre renk atamaları
              Color borderColor;
              Color textColor;
              Color backgroundColor;

              if (!isAvailable) {
                // Pasif (Dolmuş/Geçmiş) Saatler
                borderColor = Colors.black.withValues(alpha: 0.05);
                textColor = Colors.black.withValues(alpha: 0.20);
                backgroundColor = Colors.transparent;
              } else if (isSelected) {
                // Seçili Saat
                borderColor = const Color(0xFF21BC87);
                textColor = const Color(0xFF21BC87);
                backgroundColor = const Color(
                  0xFF21BC87,
                ).withValues(alpha: 0.10);
              } else {
                // Seçilebilir Aktif Saatler
                borderColor = Colors.black.withValues(
                  alpha: 0.20,
                ); // Figma #000000 20%
                textColor = Colors.black;
                backgroundColor = Colors.transparent;
              }

              return GestureDetector(
                onTap: isAvailable
                    ? () {
                        setState(() {
                          _selectedSlotIndex = isSelected ? null : index;
                        });
                      }
                    : null, // Pasif butonlara tıklanmasını engeller
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, // Figma Left/Right 10px
                    vertical: 4, // Figma Top/Bottom 4px
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(
                      999,
                    ), // Tam oval (Pill shape)
                    border: Border.all(
                      color: borderColor,
                      width: 1, // Figma Border 1px
                    ),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
