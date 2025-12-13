import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/context_l10n_extensions.dart';
import '../../appointments/appointments_notifier.dart';

class CountdownTimer extends ConsumerWidget {
  const CountdownTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);
    final l10n = context.l10n;

    final days = state.remainingDays;
    final hours = state.remainingHours;
    final minutes = state.remainingMinutes;
    final seconds = state.remainingSeconds;

    final isZero =
        days == '00' && hours == '00' && minutes == '00' && seconds == '00';

    final timeRemaining =
    isZero ? l10n.meetingStarted : '$days:$hours:$minutes:$seconds';

    return Column(
      children: [
        Text(
          l10n.timeRemainingTitle,
          style: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          shadowColor: Colors.black.withOpacity(0.4),
          elevation: 4,
          child: Container(
            width: 327,
            height: 84,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeRemaining,
                      style: const TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w600,
                        fontSize: 40,
                        color: Color(0xFF2BD383),
                      ),
                    ),
                  ],
                ),
                Text(
                  "${l10n.days} ${l10n.hours} ${l10n.minutes} ${l10n.seconds}",
                  style: const TextStyle(
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
