import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

import '../../../core/utils/context_l10n_extensions.dart';

import '../../appointments/appointment_ui.dart';
import '../../appointments/appointments_ui_provider.dart';
import '../../appointments/appointments_notifier.dart';


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

/// UPCOMING TAB
class UpcomingAppointmentsTab extends ConsumerWidget {
  const UpcomingAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(upcomingAppointmentsProvider);
    final appointmentsState = ref.watch(appointmentsProvider);

    // Loading state: appointments map boşsa ve henüz yükleniyorsa
    if (appointmentsState.appointments.isEmpty) {
      return Center(
        child: Text(
          'No upcoming appointments',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: const Color(0xFF9F9F9F),
          ),
        ),
      );
    }

    // Empty state
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No upcoming appointments',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: const Color(0xFF9F9F9F),
          ),
        ),
      );
    }else{
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
}

/// COMPLETED TAB
class CompletedAppointmentsTab extends ConsumerWidget {
  const CompletedAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(completedAppointmentsProvider).where((e)=> e.isCompleted == true).toList();
    final appointmentsState = ref.watch(appointmentsProvider);

    // Loading state: appointments map boşsa ve henüz yükleniyorsa


    // Empty state
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No completed appointments',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: const Color(0xFF9F9F9F),
          ),
        ),
      );
    }else{
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
}
