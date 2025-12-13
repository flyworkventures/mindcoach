import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/specialist_filters.dart';
import 'domain/specialist_profile.dart';

/// UZMAN ID'LERİ
enum SpecialistId { aura, zen, elara, orion, cyra }

class SpecialistsState {
  final List<SpecialistId> specialists; // filtrelenmiş liste
  final SpecialistId? selected;

  // filtre state
  final SpecialistFilters filters;

  // dummy profil bilgileri (ileride API'den gelecek)
  final Map<SpecialistId, SpecialistProfile> profiles;

  const SpecialistsState({
    required this.specialists,
    required this.profiles,
    this.selected,
    this.filters = SpecialistFilters.empty,
  });

  SpecialistsState copyWith({
    List<SpecialistId>? specialists,
    Map<SpecialistId, SpecialistProfile>? profiles,
    SpecialistId? selected,
    SpecialistFilters? filters,
  }) {
    return SpecialistsState(
      specialists: specialists ?? this.specialists,
      profiles: profiles ?? this.profiles,
      selected: selected ?? this.selected,
      filters: filters ?? this.filters,
    );
  }
}

class SpecialistsNotifier extends Notifier<SpecialistsState> {
  @override
  SpecialistsState build() {
    // Şimdilik random/dummy özellikler (sonra değişir)
    final profiles = <SpecialistId, SpecialistProfile>{
      SpecialistId.aura: const SpecialistProfile(
        id: SpecialistId.aura,
        category: SpecialistCategory.mentorship,
        availability: Availability.availableNow,
        rating: 4.8,
        priceTier: PriceTier.premium,
      ),
      SpecialistId.zen: const SpecialistProfile(
        id: SpecialistId.zen,
        category: SpecialistCategory.relationship,
        availability: Availability.today,
        rating: 4.5,
        priceTier: PriceTier.standard,
      ),
      SpecialistId.elara: const SpecialistProfile(
        id: SpecialistId.elara,
        category: SpecialistCategory.mindfulness,
        availability: Availability.thisWeek,
        rating: 4.2,
        priceTier: PriceTier.budget,
      ),
      SpecialistId.orion: const SpecialistProfile(
        id: SpecialistId.orion,
        category: SpecialistCategory.focus,
        availability: Availability.today,
        rating: 4.1,
        priceTier: PriceTier.standard,
      ),
      SpecialistId.cyra: const SpecialistProfile(
        id: SpecialistId.cyra,
        category: SpecialistCategory.anxiety,
        availability: Availability.availableNow,
        rating: 4.7,
        priceTier: PriceTier.standard,
      ),
    };

    final all = const [
      SpecialistId.aura,
      SpecialistId.zen,
      SpecialistId.elara,
      SpecialistId.orion,
      SpecialistId.cyra,
    ];

    return SpecialistsState(
      specialists: all,
      profiles: profiles,
      filters: SpecialistFilters.empty,
    );
  }

  void selectSpecialist(SpecialistId id) {
    state = state.copyWith(selected: id);
  }

  // ---- Filters API ----

  void setFilters(SpecialistFilters filters) {
    final filtered = _applyFilters(filters, state.profiles);
    state = state.copyWith(filters: filters, specialists: filtered);
  }

  void resetFilters() {
    setFilters(SpecialistFilters.empty);
  }

  List<SpecialistId> _applyFilters(
      SpecialistFilters filters,
      Map<SpecialistId, SpecialistProfile> profiles,
      ) {
    final all = profiles.keys.toList();
    all.sort((a, b) => a.index.compareTo(b.index)); // stabil order
    return all.where((id) => filters.matchesProfile(profiles[id]!)).toList();
  }
}

final specialistsProvider =
NotifierProvider<SpecialistsNotifier, SpecialistsState>(
  SpecialistsNotifier.new,
);
