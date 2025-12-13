import '../specialists_notifier.dart';

enum SpecialistCategory { mentorship, relationship, mindfulness, anxiety, focus }
enum Availability { availableNow, today, thisWeek }
enum PriceTier { budget, standard, premium }

class SpecialistProfile {
  final SpecialistId id;
  final SpecialistCategory category;
  final Availability availability;
  final double rating; // 0-5
  final PriceTier priceTier;

  const SpecialistProfile({
    required this.id,
    required this.category,
    required this.availability,
    required this.rating,
    required this.priceTier,
  });
}
