import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/View/appointments/appointments_notifier.dart';

import 'appointments_helper.dart';

class AppointmentUiItem {
  final DateTime dateTime;
  final AppointmentInfo info;

  /// UI için: geçmiş mi?
  final bool isCompleted;

  /// UI için avatar (istersen sonra SpecialistId’ye bağlarız)
  final String avatarAsset;

  const AppointmentUiItem({
    required this.dateTime,
    required this.info,
    required this.isCompleted,
    required this.avatarAsset,
  });
}

// String _avatarForSpecialistName(String name) {
//   switch (name.toLowerCase()) {
//     case 'aura':
//       return 'assets/images/kızıl.png';
//     case 'zen':
//       return 'assets/images/zen.png';
//     case 'elara':
//       return 'assets/images/elara.png';
//     case 'orion':
//       return 'assets/images/orion.png';
//     case 'cyra':
//       return 'assets/images/cyra.png';
//     default:
//       return 'assets/images/profile_avatar.jpeg';
//   }
// }

/// Map<DateTime, List<AppointmentInfo>> -> düz liste
final appointmentsListProvider = Provider<List<AppointmentUiItem>>((ref) {
  final map = ref.watch(
    appointmentsProvider.select((s) => s.appointments),
  );

  final now = DateTime.now();
  final items = <AppointmentUiItem>[];

  for (final entry in map.entries) {
    final dateTime = entry.key;
    for (final info in entry.value) {
      // appointmentDateTime varsa onu kullan, yoksa dateTime kullan
      final appointmentDateTime = info.appointmentDateTime ?? dateTime;
      
      items.add(
        AppointmentUiItem(
          dateTime: appointmentDateTime, // Tam tarih + saat
          info: info,
          isCompleted: !appointmentDateTime.isAfter(now), // appointmentDateTime'a göre completed kontrolü
          avatarAsset: avatarForKey(info.specialistName),
        ),
      );
    }
  }

  // Tarihe göre sırala (yaklaşanlar en yakın üstte, completed en yeni üstte)
  items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return items;
});

final upcomingAppointmentsProvider = Provider<List<AppointmentUiItem>>((ref) {
  final all = ref.watch(appointmentsListProvider);
  final now = DateTime.now();

  final upcoming = all.where((e) => e.dateTime.isAfter(now)).toList();
  upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime)); // yakın -> uzak
  return upcoming;
});

final completedAppointmentsProvider = Provider<List<AppointmentUiItem>>((ref) {
  final all = ref.watch(appointmentsListProvider).where((e)=> e.isCompleted == true).toList();

  final completed = all.where((e) => e.isCompleted).toList();
  completed.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // yeni -> eski
  return completed;
});
