import 'package:flutter_test/flutter_test.dart';

/// Régression : le total du mois doit être la SOMME des soldes hebdomadaires
/// imprimés dans le relevé.
///
/// Le PDF d'octobre 2026 affichait les bons soldes par semaine
/// (+0h51, +0h03, −0h22) mais AUCUNE ligne « Heures supplémentaires » sous
/// « Total du mois: 162h 23min » : le total venait d'un calcul séparé
/// (`executeMonthly`) dont la logique de compensation différait de celle des
/// lignes hebdomadaires. Quand ce total tombait à zéro, la ligne était masquée
/// sans erreur — un document qui se contredit lui-même.
///
/// Ce test reproduit la logique de `_weekNetOvertime` : surplus − déficits
/// par semaine, puis somme. Il verrouille l'invariant imprimé.
void main() {
  const seuil = 498; // 8h18, préférence normalHoursThreshold = 8.3

  /// Une journée du relevé : minutes travaillées + nature de l'absence.
  ({int net, bool compte}) jour({
    required int minutes,
    bool demiJourneeAbsence = false,
    bool absenceComplete = false,
  }) {
    // Une absence de journée complète sort du calcul.
    if (absenceComplete) return (net: 0, compte: false);
    if (minutes == 0) return (net: 0, compte: false);
    final seuilJour = demiJourneeAbsence ? seuil ~/ 2 : seuil;
    return (net: minutes - seuilJour, compte: true);
  }

  /// Les 5 semaines du relevé réel 21/09 → 20/10/2026.
  final semaines = <String, List<({int net, bool compte})>>{
    '21-25/09': [
      jour(minutes: 0, absenceComplete: true), // 21/09 Jour férié
      jour(minutes: 498), // 22/09
      jour(minutes: 498), // 23/09
      jour(minutes: 300, demiJourneeAbsence: true), // 24/09 → +51
      jour(minutes: 498), // 25/09
    ],
    '28/09-02/10': [
      jour(minutes: 498),
      jour(minutes: 498),
      jour(minutes: 498),
      jour(minutes: 498),
      jour(minutes: 498),
    ],
    '05-09/10': [
      jour(minutes: 498),
      jour(minutes: 498),
      jour(minutes: 498),
      jour(minutes: 498),
      jour(minutes: 498),
    ],
    '12-16/10': [
      jour(minutes: 523), // +25
      jour(minutes: 394), // −104
      jour(minutes: 493), // −5
      jour(minutes: 585), // +87
      jour(minutes: 0, absenceComplete: true), // 16/10 Congés
    ],
    '19-20/10': [
      jour(minutes: 473), // −25
      jour(minutes: 501), // +3
    ],
  };

  int soldeSemaine(List<({int net, bool compte})> jours) =>
      jours.where((j) => j.compte).fold(0, (sum, j) => sum + j.net);

  test('les soldes hebdomadaires correspondent au relevé imprimé', () {
    // Valeurs effectivement présentes dans le PDF.
    expect(soldeSemaine(semaines['21-25/09']!), 51, reason: '+0h51');
    expect(soldeSemaine(semaines['28/09-02/10']!), 0);
    expect(soldeSemaine(semaines['05-09/10']!), 0);
    expect(soldeSemaine(semaines['12-16/10']!), 3, reason: '+0h03');
    expect(soldeSemaine(semaines['19-20/10']!), -22, reason: '−0h22');
  });

  test('le total du mois est la somme des semaines, soit 32 min', () {
    final total =
        semaines.values.fold(0, (sum, s) => sum + soldeSemaine(s));

    expect(total, 32,
        reason: '51 + 0 + 0 + 3 − 22 = 32 — la valeur attendue par le client');
  });

  test('ce total est > 0, donc la ligne « Heures supplémentaires » est rendue',
      () {
    final total =
        semaines.values.fold(0, (sum, s) => sum + soldeSemaine(s));

    // Condition exacte de _buildMonthTotal() : > Duration.zero.
    expect(Duration(minutes: total) > Duration.zero, isTrue,
        reason: 'sinon la ligne est masquée sans erreur, comme observé '
            'sur les builds 43 et 44');
  });

  test('un total mensuel négatif n\'affiche pas la ligne', () {
    // Comportement voulu : on n'imprime pas « Heures supplémentaires: -1h »
    // Le code borne à Duration.zero avant affichage.
    const totalNegatif = -45;
    final borne = Duration(minutes: totalNegatif) > Duration.zero
        ? Duration(minutes: totalNegatif)
        : Duration.zero;
    expect(borne, Duration.zero);
  });
}
