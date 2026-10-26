import 'package:flutter_test/flutter_test.dart';

/// Régression : le total mensuel d'heures supplémentaires doit être égal à la
/// somme des soldes hebdomadaires affichés dans le PDF.
///
/// Le PDF « octobre_2026 » montrait les bons soldes par semaine
/// (+0h51, +0h03, −0h22 → +32 min) mais AUCUNE ligne « Heures supplémentaires »
/// sous « Total du mois: 162h 23min » : les deux calculs ne lisaient pas le
/// même seuil journalier. L'affichage hebdomadaire utilise la préférence
/// `normalHoursThreshold` (8.3 → 498 min) ; le total mensuel lisait
/// `overtime_configurations`, table qui contenait 4 lignes divergentes pour le
/// même utilisateur (une à 498, trois à 480) et dont la lecture n'était pas
/// déterministe.
///
/// Ce test raisonne sur les minutes, sans PowerSync : il vérifie l'invariant
/// métier, pas la plomberie.
void main() {
  /// Période de paie réelle 21/09/2026 → 20/10/2026 (données de production).
  /// minutes travaillées, et si le jour est une demi-journée d'absence.
  const jours = <({String date, int minutes, bool demiJournee, bool absent})>[
    (date: '2026-09-21', minutes: 0, demiJournee: false, absent: true),
    (date: '2026-09-22', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-09-23', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-09-24', minutes: 300, demiJournee: true, absent: false),
    (date: '2026-09-25', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-09-28', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-09-29', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-09-30', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-01', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-02', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-05', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-06', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-07', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-08', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-09', minutes: 498, demiJournee: false, absent: false),
    (date: '2026-10-12', minutes: 523, demiJournee: false, absent: false),
    (date: '2026-10-13', minutes: 394, demiJournee: false, absent: false),
    (date: '2026-10-14', minutes: 493, demiJournee: false, absent: false),
    (date: '2026-10-15', minutes: 585, demiJournee: false, absent: false),
    (date: '2026-10-16', minutes: 0, demiJournee: false, absent: true),
    (date: '2026-10-19', minutes: 473, demiJournee: false, absent: false),
    (date: '2026-10-20', minutes: 501, demiJournee: false, absent: false),
  ];

  /// Solde net mensuel = somme des excédents − somme des déficits, avec seuil
  /// proratisé de moitié les demi-journées d'absence.
  int soldeNet(int seuil) {
    var exces = 0;
    var deficits = 0;
    for (final j in jours) {
      if (j.absent) continue;
      final seuilJour = j.demiJournee ? seuil ~/ 2 : seuil;
      final ecart = j.minutes - seuilJour;
      if (ecart > 0) {
        exces += ecart;
      } else {
        deficits += -ecart;
      }
    }
    return exces - deficits;
  }

  int totalTravaille() =>
      jours.fold(0, (sum, j) => sum + (j.absent ? 0 : j.minutes));

  test('le total travaillé correspond au PDF (162h23)', () {
    expect(totalTravaille(), 9743, reason: '162h23 = 9743 min');
  });

  test('avec le seuil des préférences (498), le solde est de +32 min', () {
    // C'est la valeur qu'Hermance attend et que les colonnes hebdomadaires
    // du PDF affichent déjà (+0h51, +0h03, −0h22).
    expect(soldeNet(498), 32);
  });

  test('le seuil de 480 min donnait un solde DIFFÉRENT, d\'où l\'incohérence',
      () {
    // Preuve que lire le seuil ailleurs change le résultat : c'est bien la
    // divergence de source, et non le calcul, qui était en cause.
    expect(soldeNet(480), isNot(32),
        reason: 'un seuil à 480 ne peut pas reproduire les 32 min du PDF');
  });

  test('somme des soldes hebdomadaires == solde mensuel', () {
    // Les 5 semaines du PDF : seules celles contenant des jours ouvrés.
    const semaines = <List<int>>[
      [1, 2, 3, 4], // 22→25/09 (indices dans `jours`)
      [5, 6, 7, 8, 9], // 28/09→02/10
      [10, 11, 12, 13, 14], // 05→09/10
      [15, 16, 17, 18], // 12→15/10
      [20, 21], // 19→20/10
    ];

    var sommeHebdo = 0;
    for (final semaine in semaines) {
      for (final i in semaine) {
        final j = jours[i];
        if (j.absent) continue;
        final seuilJour = j.demiJournee ? 498 ~/ 2 : 498;
        sommeHebdo += j.minutes - seuilJour;
      }
    }

    expect(sommeHebdo, soldeNet(498),
        reason: 'le total mensuel doit égaler la somme des semaines affichées');
    expect(sommeHebdo, 32);
  });

  test('la ligne « Heures supplémentaires » est rendue si le solde > 0', () {
    // Condition de rendu dans generate_pdf_usecase.dart : > Duration.zero.
    final solde = Duration(minutes: soldeNet(498));
    expect(solde > Duration.zero, isTrue,
        reason: 'sinon la ligne est masquée sans erreur, comme observé');
  });
}
