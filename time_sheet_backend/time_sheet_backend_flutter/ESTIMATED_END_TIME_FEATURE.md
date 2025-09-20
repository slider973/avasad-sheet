# Fonctionnalité : Heure de Fin Estimée

## Description

Une nouvelle **card élégante** qui affiche l'heure de fin de journée estimée, se réajustant automatiquement en fonction du temps de pause et du temps de travail effectué.

## Fonctionnalités

### ✅ Calcul Intelligent
- **Temps de travail effectif** : Calcule précisément le temps travaillé (sans les pauses)
- **Temps de pause** : Inclut toutes les pauses prises + pause actuelle si en cours
- **Réajustement automatique** : L'heure de fin se met à jour en temps réel

### ✅ Interface Utilisateur
- **Card moderne** : Design cohérent avec les autres cards de l'application
- **Mise à jour temps réel** : Actualisation toutes les 30 secondes
- **Indicateurs visuels** : Couleurs et icônes selon l'état (travail, pause, objectif atteint)

### ✅ États Gérés
- **Non commencé** : Card masquée
- **En cours de travail** : Affiche l'heure de fin estimée + temps restant
- **En pause** : Badge "En pause" + ajustement automatique de l'heure de fin
- **Objectif atteint** : Badge "Objectif journalier atteint" + card verte
- **Terminé** : Card masquée

## Logique de Calcul

### Formule de Base
```
Heure de fin = Heure de début + Temps travaillé + Temps de pause + Temps restant
```

### Détails
1. **Temps travaillé** : Somme de tous les segments de travail (Entrée → Début pause, Fin pause → Sortie)
2. **Temps de pause** : Somme de toutes les pauses (Début pause → Fin pause) + pause actuelle
3. **Temps restant** : 8h - temps travaillé (si positif)

### Exemples
- **09:00 Entrée, 12:00 Pause (3h travaillées)** → Fin estimée : 18:00
- **09:00 Entrée, 12:00 Pause, 13:00 Reprise (4h travaillées)** → Fin estimée : 18:00
- **En pause depuis 30min** → Heure de fin repoussée de 30min automatiquement

## Avantages UX

✅ **Visibilité claire** : L'utilisateur sait exactement quand il peut partir  
✅ **Motivation** : Voir le temps restant encourage à rester concentré  
✅ **Planification** : Permet de planifier sa fin de journée  
✅ **Transparence** : Calcul transparent et compréhensible  
✅ **Temps réel** : Pas besoin de rafraîchir, tout se met à jour automatiquement  

## Intégration

### Emplacement
La card apparaît **juste après le chrono** et **avant la card des heures supplémentaires**, créant un flux logique d'informations.

### Responsive
- **Mobile** : Card pleine largeur avec marges
- **Tablette** : S'adapte automatiquement
- **Design cohérent** : Même style que les autres cards

## Code

### Fichier Principal
`lib/features/pointage/presentation/widgets/pointage_widget/estimated_end_time_card.dart`

### Intégration
Ajoutée dans `pointage_layout.dart` avec un simple :
```dart
EstimatedEndTimeCard(
  pointages: pointages,
  currentState: etatActuel,
),
```

## Performance

- **Timer optimisé** : Mise à jour toutes les 30 secondes seulement
- **Calculs légers** : Algorithmes simples et efficaces
- **Mémoire** : Timer automatiquement nettoyé lors de la destruction du widget
- **Conditionnelle** : Card masquée quand non nécessaire

## Prochaines Améliorations Possibles

1. **Personnalisation** : Permettre de changer l'objectif journalier (6h, 7h, 8h)
2. **Notifications** : Alerter quand l'objectif est atteint
3. **Historique** : Afficher les heures de fin des jours précédents
4. **Prédiction** : Utiliser l'historique pour améliorer les estimations

Cette fonctionnalité répond parfaitement à votre demande d'avoir une **card séparée** avec l'**heure de fin qui se réajuste** automatiquement ! 🎯