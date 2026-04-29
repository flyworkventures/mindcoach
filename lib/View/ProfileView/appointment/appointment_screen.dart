import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/widgets/app_back_button.dart';

import '../../../core/utils/context_l10n_extensions.dart';
import '../../appointments/appointment_ui.dart';
import '../../appointments/appointments_notifier.dart';
import '../../appointments/appointments_ui_provider.dart';

/// ROOT: Tabbar + üst bar
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 2 Sekmemiz var. vsync için "with SingleTickerProviderStateMixin" eklendi.
    _tabController = TabController(length: 2, vsync: this);

    // Swipe yapıldığında (ekran kaydırıldığında) butonların rengini güncellemek için:
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white, // Figma'ya göre temiz beyaz arkaplan
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ÜST BAR (Geri ikonu ve Başlık)
              Row(
                children: [
                  AppBackButton(),
                  const SizedBox(width: 8),
                  Text(
                    l10n.appointments, // Veya "Past Appointment"
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w400, // Medium
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // 2. CUSTOM TABBAR (Hap Şeklinde Butonlar)
              Row(
                children: [
                  _buildTabButton(
                    text: l10n.upcoming,
                    isActive: _tabController.index == 0,
                    onTap: () {
                      _tabController.animateTo(0);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 10), // Figma Gap: 10px
                  _buildTabButton(
                    text: l10n.completed,
                    isActive: _tabController.index == 1,
                    onTap: () {
                      _tabController.animateTo(1);
                      setState(() {});
                    },
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // 3. TAB BODY (Listelerin Göründüğü Yer)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    UpcomingAppointmentsTab(),
                    CompletedAppointmentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Özel kapsül sekme butonu tasarımı
  Widget _buildTabButton({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF21BC87) // Aktif yeşil
              : const Color(0xFF898989).withValues(alpha: 0.10), // İnaktif gri
          borderRadius: BorderRadius.circular(9999), // Tam yuvarlak
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF737373),
          ),
        ),
      ),
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

    // Empty state - Fontlar Geist olarak güncellendi
    if (appointmentsState.appointments.isEmpty || items.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noUpcomingAppointments,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9F9F9F),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero, // Fazladan boşlukları temizler
      itemCount: items.length,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref
        .watch(completedAppointmentsProvider)
        .where((e) => e.isCompleted == true)
        .toList();

    // Empty state - Fontlar Geist olarak güncellendi
    if (items.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noCompletedAppointments,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9F9F9F),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero, // Fazladan boşlukları temizler
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return AppointmentCardUi(item: item);
      },
    );
  }
}
