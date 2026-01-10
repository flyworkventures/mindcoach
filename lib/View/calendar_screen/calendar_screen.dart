import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mindcoach/core/global_constants/month_strings.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/appointment_info.dart';
import '../../core/utils/time_format_utils.dart';
import '../appointments/appointments_notifier.dart';
import '../specialists_screen/specialists_notifier.dart';

// Stil bilgileri için kullanılan sabitler
const Color _kPrimaryGreen = Color(0xFF2BD383);
const Color _kGreyBackground = Color(0xFFC4C4C4);
const Color _kLightGreyText = Color(0xFFA6A6A6);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // TableCalendar için gerekli değişkenler
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static const Color _kGradientStart = Color(0xFFFBFCFF); // #FBFCFF
  static const Color _kGradientEnd = Color(0xFFF9FAFF); // #F9FAFF

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Belirli bir gün için randevuları getiren yardımcı fonksiyon
  List<AppointmentInfo> _getAppointmentsForDay(DateTime day) {
    final appointmentsState = ref.read(appointmentsProvider);
    final map = appointmentsState.appointments;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(today)) return const <AppointmentInfo>[];

    final key = DateTime(day.year, day.month, day.day);
    return map[key] ?? const <AppointmentInfo>[];
  }



  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final appointmentsState = ref.watch(appointmentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kGradientStart, _kGradientEnd],
            stops: [0.075, 1.0133],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 33.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 32.h),

                // 1. Kalan Süre Başlığı
                Text(
                  l.timeRemainingTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 24 / 14,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10.h),

                // 2. Kalan Süre Kartı
                _buildRemainingTimeCard(context, appointmentsState),
                SizedBox(height: 25.h),

                // 3. Calendar Başlığı
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.calendar, // ARB: "Calendar"
                    style: GoogleFonts.quicksand(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 24.h / 17.h,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 15.h),

                // 4. Ay/Yıl Gösteren Kart ve Navigasyon
                _buildMonthNavigationCard(context),
                SizedBox(height: 10.h),

                // 5. Takvim Görünümü (TableCalendar)
                _buildCustomCalendar(context),
                SizedBox(height: 20.h),

                // 6. Seçilen Tarihteki Randevu Listesi
                if (_selectedDay != null) ...[
                  ..._getAppointmentsForDay(_selectedDay!).map((info) {
                    return _buildAppointmentCard(
                      context: context,
                      date: _selectedDay!,
                      info: info,
                    );
                  }),
                ],

                SizedBox(height: 80.h), // Alt navigasyon barı için boşluk
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Kalan süre kartı ---

  Widget _buildRemainingTimeCard(
    BuildContext context,
    AppointmentsState appointmentsState,
  ) {
    final l = context.l10n;

    return Container(
      width: 327.w,
      height: 84.h,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTimeItem(context, appointmentsState.remainingDays, l.days),
          _buildSeparator(),
          _buildTimeItem(context, appointmentsState.remainingHours, l.hours),
          _buildSeparator(),
          _buildTimeItem(
            context,
            appointmentsState.remainingMinutes,
            l.minutes,
          ),
          _buildSeparator(),
          _buildTimeItem(
            context,
            appointmentsState.remainingSeconds,
            l.seconds,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(BuildContext context, String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: _kPrimaryGreen,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0.0, -5.0),
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
              color: const Color(0xFFBEBEBE),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Transform.translate(
      offset: const Offset(0.0, -5.0),
      child: Text(
        ':',
        style: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1,
          color: _kGreyBackground.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // --- Ay/Yıl kartı ---

  Widget _buildMonthNavigationCard(BuildContext context) {
    final monthLabel = MonthStrings.name(context, _focusedDay.month);

    return Container(
      width: 333.w,
      height: 48.h,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$monthLabel ${_focusedDay.year}',
              style: GoogleFonts.quicksand(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 24.h / 17.h,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                        _focusedDay.day,
                      );
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                        _focusedDay.day,
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TableCalendar ---

  Widget _buildCustomCalendar(BuildContext context) {
    final langCode = context.langCode;

    return TableCalendar<AppointmentInfo>(
      startingDayOfWeek: langCode == 'en'
          ? StartingDayOfWeek.sunday
          : StartingDayOfWeek.monday,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      headerVisible: false,
      rowHeight: 40.0.h,

      calendarBuilders: CalendarBuilders<AppointmentInfo>(
        // Haftanın günleri başlığı
        dowBuilder: (dowContext, day) {
          final locale = Localizations.localeOf(dowContext);
          // Örn: en -> Mon, tr -> Pzt, de -> Mo
          final label = DateFormat.E(
            locale.toLanguageTag(),
          ).format(day); // kısa gün adı

          return Center(
            child: Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1,
                color: Colors.black,
              ),
            ),
          );
        },

        markerBuilder: (context, day, events) {
          if (events.isNotEmpty) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                width: 4.w,
                height: 4.h,
                decoration: const BoxDecoration(
                  color: _kPrimaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),

      daysOfWeekHeight: 20.0.h,

      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 24.h / 14.h,
          color: Colors.black,
        ),
        weekendStyle: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 24.h / 14.h,
          color: Colors.black54,
        ),
      ),

      calendarStyle: CalendarStyle(
        weekendTextStyle: const TextStyle(color: Colors.black54),
        defaultTextStyle: const TextStyle(color: Colors.black),
        todayDecoration: BoxDecoration(
          color: _kPrimaryGreen.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: _kPrimaryGreen,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: _kPrimaryGreen,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      eventLoader: _getAppointmentsForDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  // --- Randevu kartı ---

  Widget _buildAppointmentCard({
    required BuildContext context,
    required DateTime date,
    required AppointmentInfo info,
  }) {
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
        if (consultants != null && consultants.isNotEmpty) {
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
            debugPrint("⚠️ Consultant bulunamadı (ID: $consultantId): $e");
          }
        }
      } catch (e) {
        // Provider hatası, fallback kullan
        debugPrint("⚠️ SpecialistsProvider hatası: $e");
      }
    }
    
    // Tarih ve saat bilgisi
    final appointmentDateTime = info.appointmentDateTime ?? DateTime(date.year, date.month, date.day, 9, 0);
    final monthLabel = MonthStrings.name(context, appointmentDateTime.month);
    final formattedTime = TimeFormatUtils.formatTime(context, appointmentDateTime);
    final dateTimeText = '$monthLabel ${appointmentDateTime.day} | $formattedTime';
    
    // Status bilgisi
    final statusText = _getStatusText(context, info.status ?? 'scheduled');

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Container(
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
                child: Image.network(
                  photoURL,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      photoURL,
                      fit: BoxFit.cover,
                    );
                  },
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
                      JobConvert(consultantJob).call(),
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
                    padding: EdgeInsets.symmetric(horizontal: 5,vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(info.status ?? 'scheduled'),
                      borderRadius: BorderRadius.circular(30)
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
    switch (status.toLowerCase()) {
      case 'scheduled':
        return const Color(0xFF2BD383); // Yeşil
      case 'completed':
        return const Color(0xFF7B7B7B); // Gri
      case 'cancelled':
        return Colors.red;
      default:
        return _kLightGreyText;
    }
  }
}
