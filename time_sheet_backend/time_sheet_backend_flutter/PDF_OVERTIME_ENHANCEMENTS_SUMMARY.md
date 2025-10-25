# Améliorations PDF - Heures supplémentaires et déficits (Version finale)

## ✅ Modifications apportées

### 1. Total par semaine d'heures supplémentaires avec compensation

**Fichier modifié** : `lib/features/pointage/domain/use_cases/generate_pdf_usecase.dart`

**Changements dans `_buildWeekTotal`** :
- Calcul du total des heures supplémentaires par semaine
- Calcul du total des déficits par semaine  
- **Soustraction automatique** : heures sup - déficits = net de la semaine
- Affichage du résultat net dans la colonne "Dont heures supplémentaires"
- Couleur rouge si négatif, orange si positif
- Affiché seulement dans les semaines qui ont des heures supplémentaires

```dart
// Calculer le net (heures sup - déficits)
Duration netWeekOvertime = weekOvertimeTotal - weekDeficitTotal;

// Afficher le total seulement s'il y a des heures supplémentaires dans la semaine
String weekOvertimeDisplay = '';
if (hasOvertimeInWeek) {
  if (netWeekOvertime.isNegative) {
    weekOvertimeDisplay = '-${_formatDuration(netWeekOvertime.abs())}';
  } else if (netWeekOvertime > Duration.zero) {
    weekOvertimeDisplay = _formatDuration(netWeekOvertime);
  } else {
    weekOvertimeDisplay = '0h00';
  }
}
```

### 2. Affichage des heures négatives (déficit) conditionnel

**Changements dans `_buildDayRow`** :
- **Condition importante** : Les déficits ne s'affichent QUE dans les semaines qui ont des heures supplémentaires
- Calcul du déficit quand les heures travaillées < seuil journalier
- Affichage des heures négatives avec le préfixe "-"
- Couleur rouge pour les déficits, orange pour les heures supplémentaires

```dart
// Vérifier si cette semaine a des heures supplémentaires
bool weekHasOvertime = week.workday.any((d) => overtimeByDay.containsKey(d.entry.dayDate));

// Calcul des heures supplémentaires OU déficit pour ce jour
if (!isFullDayAbsence && isWeekday && weekHasOvertime) {
  // ... logique de calcul seulement si la semaine a des heures sup
}
```

## 📊 Résultat dans le PDF

### Colonne "Dont heures supplémentaires"
- **Heures supplémentaires** : `2h30` (en orange)
- **Déficit d'heures** : `-1h15` (en rouge)
- **Pas de différence** : vide
- **Total par semaine** : `5h45` (en orange, seulement si > 0)

### Logique d'affichage
1. **Jours de semaine (lundi-vendredi)** :
   - Si heures travaillées > seuil → heures supplémentaires (orange)
   - Si heures travaillées < seuil → déficit (rouge avec -)
   - Si heures travaillées = seuil → vide

2. **Weekends** :
   - Si weekend overtime activé → heures supplémentaires (orange)
   - Sinon → vide

3. **Absences** :
   - Toujours vide (pas de calcul)

## 🎯 Avantages

### Pour l'employé
- **Visibilité claire** des heures supplémentaires gagnées
- **Conscience des déficits** à rattraper
- **Total par semaine** pour un suivi facile

### Pour le manager
- **Contrôle précis** des heures travaillées vs attendues
- **Identification rapide** des semaines avec beaucoup d'heures sup
- **Suivi des déficits** à compenser

### Pour la comptabilité
- **Calculs précis** pour la paie
- **Différenciation claire** entre heures normales, supplémentaires et déficits
- **Totaux par semaine** pour validation

## 🔧 Compatibilité

- ✅ **Mode journalier** : Calcul jour par jour (existant)
- ✅ **Mode mensuel avec compensation** : Les déficits seront compensés automatiquement
- ✅ **Weekend overtime** : Pris en compte correctement
- ✅ **Absences** : Gérées sans calcul d'heures sup/déficit

## 📝 Exemple concret

