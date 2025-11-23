/// Use case pour calculer le montant d'un déplacement kilométrique
class CalculateMileageUseCase {
  /// Calcule le montant d'un déplacement (km × taux)
  double execute({
    required int distanceKm,
    required double mileageRate,
  }) {
    return distanceKm * mileageRate;
  }

  /// Récupère le taux kilométrique par défaut (Suisse: 0.70 CHF/km)
  double getDefaultMileageRate() {
    return 0.70;
  }

  /// Valide qu'une distance est cohérente
  bool isValidDistance(int distanceKm) {
    return distanceKm > 0 && distanceKm <= 1000; // Max 1000km par trajet
  }

  /// Valide qu'un taux est cohérent
  bool isValidRate(double rate) {
    return rate > 0 && rate <= 5.0; // Max 5 CHF/km
  }
}
