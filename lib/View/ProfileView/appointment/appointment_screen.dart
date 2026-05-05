import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';
import 'package:mindcoach/core/widgets/app_back_button.dart';

import '../../../core/utils/context_l10n_extensions.dart';
import '../../appointments/appointments_notifier.dart';
import '../../appointments/appointment_ui.dart';
import '../../appointments/completed_appointment_ui.dart';
import '../../appointments/appointments_ui_provider.dart';

/// ROOT: Tabbar + üst bar
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 2 Sekmemiz var. vsync için "with SingleTickerProviderStateMixin" eklendi.
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 160),
    );

    // Ekran açıldığında randevuları API'den taze çek.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentsProvider.notifier).refresh();
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
      backgroundColor: Colors.white,
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
                    l10n.appointments,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // 2. CUSTOM TABBAR - ListenableBuilder ile efficient rebuild
              ListenableBuilder(
                listenable: _tabController,
                builder: (context, child) {
                  return Row(
                    children: [
                      _buildTabButton(
                        text: l10n.upcoming,
                        isActive: _tabController.index == 0,
                        onTap: () {
                          _tabController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                          );
                          // ❌ setState() kaldırıldı - ListenableBuilder trigger ediyor
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildTabButton(
                        text: l10n.completed,
                        isActive: _tabController.index == 1,
                        onTap: () {
                          _tabController.animateTo(
                            1,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                          );
                          // ❌ setState() kaldırıldı
                        },
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 24.h),

              // 3. TAB BODY - NeverScrollableScrollPhysics ile swipe disable
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Swipe disable
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

  // Özel kapsül sekme butonu - AnimatedContainer ile smooth renk
  Widget _buildTabButton({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF21BC87)
              : const Color(0xFF898989).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF737373),
          ),
          child: Text(text),
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

    // ❌ KÖTÜ: appointmentsState.watch kaldırıldı - gereksiz rebuild trigger ediyor
    // ✅ İYİ: Sadece items'ı watch et

    if (items.isEmpty) {
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
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
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
    // completed provider zaten status/zaman kurallarını uyguluyor.
    final items = ref.watch(completedAppointmentsProvider);

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
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CompletedAppointmentCardUi(item: item);
      },
    );
  }
}