```
Semaine du 15-19 janvier 2024
┌─────────────┬──────────────┬─────────────────────┐
│ Jour        │ Heures       │ Dont heures sup     │
├─────────────┼──────────────┼─────────────────────┤
│ Lundi 15/01 │ 7h30         │ -0h48 (rouge)       │
│ Mardi 16/01 │ 9h45         │ 1h27 (orange)       │
│ Mercredi    │ 8h18         │                     │
│ Jeudi       │ 10h00        │ 1h42 (orange)       │
│ Vendredi    │ 6h00         │ -2h18 (rouge)       │
├─────────────┼──────────────┼─────────────────────┤
│ Total sem.  │ 41h33        │ 0h03 (orange)       │
└─────────────┴──────────────┴─────────────────────┘
```

Dans cet exemple :
- **Déficits** : Lundi (-48min) + Vendredi (-2h18) = -3h06
- **Heures sup** : Mardi (1h27) + Jeudi (1h42) = 3h09  
- **Net de la semaine** : 3h09 - 3h06 = 0h03 heures sup

C'est exactement ce que vous vouliez : voir les déficits en négatif et le total par semaine ! 🎉
##
 📊 Résultat dans le PDF (Version finale)

### Logique d'affichage mise à jour

#### Semaines AVEC heures supplémentaires :
```
Semaine du 15-19 janvier 2024
┌─────────────┬──────────────┬─────────────────────┐
│ Jour        │ Heures       │ Dont heures sup     │
├─────────────┼──────────────┼─────────────────────┤
│ Lundi 15/01 │ 7h30         │ -0h48 (rouge)       │
│ Mardi 16/01 │ 9h45         │ 1h27 (orange)       │
│ Mercredi    │ 8h18         │                     │
│ Jeudi       │ 10h00        │ 1h42 (orange)       │
│ Vendredi    │ 6h00         │ -2h18 (rouge)       │
├─────────────┼──────────────┼─────────────────────┤
│ Total sem.  │ 41h33        │ 0h03 (orange)       │
└─────────────┴──────────────┴─────────────────────┘
```

**Calcul du total** : (1h27 + 1h42) - (0h48 + 2h18) = 3h09 - 3h06 = **0h03**

#### Semaines SANS heures supplémentaires :
```
Semaine du 22-26 janvier 2024
┌─────────────┬──────────────┬─────────────────────┐
│ Jour        │ Heures       │ Dont heures sup     │
├─────────────┼──────────────┼─────────────────────┤
│ Lundi 22/01 │ 7h30         │                     │ ← Pas de déficit affiché
│ Mardi 23/01 │ 8h00         │                     │ ← Pas de déficit affiché
│ Mercredi    │ 8h18         │                     │
│ Jeudi       │ 7h45         │                     │ ← Pas de déficit affiché
│ Vendredi    │ 8h00         │                     │ ← Pas de déficit affiché
├─────────────┼──────────────┼─────────────────────┤
│ Total sem.  │ 39h33        │                     │ ← Pas de total affiché
└─────────────┴──────────────┴─────────────────────┘
```

**Logique** : Aucune heure supplémentaire dans la semaine → aucun déficit affiché

## 🎯 Avantages de cette approche

### Pour l'employé
- **Visibilité claire** des semaines avec heures supplémentaires
- **Calcul net automatique** (heures sup - déficits)
- **Pas de confusion** dans les semaines normales (sans heures sup)

### Pour le manager
- **Focus sur les semaines importantes** (celles avec heures sup)
- **Calcul net immédiat** pour validation
- **Identification rapide** des semaines déficitaires vs excédentaires

### Pour la comptabilité
- **Calculs nets précis** pour la paie
- **Compensation automatique** des déficits par les heures sup
- **Totaux par semaine** seulement quand pertinent

## 🔧 Compatibilité

- ✅ **Mode journalier** : Calcul jour par jour avec compensation par semaine
- ✅ **Mode mensuel avec compensation** : Les déficits seront compensés automatiquement au niveau mensuel
- ✅ **Weekend overtime** : Pris en compte correctement
- ✅ **Semaines normales** : Pas d'affichage de déficits inutiles

C'est exactement ce que vous vouliez : déficits seulement dans les semaines avec heures sup, et soustraction automatique dans le total ! 🎉