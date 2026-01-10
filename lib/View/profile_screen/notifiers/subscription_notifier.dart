// lib/features/profile/subscription_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlanType { free, premium }

class SubscriptionState {
  final PlanType plan;
  const SubscriptionState({required this.plan});

  SubscriptionState copyWith({PlanType? plan}) =>
      SubscriptionState(plan: plan ?? this.plan);
}

class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() => const SubscriptionState(plan: PlanType.free);

  void setPlan(PlanType plan) => state = state.copyWith(plan: plan);
}

final subscriptionProvider =
NotifierProvider<SubscriptionNotifier, SubscriptionState>(
  SubscriptionNotifier.new,
);
