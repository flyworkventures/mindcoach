import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/Analytics/analytics_service.dart';
import 'package:mindcoach/core/analytics/analytics_events.dart';
import 'package:mindcoach/View/appointments/appointments_notifier.dart';
import 'package:mindcoach/View/chat_screen/conversation/conversation_page.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/repo/consultant_repo.dart';
import 'package:mindcoach/core/routes/page_routes.dart';
import 'package:mindcoach/core/routes/video_call_route_args.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/explanation_convert.dart';
import 'package:mindcoach/core/utils/feature_convert.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/revenuecat_paywalls.dart';
import 'package:mindcoach/core/widgets/future_progress_dialog.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/consultant_model.dart';

class _AppointmentResult {
  final int statusCode;
  final String? message;
  final String? error;
  const _AppointmentResult({
    required this.statusCode,
    this.message,
    this.error,
  });
}

class SpecialistDetailScreen extends ConsumerStatefulWidget {
  final ConsultantModel specialist;

  /// Onboarding sirasinda (login olmadan) acildiginda true olur.
  /// 1 dakikalik limit yalnizca goruntulu arama baglandiginda baslar
  /// ([VideoCallRealtimeScreen], `connection_success`).
  final bool isTrial;

  /// Bu ekran bir ConversationScreen üzerinden açıldıysa true olur.
  /// Sohbet butonuna basıldığında yeni bir ConversationScreen push'lamak
  /// yerine geri pop ederek loop'u engelleriz.
  final bool fromConversation;

  /// PostHog `coach_profile_viewed.source` — `match_card` | `book_button`.
  final String profileSource;

  const SpecialistDetailScreen({
    super.key,
    required this.specialist,
    this.isTrial = false,
    this.fromConversation = false,
    this.profileSource = 'match_card',
  });

  @override
  ConsumerState<SpecialistDetailScreen> createState() =>
      _SpecialistDetailScreenState();
}

