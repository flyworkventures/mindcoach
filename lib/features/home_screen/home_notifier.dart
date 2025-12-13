import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/models/appointment_info.dart';
import 'package:mindcoach/features/appointments/appointments_notifier.dart';
import 'domain/mood.dart';

class HomeState {
  final int quickActionPageIndex;
  final Mood? selectedMood;

  const HomeState({
    this.quickActionPageIndex = 0,
    this.selectedMood,
  });

  HomeState copyWith({
    int? quickActionPageIndex,
    Mood? selectedMood,
  }) {
    return HomeState(
      quickActionPageIndex: quickActionPageIndex ?? this.quickActionPageIndex,
      selectedMood: selectedMood ?? this.selectedMood,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  void setQuickActionPageIndex(int index) {
    state = state.copyWith(quickActionPageIndex: index);
  }

  void setMood(Mood mood) {
    state = state.copyWith(selectedMood: mood);
  }

  MapEntry<DateTime, AppointmentInfo>? findNextAppointment() {
    return ref.read(appointmentsProvider.notifier).findNextAppointment();
  }

  void addAppointment(DateTime dateTime, AppointmentInfo info) {
    ref.read(appointmentsProvider.notifier).upsertAppointment(dateTime, info);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
