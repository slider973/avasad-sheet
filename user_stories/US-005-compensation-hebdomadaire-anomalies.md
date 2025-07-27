# User Story : Compensation Hebdomadaire des Anomalies

## User Story
**En tant qu'** employé  
**Je veux** que les anomalies journalières soient automatiquement compensées lorsque mon temps de travail hebdomadaire est conforme  
**Afin de** ne pas être pénalisé pour des variations journalières lorsque mon total hebdomadaire est correct

## Contexte
Actuellement, le système génère des anomalies pour chaque journée où le temps de travail n'atteint pas l'objectif quotidien. Cependant, dans la pratique, un employé peut compenser des journées courtes par des journées plus longues dans la même semaine. Si le total hebdomadaire est conforme (41h30), les anomalies journalières ne devraient plus être considérées comme problématiques.

## Critères d'acceptation

### Scénario 1 : Compensation hebdomadaire complète
```gherkin
Given un employé a travaillé 6h lundi, 8h mardi, 10h mercredi, 9h jeudi et 8.5h vendredi
And le total hebdomadaire est de 41h30 (objectif atteint)
When le système calcule les anomalies
Then aucune anomalie d'heures insuffisantes ne doit apparaître pour le lundi
And le statut de la semaine doit indiquer "Objectif hebdomadaire atteint"
```

### Scénario 2 : Compensation hebdomadaire partielle
```gherkin
Given un employé a travaillé 6h lundi, 7h mardi, 8h mercredi, 8h jeudi et 8h vendredi
And le total hebdomadaire est de 37h (en dessous de 41h30)
When le système calcule les anomalies
Then les anomalies journalières doivent toujours apparaître
And une anomalie hebdomadaire doit indiquer "4h30 manquantes sur la semaine"
```

### Scénario 3 : Affichage différencié des anomalies compensées
```gherkin
Given des anomalies journalières existent mais sont compensées sur la semaine
When l'utilisateur consulte la page des anomalies
Then les anomalies compensées doivent apparaître avec un style visuel différent (grisées ou barrées)
And une mention "Compensé sur la semaine" doit être affichée
And les anomalies non compensées restent en rouge
```

### Scénario 4 : Calcul de compensation multi-semaines
```gherkin
Given l'utilisateur consulte les anomalies du mois
And certaines semaines ont des totaux conformes et d'autres non
When le système affiche les anomalies
Then seules les anomalies des semaines non conformes sont actives
And un résumé mensuel indique le nombre de semaines conformes vs non conformes
```

## Notes techniques
- Le calcul doit se faire sur la période du lundi au vendredi (semaine de travail)
- L'objectif hebdomadaire est paramétrable (actuellement 41h30)
- Les anomalies compensées restent dans l'historique mais avec un statut "compensé"
- La logique de compensation doit être intégrée dans `AnomalyDetectorFactory`

## Valeur / Effort / Priorité
- **Valeur Business** : Élevée - Améliore significativement l'expérience utilisateur et reflète la réalité du travail flexible
- **Effort** : M (Medium) - Nécessite une refonte de la logique de détection d'anomalies et de l'affichage
- **Priorité** : Must Have - Les utilisateurs se plaignent des fausses alertes d'anomalies
- **Estimation** : 3-5 jours de développement

## Dépendances
- Module de détection d'anomalies existant
- Système de calcul des heures hebdomadaires
- Interface d'affichage des anomalies