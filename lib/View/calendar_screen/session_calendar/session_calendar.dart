import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/appointment_info.dart';
import '../../../core/utils/context_l10n_extensions.dart';
import '../../appointments/appointments_notifier.dart';

class SessionCalendar extends ConsumerStatefulWidget {
  const SessionCalendar({super.key});

  @override
  ConsumerState<SessionCalendar> createState() => _SessionCalendarState();
}

class _SessionCalendarState extends ConsumerState<SessionCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDate = now;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        TableCalendar<AppointmentInfo>(
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),

          selectedDayPredicate: (day) =>
          day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day,

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDate = selectedDay;
              _focusedDay = focusedDay;
            });

            // Seçilen güne dummy bir randevu ekliyoruz
            ref.read(appointmentsProvider.notifier).upsertAppointment(
              DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
                18, // 18:00
              ),
              const AppointmentInfo(
                specialistName: "Cyra",
                topicKey: "feelingGood",
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text('${l10n.selectedDate}: ${_selectedDate.toLocal()}'),
      ],
    );
  }
}
