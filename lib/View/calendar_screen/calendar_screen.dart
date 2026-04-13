import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mindcoach/core/global_constants/month_strings.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/job_convert.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/models/appointment_info.dart';
import '../appointments/appointment_detail_screen.dart';
import '../appointments/appointments_notifier.dart';
import '../specialists_screen/specialists_notifier.dart';

// Stil bilgileri için kullanılan sabitler
const Color _kPrimaryGreen = Color(0xFF21BC87);
const Color _kLightGreyText = Color(0xFF96989C);

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // TableCalendar için gerekli değişkenler
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // İptal edilen randevular için geri alma state'i
  final Map<int, DateTime> _cancelledAppointments = {};

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
    final appointments = map[key] ?? const <AppointmentInfo>[];

    // İptal edilen randevuları filtrele
    return appointments.where((appointment) {
      if (appointment.status?.toLowerCase() == 'cancelled') {
        if (appointment.appointmentId != null &&
            _cancelledAppointments.containsKey(appointment.appointmentId)) {
          final cancelledTime =
              _cancelledAppointments[appointment.appointmentId]!;
          final timeSinceCancelled = DateTime.now().difference(cancelledTime);
          return timeSinceCancelled.inSeconds < 3;
        }
        return false;
      }
      return true;
    }).toList();
  }

  // Takvim şeridi için o haftanın günlerini hesaplayan yardımcı fonksiyon
  List<DateTime> _getCurrentWeekDays(DateTime focused) {
    // Hafta Pazartesi(1) başlıyor kabul ediyoruz
    int currentWeekday = focused.weekday;
    DateTime startOfWeek = focused.subtract(Duration(days: currentWeekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Figma arkaplanı beyaz
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 24),

              // 1. Ay/Yıl Gösteren Kart ve Navigasyon
              _buildMonthNavigationHeader(context),
              const SizedBox(height: 24),

              // 2. HAFTALIK ŞERİT (Weekly Timeline)
              _buildWeeklyTimelineRow(),
              const SizedBox(height: 24),

              // 3. Takvim Görünümü (TableCalendar)
              _buildCustomCalendar(context),
              const SizedBox(height: 32),

              // 4. "Today's sessions" Başlığı
              const Text(
                "Today's sessions",
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // 5. Seçilen Tarihteki Randevu Listesi
              if (_selectedDay != null) ...[
                ..._getAppointmentsForDay(_selectedDay!).map((info) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AppointmentDetailScreen(appointment: info),
                        ),
                      );
                    },
                    child: _buildAppointmentCard(
                      context: context,
                      date: _selectedDay!,
                      info: info,
                    ),
                  );
                }),
              ],

              // 6. "Make an Appointment" Butonu
              const SizedBox(height: 8),
              _buildMakeAppointmentButton(),

              const SizedBox(height: 80), // Alt navigasyon barı için boşluk
            ],
          ),
        ),
      ),
    );
  }

  // --- Ay/Yıl Başlığı ---

  Widget _buildMonthNavigationHeader(BuildContext context) {
    final monthLabel = MonthStrings.name(
      context,
      _focusedDay.month,
    ).toUpperCase();
    final dayLabel = DateFormat('EEEE').format(_focusedDay); // 'Friday'

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
                fontSize: 14,
                fontWeight: FontWeight.w700, // Bold
                color: _kPrimaryGreen,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${_focusedDay.day}',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 32,
                    fontWeight: FontWeight.w700, // Bold
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dayLabel,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    fontWeight: FontWeight.w500, // Medium
                    color: _kLightGreyText,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                    _focusedDay.day,
                  );
                });
              },
              child: SvgPicture.asset(
                'assets/icons/ic_left.svg',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                    _focusedDay.day,
                  );
                });
              },
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

  // --- HAFTALIK ŞERİT WIDGET'I ---
  Widget _buildWeeklyTimelineRow() {
    final weekDays = _getCurrentWeekDays(_focusedDay);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: weekDays.map((date) {
        final currentDate = DateTime(date.year, date.month, date.day);
        final isSelected =
            _selectedDay != null && isSameDay(_selectedDay, currentDate);

        final isPast = currentDate.isBefore(today);
        final hasEvent = _getAppointmentsForDay(currentDate).isNotEmpty;

        final dayName = DateFormat(
          'EEE',
        ).format(date).toUpperCase(); // MON, TUE...
        final dayNumber = '${date.day}';

        // --- SEÇİLİ GÜN (Yeşil Kapsül) ---
        if (isSelected) {
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = currentDate),
            child: Container(
              height: 94, // Figma yüksekliği
              width: 50,
              decoration: BoxDecoration(
                color: _kPrimaryGreen,
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
                      fontWeight: FontWeight.w600, // SemiBold
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayNumber,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 20,
                      fontWeight: FontWeight.w700, // Bold
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Olay varsa altındaki beyaz nokta
                  if (hasEvent)
                    Container(
                      width: 4,
                      height: 4,
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

        // --- SEÇİLİ OLMAYAN GÜN ---
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = currentDate;
              _focusedDay = currentDate;
            });
          },
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
                        ? _kLightGreyText.withValues(alpha: 0.5)
                        : _kLightGreyText,
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
                // Olay varsa altındaki yeşil nokta
                if (hasEvent)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: _kPrimaryGreen,
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
      child: TableCalendar<AppointmentInfo>(
        startingDayOfWeek: langCode == 'en'
            ? StartingDayOfWeek.sunday
            : StartingDayOfWeek.monday,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        headerVisible: false,
        rowHeight: 44.0, // Figma: 44px
        daysOfWeekHeight: 40.0,

        calendarBuilders: CalendarBuilders<AppointmentInfo>(
          // Haftanın günleri başlığı (M, T, W, T, F, S, S)
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
                  color: _kLightGreyText,
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
                  width: 4,
                  height: 4,
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

        calendarStyle: CalendarStyle(
          outsideDaysVisible: false, // Önceki/sonraki ay günleri gizle
          weekendTextStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          defaultTextStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          todayDecoration: const BoxDecoration(
            color: Colors.black, // Bugün siyah yuvarlak içinde
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          selectedDecoration: const BoxDecoration(
            color: _kPrimaryGreen, // Seçili gün yeşil yuvarlak içinde
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  // --- Randevu Kartı ---

  Widget _buildAppointmentCard({
    required BuildContext context,
    required DateTime date,
    required AppointmentInfo info,
  }) {
    final langCode = context.langCode;
    final consultantId = info.consultantId;
    final consultantJob = info.job ?? '';
    String consultantDisplayName = info.specialistName;
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
          } catch (e) {
            debugPrint("⚠️ Consultant bulunamadı (ID: $consultantId): $e");
          }
        }
      } catch (e) {
        debugPrint("⚠️ SpecialistsProvider hatası: $e");
      }
    }

    final appointmentDateTime =
        info.appointmentDateTime ??
        DateTime(date.year, date.month, date.day, 9, 0);
    final formattedTime = DateFormat('HH:mm').format(appointmentDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Figma: Radius 16px
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05), // Çok hafif kenarlık
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFB6BECA,
            ).withValues(alpha: 0.3), // Hafif gölge
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol taraf resim
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(photoURL),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Orta taraf isim ve görev
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultantDisplayName,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // SemiBold
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                if (consultantJob.isNotEmpty)
                  Text(
                    JobConvert(consultantJob, context).call(),
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _kLightGreyText,
                    ),
                  ),
              ],
            ),
          ),

          // Sağ taraf Saat (Yeşil Kapsül)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _kPrimaryGreen.withValues(alpha: 0.1), // %10 saydam yeşil
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: _kPrimaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Yeni Randevu Ekle Butonu ---
  Widget _buildMakeAppointmentButton() {
    return GestureDetector(
      // GestureDetector dışarıya alındı
      onTap: () {
        // Yeni randevu ekranına yönlendirme
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: _kPrimaryGreen.withValues(alpha: 0.1), // Açık yeşil zemin
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline, color: _kPrimaryGreen, size: 20),
            SizedBox(width: 8),
            Text(
              'Make an Appointment',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _kPrimaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
