import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/View/chat_screen/conversation/conversation_page.dart';
import 'package:mindcoach/core/global_constants/month_strings.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/models/consultant_model.dart';

import '../specialists_screen/specialists_notifier.dart';
import 'appointment_video_call_screen.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  final AppointmentInfo appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  Timer? _countdownTimer;
  int _remainingDays = 0;
  int _remainingHours = 0;
  int _remainingMinutes = 0;
  int _remainingSeconds = 0;
  ConsultantModel? _consultantModel;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final appointmentDateTime = widget.appointment.appointmentDateTime;
    if (appointmentDateTime == null) {
      setState(() {
        _remainingDays = 0;
        _remainingHours = 0;
        _remainingMinutes = 0;
        _remainingSeconds = 0;
      });
      return;
    }

    final now = DateTime.now();
    if (!appointmentDateTime.isAfter(now)) {
      setState(() {
        _remainingDays = 0;
        _remainingHours = 0;
        _remainingMinutes = 0;
        _remainingSeconds = 0;
      });
      return;
    }

    final diff = appointmentDateTime.difference(now);
    final totalSeconds = diff.inSeconds;

    setState(() {
      _remainingDays = totalSeconds ~/ (24 * 60 * 60);
      _remainingHours = (totalSeconds % (24 * 60 * 60)) ~/ (60 * 60);
      _remainingMinutes = (totalSeconds % (60 * 60)) ~/ 60;
      _remainingSeconds = totalSeconds % 60;
    });
  }

  /// Join Session butonuna tıklandığında randevu zamanını kontrol et ve video call ekranına yönlendir
  void _handleJoinSession() {
    final appointmentDateTime = widget.appointment.appointmentDateTime;
    if (appointmentDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorAppointmentDateNotFound)),
      );
      return;
    }

    final now = DateTime.now();
    final timeDifference = appointmentDateTime.difference(now);

    // Randevu zamanı gelmiş mi kontrol et (5 dakika tolerans)
    if (timeDifference.inMinutes < -5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorAppointmentExpired)));
      return;
    }

    // Randevu henüz gelmemişse uyarı göster
    if (timeDifference.inMinutes > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorAppointmentNotYet),
        ),
      );
      return;
    }

    // Randevu zamanı geldi, video call ekranına yönlendir
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AppointmentVideoCallScreen(appointment: widget.appointment),
      ),
    );
  }

  /// Talk Now butonuna tıklandığında consultant ile konuşma ekranına yönlendir
  void _handleTalkNow() {
    if (_consultantModel == null) {
      // ConsultantModel henüz yüklenmemişse, tekrar dene
      final consultantId = widget.appointment.consultantId;
      if (consultantId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.errorConsultantNotFound)));
        return;
      }

      try {
        final consultantsState = ref.read(specialistsProvider);
        final consultants = consultantsState.specialists;

        if (consultants == null || consultants.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.errorConsultantsNotLoaded)),
          );
          return;
        }

        final consultant = consultants.firstWhere(
          (c) => c.id == consultantId,
          orElse: () => consultants.first,
        );

        _consultantModel = consultant;
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.errorConsultantLoadFailed)));
        return;
      }
    }

    // ConversationScreen'e yönlendir
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ConversationScreen(specialistId: _consultantModel!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final langCode = context.langCode;
    final appointmentDateTime = widget.appointment.appointmentDateTime;

    // Consultant bilgisini al
    final consultantId = widget.appointment.consultantId;
    final consultantJob = widget.appointment.job ?? '';
    String consultantDisplayName = widget.appointment.specialistName;
    String photoURL = '';

    if (consultantId != null) {
      try {
        final consultantsState = ref.watch(specialistsProvider);
        final consultants = consultantsState.specialists;
        if (consultants != null && consultants.isNotEmpty) {
          try {
            final consultant = consultants.firstWhere(
              (c) => c.id == consultantId,
              orElse: () => consultants.first,
            );
            consultantDisplayName =
                consultant.names[langCode] as String? ??
                consultant.names['en'] as String? ??
                consultant.names.values.first.toString();
            photoURL = consultant.photoURL;
            // ConsultantModel'i sakla (Talk Now butonu için)
            _consultantModel = consultant;
          } catch (e) {
            debugPrint("⚠️ Consultant bulunamadı (ID: $consultantId): $e");
          }
        }
      } catch (e) {
        debugPrint("⚠️ SpecialistsProvider hatası: $e");
      }
    }

    // Tarih formatı
    String dateText = '';
    if (appointmentDateTime != null) {
      final monthLabel = MonthStrings.name(context, appointmentDateTime.month);
      dateText =
          '$monthLabel ${appointmentDateTime.day}, ${appointmentDateTime.year}';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Appointment',
          style: GoogleFonts.quicksand(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // "Next Session" başlığı
              Text(
                'Next Session',
                style: GoogleFonts.quicksand(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),

              // Ana kart (Coach bilgisi, tarih, countdown, Join Session butonu)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coach bilgisi ve tarih
                    Row(
                      children: [
                        // Coach fotoğrafı
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2BD383),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: photoURL.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: photoURL,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const SizedBox.shrink(),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.person),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Coach ismi ve görevi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                consultantDisplayName,
                                style: GoogleFonts.quicksand(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                consultantJob.isNotEmpty
                                    ? JobConvert(consultantJob, context).call()
                                    : 'Individual Coach',
                                style: GoogleFonts.quicksand(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFA6A6A6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tarih (sağda)
                        if (dateText.isNotEmpty)
                          Text(
                            dateText,
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2BD383),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // "TIME REMAINING" başlığı
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xffF8FAFC),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Text(
                              'TIME REMAINING',
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFA6A6A6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Countdown
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCountdownItem(
                                  _remainingDays.toString().padLeft(2, '0'),
                                  l.days,
                                ),
                                _buildCountdownSeparator(),
                                _buildCountdownItem(
                                  _remainingHours.toString().padLeft(2, '0'),
                                  l.hours,
                                ),
                                _buildCountdownSeparator(),
                                _buildCountdownItem(
                                  _remainingMinutes.toString().padLeft(2, '0'),
                                  l.minutes,
                                ),
                                _buildCountdownSeparator(),
                                _buildCountdownItem(
                                  _remainingSeconds.toString().padLeft(2, '0'),
                                  l.seconds,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // "Join Session" butonu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _handleJoinSession();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2BD383),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Join Session',
                              style: GoogleFonts.quicksand(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // "Need a Talk?" kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need a Talk?',
                      style: GoogleFonts.quicksand(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start talking to our other experts',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 130,
                      height: 30,
                      child: OutlinedButton(
                        onPressed: () {
                          _handleTalkNow();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: Text(
                          'Talk Now',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2BD383),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA6A6A6),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        ':',
        style: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFC4C4C4),
        ),
      ),
    );
  }
}
