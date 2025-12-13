import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import '../../../core/utils/context_l10n_extensions.dart';
import 'package:mindcoach/core/utils/time_format_utils.dart';
import 'package:mindcoach/features/specialists_screen/constants/specialists_strings.dart';
import 'package:mindcoach/core/global_constants/month_strings.dart';

import '../../appointments/appointment_ui.dart';
import '../../appointments/appointments_ui_provider.dart';


/// ROOT: Tabbar + üst bar
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2, // Upcoming + Completed
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.9, -1.0),
              end: Alignment(1.0, 0.9),
              colors: [
                Color(0xFFFBFCFF),
                Color(0xFFF9FAFF),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ÜST BAR
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: const Color(0xFFC4C4C4),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/svg/arrow_back.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.appointments,
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // TABBAR
                  _TabBarHeader(),

                  SizedBox(height: 16.h),

                  // TAB BODY
                  const Expanded(
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: UpcomingAppointmentsTab(),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: CompletedAppointmentsTab(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabBarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final baseStyle = GoogleFonts.quicksand(
      fontSize: 17,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Textler
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8, top:12),
          child: TabBar(
            isScrollable: true,
            labelColor: Colors.black,
            tabAlignment: TabAlignment.start,
            labelPadding: EdgeInsets.only(right: 24),

            unselectedLabelColor: const Color(0xFFC0C0C0),
            labelStyle: baseStyle,
            unselectedLabelStyle: baseStyle,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: l10n.upcoming),
              Tab(text: l10n.completed),
            ],
          ),
        ),
      ],
    );
  }
}

/// MODEL (iki tab da bunu kullanıyor)
/// MODEL (iki tab da bunu kullanıyor)
class Appointment {
  /// 'aura', 'zen', 'elara', 'orion', 'cyra' gibi key'ler
  final String specialistKey;

  /// Görüşme zamanı (tarih + saat)
  final DateTime dateTime;

  /// Mentor avatar görseli
  final String avatarAsset;

  /// Tamamlanmış mı, yaklaşan mı?
  final bool isCompleted;

  const Appointment({
    required this.specialistKey,
    required this.dateTime,
    required this.avatarAsset,
    required this.isCompleted,
  });
}

/// UPCOMING TAB
class UpcomingAppointmentsTab extends ConsumerWidget {
  const UpcomingAppointmentsTab({super.key});

  // Şimdilik dummy data, sonra provider / API'den beslersin
  List<Appointment> _items() {
    final now = DateTime.now();
    return [
      Appointment(
        specialistKey: 'elara',
        dateTime: DateTime(
          now.year,
          now.month,
          now.day,
          17,
          30,
        ), // bugün 17:30
        avatarAsset: 'assets/images/elara.png',
        isCompleted: false,
      ),
      Appointment(
        specialistKey: 'zen',
        dateTime: DateTime(
          now.year,
          now.month,
          now.day + 1,
          16,
          30,
        ), // yarın 16:30
        avatarAsset: 'assets/images/zen.png',
        isCompleted: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(upcomingAppointmentsProvider);

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppointmentCardUi(item: item);
      },
    );
  }
}

/// COMPLETED TAB
class CompletedAppointmentsTab extends ConsumerWidget {
  const CompletedAppointmentsTab({super.key});

  List<Appointment> _items() {
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    return [
      Appointment(
        specialistKey: 'aura',
        dateTime: DateTime(
          now.year,
          now.month,
          now.day - 1,
          17,
          30,
        ), // dün 17:30
        avatarAsset: 'assets/images/kızıl.png',
        isCompleted: true,
      ),
      Appointment(
        specialistKey: 'zen',
        dateTime:
        DateTime(
          twoWeeksAgo.year,
          twoWeeksAgo.month,
          twoWeeksAgo.day,
          16,
          30,
        ),  // 2 hafta önce 16:30
        avatarAsset: 'assets/images/zen.png',
        isCompleted: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(completedAppointmentsProvider);

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppointmentCardUi(item: item);
      },
    );
  }
}

/// ORTAK KART
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isCompleted = appointment.isCompleted;

    // İsim & ünvan artık ARB'den, dile göre geliyor
    final name = _specialistName(context, appointment.specialistKey);
    final title = _specialistTitle(context, appointment.specialistKey);

    // Saat formatı: tr/de => 24h, en => 12h (TimeFormatUtils)

    final nameColor =
    isCompleted ? const Color(0xFF9F9F9F) : Colors.black;
    final titleColor =
    isCompleted ? const Color(0xFF9F9F9F) : Colors.black;
    const timeColor = Color(0xFF7B7B7B);

    final borderColor =
    isCompleted ? const Color(0xFF9F9F9F) : const Color(0xFF2BD383);

    final relativeLabel = _relativeLabel(context, appointment.dateTime);
    final formattedTime = TimeFormatUtils.formatTime(
      context,
      appointment.dateTime,
    );
    final timeText = '$relativeLabel | $formattedTime';


    return Container(
      height: 99.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFDEDEDE),
          width: 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 61,
            height: 61,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 3,
              ),
              image: DecorationImage(
                image: AssetImage(appointment.avatarAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          // Metinler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: GoogleFonts.quicksand(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 24 / 17,
                    color: nameColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                    color: titleColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  timeText,
                  style: GoogleFonts.quicksand(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 18 / 11,
                    color: timeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


String _relativeLabel(BuildContext context, DateTime dateTime) {
  final l = context.l10n;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

  // target - today
  final diffDays = target.difference(today).inDays;

  // 0 => bugün
  if (diffDays == 0) {
    return l.relativeToday; // örn: "Today" / "Bugün"
  }

  // +1 => yarın
  if (diffDays == 1) {
    return l.relativeTomorrow; // "Tomorrow" / "Yarın"
  }

  // -1 => dün
  if (diffDays == -1) {
    return l.relativeYesterday; // "Yesterday" / "Dün"
  }

  // Geçmiş tarih (negatif)
  if (diffDays < -1) {
    final daysAgo = -diffDays;
    final weeks = daysAgo ~/ 7;

    if (weeks >= 1) {
      // 1 hafta+ önce
      return l.relativeWeeksAgo(weeks);
    } else {
      // 2–6 gün önce
      return l.relativeDaysAgo(daysAgo);
    }
  }

  // Gelecekte 2+ gün sonrası için şimdilik "Tarih" döndürelim
  // İstersen buraya "in X days" mantığı ekleriz.
  final monthLabel = MonthStrings.name(context, dateTime.month);
  return '$monthLabel ${dateTime.day}';
}


/// --- Helper fonksiyonlar: mentor isim & title’larını locale’e göre çekiyoruz ---

String _specialistName(BuildContext context, String key) {
  switch (key) {
    case 'aura':
      return SpecialistsStrings.auraName(context);
    case 'zen':
      return SpecialistsStrings.zenName(context);
    case 'elara':
      return SpecialistsStrings.elaraName(context);
    case 'orion':
      return SpecialistsStrings.orionName(context);
    case 'cyra':
      return SpecialistsStrings.cyraName(context);
    default:
      return key;
  }
}

String _specialistTitle(BuildContext context, String key) {
  switch (key) {
    case 'aura':
      return SpecialistsStrings.auraTitle(context);
    case 'zen':
      return SpecialistsStrings.zenTitle(context);
    case 'elara':
      return SpecialistsStrings.elaraTitle(context);
    case 'orion':
      return SpecialistsStrings.orionTitle(context);
    case 'cyra':
      return SpecialistsStrings.cyraTitle(context);
    default:
      return '';
  }
}
