import 'specialist_profile.dart';

class SpecialistFilters {
  final Set<SpecialistCategory> categories;
  final Set<Availability> availability;
  final double minRating; // 0..5
  final Set<PriceTier> priceTiers;

  const SpecialistFilters({
    this.categories = const {},
    this.availability = const {},
    this.minRating = 0,
    this.priceTiers = const {},
  });

  SpecialistFilters copyWith({
    Set<SpecialistCategory>? categories,
    Set<Availability>? availability,
    double? minRating,
    Set<PriceTier>? priceTiers,
  }) {
    return SpecialistFilters(
      categories: categories ?? this.categories,
      availability: availability ?? this.availability,
      minRating: minRating ?? this.minRating,
      priceTiers: priceTiers ?? this.priceTiers,
    );
  }

  static const empty = SpecialistFilters();

  bool matchesProfile(SpecialistProfile p) {
    final categoryOk = categories.isEmpty || categories.contains(p.category);
    final availabilityOk = availability.isEmpty || availability.contains(p.availability);
    final ratingOk = p.rating >= minRating;
    final priceOk = priceTiers.isEmpty || priceTiers.contains(p.priceTier);
    return categoryOk && availabilityOk && ratingOk && priceOk;
  }

  bool get isEmptyAll =>
      categories.isEmpty && availability.isEmpty && minRating <= 0 && priceTiers.isEmpty;
}