class _SpecialistDetailScreenState
    extends ConsumerState<SpecialistDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  late ConsultantModel _specialist;
  bool _isCreatingAppointment = false;

  // 00:00 - 23:30 arası 24 slot, değişken aralıklarla.
  static const List<String> _slotTimes = [
    '00:00',
    '00:45',
    '01:30',
    '02:30',
    '03:15',
    '04:00',
    '05:00',
    '06:30',
    '07:15',
    '08:00',
    '09:00',
    '10:30',
    '11:15',
    '12:00',
    '13:30',
    '14:15',
    '15:00',
    '16:30',
    '17:15',
    '18:00',
    '19:30',
    '20:45',
    '22:00',
    '23:30',
  ];

  String? _slotTimeAt(int index) =>
      (index >= 0 && index < _slotTimes.length) ? _slotTimes[index] : null;

  @override
  void initState() {
    super.initState();
    _specialist = widget.specialist;
    // Polling yerine, detay ekrani acildiginda tek sefer guncel randevu cek.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(appointmentsProvider.notifier).refresh();
      AnalyticsService.instance.capture(
        AnalyticsEvents.coachDetailViewed,
        properties: {
          'coach_id': _specialist.id.toString(),
          'source': widget.profileSource,
          'consultant_id': _specialist.id,
          'is_trial_flow': widget.isTrial,
        },
      );
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

  /// Seçili slot için bugün tarihinde randevu oluştur.
  /// POST /appointments/webhook — server duplicate kontrolünü kendisi yapar.
  /// Network/Backend süresince proje genel loading dialog'unu (runWithProgressDialog) gösterir.
  Future<void> _createAppointment(String slotTime) async {
    if (_isCreatingAppointment) return;
    final l10n = context.l10n;
    final userId = ref.read(AllProviders.userProvider)?.id;
    if (userId == null) {
      _showSnack('Error');
      return;
    }

    final parts = slotTime.split(':');
    if (parts.length != 2) return;
    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    _isCreatingAppointment = true;
    try {
      final result = await context.runWithProgressDialog<_AppointmentResult>(
        () async {
          try {
            final httpService = HttpService();
            final response = await httpService.post(
              path: AppConstants.createAppointmentURL,
              body: {
                'userId': userId,
                'consultantId': _specialist.id,
                'appointmentDate': appointmentDateTime
                    .toUtc()
                    .toIso8601String(),
              },
            );

            Map<String, dynamic> data = const {};
            try {
              data = jsonDecode(response.body) as Map<String, dynamic>;
            } catch (_) {}

            final ok = response.statusCode == 201 || response.statusCode == 200;
            // Dialog kapanmadan önce appointments listesini yenile — kapandığında
            // slotlar zaten güncellenmiş görünür.
            if (ok && mounted) {
              await ref.read(appointmentsProvider.notifier).refresh();
            }
            return _AppointmentResult(
              statusCode: response.statusCode,
              message: data['message'] as String?,
              error: data['error'] as String?,
            );
          } catch (_) {
            return const _AppointmentResult(statusCode: -1);
          }
        },
        message: l10n.pleaseWait,
      );

      if (!mounted) return;
      final ok = result.statusCode == 201 || result.statusCode == 200;
      if (ok) {
        setState(() => _selectedTime = null);
        await AnalyticsService.instance.capture(
          AnalyticsEvents.appointmentCreated,
          properties: {
            'consultant_id': _specialist.id,
            'slot_time': slotTime,
          },
        );
        _showSnack(result.message ?? l10n.coachDetailCreateAppointment);
      } else if (result.statusCode == 409) {
        await AnalyticsService.instance.capture(
          AnalyticsEvents.appointmentCreateFailed,
          properties: {
            'consultant_id': _specialist.id,
            'status_code': result.statusCode,
            'error_type': 'conflict',
          },
        );
        final serverError = result.error ?? '';
        final String localizedMsg;
        if (serverError.contains('at this date and time')) {
          localizedMsg = l10n.appointmentConflictSameTime;
        } else if (serverError.contains('with this consultant')) {
          localizedMsg = l10n.appointmentConflictSameCoach;
        } else {
          localizedMsg = l10n.appointmentConflictSameTime;
        }
        _showSnack(localizedMsg);
      } else {
        await AnalyticsService.instance.capture(
          AnalyticsEvents.appointmentCreateFailed,
          properties: {
            'consultant_id': _specialist.id,
            'status_code': result.statusCode,
          },
        );
        _showSnack('Error');
      }
    } finally {
      _isCreatingAppointment = false;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                                                  fontSize: 16,
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
                                      fontSize: 16,
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
                                  title: '00:00 - 23:30',
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
                              _bookedTimeSlotsForCoachOnDate(
                                appointmentsState.appointments,
                                specialist.id,
                                _selectedDate,
                              ),
                            ),
                          ],

                          // Alt Navigation Bar çakışmasını engellemek için boşluk
                          SizedBox(height: bottomPadding),
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
                  // Eğer ekran zaten bir ConversationScreen'den açıldıysa,
                  // yeni bir ConversationScreen push'lamak yerine geri pop
                  // ederek loop'u engelle (chat → detail → chat → detail ...).
                  if (widget.fromConversation) {
                    Navigator.pop(context);
                  } else {
                    // Detaydan ConversationScreen'e gidiyoruz; fromDetail=true
                    // geçerek o ekrandan tekrar detaya gidilirse geri pop edilsin.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(
                          name: '/conversation_page',
                        ),
                        builder: (_) => ConversationScreen(
                          specialistId: specialist,
                          fromDetail: true,
                        ),
                      ),
                    );
                  }
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

            // Bottom action button — bir slot seçiliyse "Randevu Oluştur",
            // değilse "Görüntülü Aramayı Başlat".
            Expanded(
              child: Builder(
                builder: (context) {
                  final hasSelectedSlot = _selectedTime != null;
                  final iconPath = hasSelectedSlot
                      ? "assets/icons/ic_ic.svg"
                      : "assets/icons/ic_record.svg";
                  final label = hasSelectedSlot
                      ? l10n.coachDetailCreateAppointment
                      : l10n.coachDetailStartVideoCall;

                  Future<void> onTap() async {
                    if (hasSelectedSlot) {
                      await _createAppointment(_selectedTime!);
                      return;
                    }

                    final premiumState = ref.read(AllProviders.premiumProvider);
                    late final bool isTrial;
                    // FindCoachStep'ten gelen her görüşme 1 dk trial — premium olsun olmasın.
                    if (widget.isTrial) {
                      isTrial = true;
                    } else if (premiumState.isPremium) {
                      isTrial = false;
                    } else {
                      final isGuest =
                          (ref.read(AllProviders.userProvider)?.credential ??
                                  '')
                              .toLowerCase() ==
                          'guest';
                      await presentPaywallForUser(context, isGuest: isGuest);
                      return;
                    }
                    if (!context.mounted) return;
                    await AnalyticsService.instance.capture(
                      AnalyticsEvents.videoCallStarted,
                      properties: {
                        'coach_id': specialist.id.toString(),
                        'consultant_id': specialist.id,
                        'is_trial': isTrial,
                      },
                    );
                    await Navigator.pushNamed(
                      context,
                      PageRoutes.videoCall,
                      arguments: VideoCallRouteArgs(
                        specialist: specialist,
                        isTrial: isTrial,
                      ),
                    );
                    if (mounted) _refreshSpecialist();
                  }

                  return GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21BC87),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF21BC87),
                            blurRadius: 10,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(iconPath),
                          const SizedBox(width: 10),
                          Text(
                            label,
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
                  );
                },
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
              fontSize: 16,
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

  Set<String> _bookedTimeSlotsForCoachOnDate(
    Map<DateTime, List<AppointmentInfo>> appointments,
    int consultantId,
    DateTime date,
  ) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final bookedSlots = <String>{};

    for (final entry in appointments.entries) {
      final keyDate = DateTime(entry.key.year, entry.key.month, entry.key.day);
      if (keyDate != targetDate) continue;

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
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('d MMM, EEEE', localeTag).format(_selectedDate);

    String timeLabel;
    if (_selectedTime != null) {
      final parts = _selectedTime!.split(':');
      final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      timeLabel = DateFormat.jm(localeTag).format(dt);
    } else {
      timeLabel = context.l10n.coachDetailSelectTime;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Selector
        _appointmentField(
          iconAsset: "assets/icons/calendar-2 1.png",
          fallbackIcon: Icons.calendar_today,
          label: dateLabel,
          onTap: _showDateBottomSheet,
        ),
        const SizedBox(height: 12),
        // Time Selector
        _appointmentField(
          iconAsset: "assets/icons/clock (10) 1.png",
          fallbackIcon: Icons.access_time,
          label: timeLabel,
          highlighted: _selectedTime != null,
          onTap: () => _showTimeBottomSheet(bookedSlots),
        ),
      ],
    );
  }

  Widget _appointmentField({
    required String iconAsset,
    required IconData fallbackIcon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F5F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlighted
                ? const Color(0xFF21BC87)
                : const Color(0xFFE2E2E2),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              iconAsset,
              width: 22,
              height: 22,
              errorBuilder: (c, e, s) => Icon(fallbackIcon, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 20 / 14,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bu koç için randevusu olan günleri (gün bazında) döndürür — takvimde
  /// nokta göstermek için kullanılır.
  Set<DateTime> _eventDatesForCoach() {
    final appointments = ref.read(appointmentsProvider).appointments;
    final result = <DateTime>{};
    for (final entry in appointments.entries) {
      for (final info in entry.value) {
        if (info.consultantId != _specialist.id) continue;
        if ((info.status ?? '').toLowerCase() == 'cancelled') continue;
        final dt = info.appointmentDateTime;
        if (dt == null) continue;
        result.add(DateTime(dt.year, dt.month, dt.day));
      }
    }
    return result;
  }

  void _showDateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppointmentDateSheet(
        initialDate: _selectedDate,
        eventDates: _eventDatesForCoach(),
        onSaved: (date) {
          setState(() {
            _selectedDate = date;
            _selectedTime = null; // Tarih değişince saat sıfırlanır.
          });
        },
      ),
    );
  }

  void _showTimeBottomSheet(Set<String> bookedSlots) {
    DateTime initialTime = DateTime.now();
    if (_selectedTime != null) {
      final parts = _selectedTime!.split(':');
      initialTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }
    
    DateTime tempSelectedTime = initialTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: tempSelectedTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempSelectedTime = newDateTime;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21BC87),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      final timeStr = DateFormat('HH:mm').format(tempSelectedTime);
                      
                      final isPast = _selectedDate.year == DateTime.now().year &&
                                     _selectedDate.month == DateTime.now().month &&
                                     _selectedDate.day == DateTime.now().day &&
                                     tempSelectedTime.hour * 60 + tempSelectedTime.minute < DateTime.now().hour * 60 + DateTime.now().minute;
                      
                      if (bookedSlots.contains(timeStr) || isPast) {
                        _showSnack(context.l10n.appointmentConflictSameTime);
                        return;
                      }

                      setState(() {
                        _selectedTime = timeStr;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      context.l10n.save,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Randevu tarihi seçimi için bottom sheet — takvim sayfasının (CalendarScreen)
/// üstündeki takvim yapısının aynısı: ay başlığı + ay okları, haftalık şerit ve
/// bordürlü TableCalendar. Altında Kaydet butonu.
class _AppointmentDateSheet extends StatefulWidget {
  final DateTime initialDate;
  final Set<DateTime> eventDates;
  final ValueChanged<DateTime> onSaved;

  const _AppointmentDateSheet({
    required this.initialDate,
    required this.eventDates,
    required this.onSaved,
  });

  @override
  State<_AppointmentDateSheet> createState() => _AppointmentDateSheetState();
}

class _AppointmentDateSheetState extends State<_AppointmentDateSheet> {
  static const _primaryGreen = Color(0xFF21BC87);
  static const _lightGreyText = Color(0xFF96989C);

  late DateTime _selected;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selected = _dateOnly(widget.initialDate);
    _focusedDay = _selected;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _today => _dateOnly(DateTime.now());

  bool _isPast(DateTime day) => _dateOnly(day).isBefore(_today);

  bool _hasEvent(DateTime day) => widget.eventDates.contains(_dateOnly(day));

  // Takvim şeridi için o haftanın günleri (Pazartesi başlangıçlı).
  List<DateTime> _getCurrentWeekDays(DateTime focused) {
    final startOfWeek = focused.subtract(Duration(days: focused.weekday - 1));
    return List.generate(
      7,
      (i) => _dateOnly(startOfWeek.add(Duration(days: i))),
    );
  }

  void _selectDay(DateTime day) {
    if (_isPast(day)) return;
    setState(() {
      _selected = _dateOnly(day);
      _focusedDay = _selected;
    });
  }

  void _changeMonth(int delta) {
    final candidate = DateTime(
      _focusedDay.year,
      _focusedDay.month + delta,
      _focusedDay.day,
    );
    // Geçmiş aylara gitmeyi engelle.
    if (candidate.year < _today.year ||
        (candidate.year == _today.year && candidate.month < _today.month)) {
      return;
    }
    setState(() => _focusedDay = candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1. Ay/Yıl başlığı ve navigasyon
            _buildMonthNavigationHeader(context),
            const SizedBox(height: 24),

            // 2. Haftalık şerit
            _buildWeeklyTimelineRow(context),
            const SizedBox(height: 24),

            // 3. Takvim (TableCalendar)
            _buildCustomCalendar(context),
            const SizedBox(height: 24),

            // 4. Kaydet butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.onSaved(_selected);
                  Navigator.pop(context);
                },
                child: Text(
                  context.l10n.save,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Ay/Yıl başlığı ---
  Widget _buildMonthNavigationHeader(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel = DateFormat('MMMM', locale).format(_focusedDay).toUpperCase();
    final dayLabel = DateFormat('EEEE', locale).format(_selected);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthLabel ${_focusedDay.year}',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _primaryGreen,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${_selected.day}',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dayLabel,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _lightGreyText,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => _changeMonth(-1),
              child: SvgPicture.asset(
                'assets/icons/ic_left.svg',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _changeMonth(1),
              child: SvgPicture.asset(
                'assets/icons/ic_right.svg',
                width: 32,
                height: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Haftalık şerit ---
  Widget _buildWeeklyTimelineRow(BuildContext context) {
    final weekDays = _getCurrentWeekDays(_focusedDay);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: weekDays.map((date) {
        final currentDate = _dateOnly(date);
        final isSelected = isSameDay(_selected, currentDate);
        final isPast = _isPast(currentDate);
        final hasEvent = _hasEvent(currentDate);

        final dayName = DateFormat('EEE', locale).format(date).toUpperCase();
        final dayNumber = '${date.day}';

        // Seçili gün (yeşil kapsül)
        if (isSelected) {
          return GestureDetector(
            onTap: () => _selectDay(currentDate),
            child: Container(
              height: 94,
              width: 50,
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayNumber,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasEvent)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // Seçili olmayan gün
        return GestureDetector(
          onTap: isPast ? null : () => _selectDay(currentDate),
          child: SizedBox(
            height: 94,
            width: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isPast
                        ? _lightGreyText.withValues(alpha: 0.5)
                        : _lightGreyText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dayNumber,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isPast
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                if (hasEvent)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- TableCalendar ---
  Widget _buildCustomCalendar(BuildContext context) {
    final langCode = context.langCode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: TableCalendar<int>(
        startingDayOfWeek: langCode == 'en'
            ? StartingDayOfWeek.sunday
            : StartingDayOfWeek.monday,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerVisible: false,
        rowHeight: 44.0,
        daysOfWeekHeight: 40.0,
        enabledDayPredicate: (day) => !_isPast(day),
        selectedDayPredicate: (day) => isSameDay(_selected, day),
        eventLoader: (day) => _hasEvent(day) ? const [1] : const [],
        onDaySelected: (selectedDay, focusedDay) => _selectDay(selectedDay),
        onPageChanged: (focusedDay) =>
            setState(() => _focusedDay = focusedDay),
        calendarBuilders: CalendarBuilders<int>(
          dowBuilder: (dowContext, day) {
            final locale = Localizations.localeOf(dowContext);
            final label = DateFormat.E(
              locale.toLanguageTag(),
            ).format(day).substring(0, 1);
            return Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _lightGreyText,
                ),
              ),
            );
          },
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            final isSelectedDay = isSameDay(_selected, day);
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelectedDay ? Colors.white : _primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          defaultTextStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          disabledTextStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFCED0D3),
          ),
          todayDecoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          selectedDecoration: BoxDecoration(
            color: _primaryGreen,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
