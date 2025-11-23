# Correction du calcul des heures supplémentaires - Novembre 2025

## 🐛 Problème identifié

Le PDF de novembre 2025 affichait **6h34** d'heures supplémentaires, alors que le calcul manuel donnait **≈0h04**.

### Données de novembre 2025 (21/10 → 20/11)

- **23 jours travaillés** (semaine uniquement, pas de weekends)
- **Total travaillé** : 197h28
- **Total attendu** : 23 × 8h18 = 190h54
- **Différence brute** : 6h34

### Calcul manuel par semaine

| Semaine | Dates | Excès | Déficits | Solde net |
|---------|-------|-------|----------|-----------|
| S1 | 21-24/10 | +1h04 +0h33 +0h20 | -0h56 | **+1h01** |
| S2 | 27-31/10 | +1h50 +0h25 | -0h57 -0h33 -0h26 | **+0h19** |
| S3 | 03-07/11 | +0h18 +0h09 +0h06 | -0h38 -0h44 | **-0h49** |
| S4 | 10-14/11 | +0h31 +0h11 +0h11 +0h12 | -1h13 | **-0h08** |
| S5 | 17-20/11 | +0h03 +0h24 +0h21 | -1h07 | **-0h19** |
| **TOTAL** | | | | **+0h04** |

---

## 🔍 Analyse du bug

### Ancienne logique (INCORRECTE)

```dart
if (totalWorkedHours > expectedHours) {
  // CAS 1: Différence brute
  realOvertimeHours = totalWorkedHours - expectedHours;  // ← 6h34
}
```

Cette logique calculait :
- **6h34 = 197h28 - 190h54**
- Les déficits n'étaient **pas pris en compte** dans le calcul final
- Seule la différence globale comptait

### Nouvelle logique (CORRECTE)

```dart
// Toujours utiliser la logique excès - déficits (solde net)
if (totalExcessHours > totalDeficitHours) {
  compensatedDeficitHours = totalDeficitHours;
  realOvertimeHours = totalExcessHours - totalDeficitHours;  // ← 0h04
} else {
  compensatedDeficitHours = totalExcessHours;
  realOvertimeHours = Duration.zero;
}
```

Cette logique calcule :
- **Excès total** : somme des `(heures_jour - 8h18)` pour les jours > 8h18
- **Déficits total** : somme des `(8h18 - heures_jour)` pour les jours < 8h18
- **Heures sup réelles** : `max(0, excès - déficits)`

---

## ✅ Correction appliquée

### Fichier modifié

`lib/services/monthly_overtime_calculator.dart` (lignes 130-146)

### Changement

- ❌ **AVANT** : Utilisation du CAS 1 (`totalWorkedHours > expectedHours`)
- ✅ **APRÈS** : Utilisation uniquement de la logique `excès - déficits`

### Impact

Pour novembre 2025 :
- **Avant** : 6h34 d'heures sup
- **Après** : ≈0h04 d'heures sup

---

## 🧪 Test de validation

Un test a été créé dans `test/debug_novembre_2025_test.dart` avec les 23 jours réels de novembre 2025.

Pour l'exécuter :
```bash
flutter test test/debug_novembre_2025_test.dart
```

Le test vérifie que le calcul donne bien **≈0h04** au lieu de **6h34**.

---

## 📊 Logs de debug ajoutés

Des logs détaillés ont été ajoutés dans `CalculateOvertimeHoursUseCase.executeMonthly` pour afficher :
- La liste complète des entrées avec dates, type (weekend/semaine), et heures
- Le détail du calcul (déficits, excès, compensation)
- Le résultat final

Ces logs permettent de vérifier facilement si des jours inattendus (weekends, doublons) sont inclus dans le calcul.

---

## 🎯 Règle métier finale

**Heures supplémentaires mensuelles** = `max(0, Σ(excès jour par jour) - Σ(déficits jour par jour))`

Où :
- **Excès** = `max(0, heures_jour - 8h18)` pour chaque jour
- **Déficit** = `max(0, 8h18 - heures_jour)` pour chaque jour

Les déficits **compensent** les excès avant de calculer les heures supplémentaires finales.

---

## 📝 Notes

- La période de calcul reste **21 du mois précédent → 20 du mois courant** (période AVASAD)
- Les weekends travaillés sont toujours comptés à 100% en heures sup (non affectés par cette correction)
- Cette correction ne concerne que les **heures supplémentaires weekday**
