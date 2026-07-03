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

  /// İlk yükleme sürüyor mu (spinner göstermek için).
  final bool isLoading;

  /// Yükleme denendi ve başarısız oldu (retry butonu göstermek için).
  final bool loadFailed;

  SpecialistsState({
    required this.specialists,
    required this.selectedId,
    this.isLoading = false,
    this.loadFailed = false,
  });

  SpecialistsState copyWith({
    List<ConsultantModel>? specialists,
    int? selectedId,
    bool? isLoading,
    bool? loadFailed,
  }) {
    return SpecialistsState(
      specialists: specialists ?? this.specialists,
      selectedId: selectedId ?? this.selectedId,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
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

  /// Consultants'ları API'den yükle.
  ///
  /// Uzak DB bağlantısı kararsız olduğunda ilk istek boş/başarısız dönebiliyor;
  /// bu yüzden birkaç kez artan gecikmeyle yeniden denenir. Hepsi başarısız
  /// olursa [SpecialistsState.loadFailed] true olur ve UI retry butonu gösterir.
  Future<void> _loadConsultants({int maxAttempts = 3}) async {
    // Zaten dolu liste varsa spinner gösterme (sessiz yenileme).
    final hasData = (state.specialists?.isNotEmpty ?? false);
    if (!hasData) {
      state = state.copyWith(isLoading: true, loadFailed: false);
    }

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final repo = ConsultantRepo(ref);
        final list = await repo.getAllConsultant();
        if (!ref.mounted) return;

        if (list != null && list.isNotEmpty) {
          state = state.copyWith(
            specialists: list,
            isLoading: false,
            loadFailed: false,
          );
          debugPrint("✅ ${list.length} consultant yüklendi (deneme $attempt)");
          return;
        }
        debugPrint("ℹ️ Consultants boş döndü (deneme $attempt/$maxAttempts)");
      } catch (e) {
        if (!ref.mounted) return;
        debugPrint("❌ Consultants yükleme hatası (deneme $attempt): $e");
      }

      // Son deneme değilse artan gecikmeyle tekrar dene.
      if (attempt < maxAttempts) {
        await Future.delayed(Duration(milliseconds: 600 * attempt));
        if (!ref.mounted) return;
      }
    }

    // Tüm denemeler başarısız — mevcut veriyi koru, hata bayrağını kaldır.
    if (!ref.mounted) return;
    final stillEmpty = (state.specialists?.isEmpty ?? true);
    state = state.copyWith(
      isLoading: false,
      loadFailed: stillEmpty,
    );
  }

  /// Manuel olarak consultants'ları yeniden yükle (retry butonu / ilk açılış).
  Future<void> init() async {
    await _loadConsultants();
  }

  /// UI'dan retry için: hata durumunu sıfırlayıp yeniden dener.
  Future<void> retry() async {
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
