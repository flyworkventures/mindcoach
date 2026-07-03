// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/repo/consultant_repo.dart';
import 'package:mindcoach/models/consultant_model.dart';

/// UZMAN ID'LERİ
enum SpecialistId { aura, zen, elara, orion, cyra }

class SpecialistsState {
  final List<ConsultantModel>? specialists; // filtrelenmiş liste
  final int selectedId;
  SpecialistsState({required this.specialists, required this.selectedId});

  SpecialistsState copyWith({
    List<ConsultantModel>? specialists,
    int? selectedId,
  }) {
    return SpecialistsState(
      specialists: specialists ?? this.specialists,
      selectedId: selectedId ?? this.selectedId,
    );
  }
}

class SpecialistsNotifier extends Notifier<SpecialistsState> {
  @override
  SpecialistsState build() {
    // İlk state - boş liste ile başla
    final initialState = SpecialistsState(specialists: [], selectedId: 0);

    // ✅ ÖNEMLİ: provider build sırasında state değiştirmiyoruz
    // API'den consultants'ları çek ve widget build bittikten sonra yükle
    Future(() {
      if (!ref.mounted) return;
      _loadConsultants();
    });

    return initialState;
  }

  /// Consultants'ları API'den yükle
  Future<void> _loadConsultants() async {
    try {
      ConsultantRepo repo = ConsultantRepo(ref);
      List<ConsultantModel>? list = await repo.getAllConsultant();
      if (!ref.mounted) return;

      if (list != null && list.isNotEmpty) {
        state = state.copyWith(specialists: list);
        debugPrint("✅ ${list.length} consultant yüklendi");
      } else {
        // Boş liste
        debugPrint("ℹ️ Consultants listesi boş veya null");
      }
    } catch (e) {
      if (!ref.mounted) return;
      debugPrint("❌ Consultants yükleme hatası: $e");
    }
  }

  /// Manuel olarak consultants'ları yeniden yükle
  Future<void> init() async {
    await _loadConsultants();
  }

  /// Tek danışmanı API'den getirir (analiz kartı gibi doğrudan açılışlar için).
  Future<ConsultantModel?> fetchConsultantById(int id) async {
    try {
      final repo = ConsultantRepo(ref);
      return await repo.getConsultantById(id);
    } catch (e) {
      debugPrint('fetchConsultantById($id) error: $e');
      return null;
    }
  }

  void selectSpecialist(int id) {
    state = state.copyWith(selectedId: id);
  }

  /*
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

  */
}

final specialistsProvider =
    NotifierProvider<SpecialistsNotifier, SpecialistsState>(
      SpecialistsNotifier.new,
    );
