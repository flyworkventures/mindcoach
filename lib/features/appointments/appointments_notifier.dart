/// lib/features/appointments/appointments_notifier.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/models/appointment_info.dart';

class AppointmentsState {
  final Map<DateTime, List<AppointmentInfo>> appointments;

  final String remainingDays;
  final String remainingHours;
  final String remainingMinutes;
  final String remainingSeconds;

  const AppointmentsState({
    required this.appointments,
    this.remainingDays = '00',
    this.remainingHours = '00',
    this.remainingMinutes = '00',
    this.remainingSeconds = '00',
  });

  AppointmentsState copyWith({
    Map<DateTime, List<AppointmentInfo>>? appointments,
    String? remainingDays,
    String? remainingHours,
    String? remainingMinutes,
    String? remainingSeconds,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      remainingDays: remainingDays ?? this.remainingDays,
      remainingHours: remainingHours ?? this.remainingHours,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class AppointmentsNotifier extends Notifier<AppointmentsState> {
  Timer? _timer;

  @override
  AppointmentsState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    // Dummy randevular
    final now = DateTime.now();

    final tomorrow18 = DateTime(now.year, now.month, now.day + 1, 18);
    final twoWeeksLater1630 = DateTime(now.year, now.month, now.day + 14, 16, 30);

    final yesterday1730 = DateTime(now.year, now.month, now.day - 1, 17, 30);
    final threeWeeksAgo1630 = DateTime(now.year, now.month, now.day - 21, 16, 30);

    final initialMap = <DateTime, List<AppointmentInfo>>{
      // Upcoming
      tomorrow18: const [
        AppointmentInfo(specialistName: 'cyra', topicKey: 'feelingGood'),
      ],
      twoWeeksLater1630: const [
        AppointmentInfo(specialistName: 'zen', topicKey: 'feelingGood'),
      ],

      // Completed
      yesterday1730: const [
        AppointmentInfo(specialistName: 'aura', topicKey: 'feelingGood'),
      ],
      threeWeeksAgo1630: const [
        AppointmentInfo(specialistName: 'elara', topicKey: 'feelingGood'),
      ],
    };

    final initialState = AppointmentsState(appointments: initialMap);

    // ✅ ÖNEMLİ: provider build sırasında state değiştirmiyoruz
    // Countdown'u widget build bittikten sonra başlatıyoruz.
    Future(() {
      if (!ref.mounted) return;
      _startCountdown();
    });

    return initialState;
  }

  // ---------------- COUNTDOWN ---------------- //

  void _startCountdown() {
    if (_timer != null) return;

    _tickCountdown();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCountdown();
    });
  }

  void _tickCountdown() {
    final next = findNextAppointment();

    if (next == null) {
      state = state.copyWith(
        remainingDays: '00',
        remainingHours: '00',
        remainingMinutes: '00',
        remainingSeconds: '00',
      );
      return;
    }

    final target = next.key;
    final now = DateTime.now();

    if (!target.isAfter(now)) {
      state = state.copyWith(
        remainingDays: '00',
        remainingHours: '00',
        remainingMinutes: '00',
        remainingSeconds: '00',
      );
      return;
    }

    final diff = target.difference(now);
    final totalSeconds = diff.inSeconds;

    final days = totalSeconds ~/ (24 * 60 * 60);
    final hours = (totalSeconds % (24 * 60 * 60)) ~/ (60 * 60);
    final minutes = (totalSeconds % (60 * 60)) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int v) => v.toString().padLeft(2, '0');

    state = state.copyWith(
      remainingDays: two(days),
      remainingHours: two(hours),
      remainingMinutes: two(minutes),
      remainingSeconds: two(seconds),
    );
  }

  MapEntry<DateTime, AppointmentInfo>? findNextAppointment() {
    final now = DateTime.now();
    final map = state.appointments;

    DateTime? bestDate;
    AppointmentInfo? bestInfo;

    for (final entry in map.entries) {
      final date = entry.key;
      final infos = entry.value;
      if (infos.isEmpty) continue;
      if (!date.isAfter(now)) continue;

      if (bestDate == null || date.isBefore(bestDate)) {
        bestDate = date;
        bestInfo = infos.first;
      }
    }

    if (bestDate == null || bestInfo == null) return null;
    return MapEntry(bestDate, bestInfo);
  }

  void upsertAppointment(DateTime dateTime, AppointmentInfo info) {
    final newMap = Map<DateTime, List<AppointmentInfo>>.from(state.appointments);

    final list = List<AppointmentInfo>.from(newMap[dateTime] ?? const []);
    list.add(info);
    newMap[dateTime] = list;

    state = state.copyWith(appointments: newMap);

    _tickCountdown();
  }
}

final appointmentsProvider =
NotifierProvider<AppointmentsNotifier, AppointmentsState>(
  AppointmentsNotifier.new,
);
