# User Story : Gestion Automatique des Jours Fériés par Canton

## User Story
**En tant qu'** employé travaillant en Suisse  
**Je veux** que l'application reconnaisse automatiquement les jours fériés de mon canton  
**Afin de** ne pas avoir à les saisir manuellement et qu'ils soient correctement identifiés dans mes rapports PDF

## Contexte
En Suisse, les jours fériés varient selon les cantons. Chaque canton a ses propres jours fériés officiels en plus des jours fériés nationaux. Cette fonctionnalité permettrait d'automatiser la reconnaissance de ces jours et d'éviter les erreurs de saisie manuelle.

### Solution actuelle (workaround)
Jusqu'à présent, les utilisateurs contournent cette limitation en :
- Créant une absence de type "Autre" 
- Sélectionnant la journée complète
- Saisissant manuellement "Férié" dans le champ description/raison
- Répétant cette opération pour chaque jour férié

Cette approche est fastidieuse, source d'erreurs et ne permet pas une identification claire des jours fériés dans les rapports.

## Critères d'acceptation

### Scénario 1 : Configuration du canton dans les paramètres
```gherkin
Given je suis dans la page des paramètres de l'application
When je sélectionne mon canton dans la liste déroulante (ex: Vaud, Genève, Zurich, etc.)
Then mon choix est sauvegardé dans mes préférences utilisateur
And la liste des jours fériés du canton sélectionné est chargée pour l'année en cours
```

### Scénario 2 : Marquage automatique des jours fériés
```gherkin
Given j'ai configuré mon canton comme "Vaud"
And le 2 janvier est un jour férié dans le canton de Vaud
When j'accède à la vue calendrier ou pointage du 2 janvier
Then le jour est automatiquement marqué comme "Jour férié"
And aucune saisie de pointage n'est requise pour ce jour
And le jour apparaît avec un indicateur visuel distinct (icône ou couleur)
```

### Scénario 3 : Affichage dans le PDF mensuel
```gherkin
Given j'ai des jours fériés dans mon mois (ex: 1er janvier, 2 janvier pour Vaud)
When je génère le PDF de ma feuille de temps mensuelle
Then les jours fériés apparaissent clairement identifiés avec la mention "Férié"
And les heures sont comptabilisées selon le temps de travail normal (8h18)
And le total mensuel inclut correctement les heures des jours fériés
```

### Scénario 4 : Changement de canton
```gherkin
Given j'ai configuré le canton "Genève" et des pointages existants
When je change mon canton pour "Zurich"
Then un message d'avertissement m'informe que les jours fériés seront recalculés
And après confirmation, les nouveaux jours fériés du canton de Zurich sont appliqués
And les anciens jours fériés spécifiques à Genève sont supprimés pour les dates futures
```

### Scénario 5 : Gestion des jours fériés nationaux vs cantonaux
```gherkin
Given le 1er août est un jour férié national
And le 2 janvier est férié uniquement dans le canton de Vaud
When je consulte le calendrier avec le canton "Vaud" configuré
Then le 1er août apparaît comme "Férié national"
And le 2 janvier apparaît comme "Férié cantonal (VD)"
And les deux types sont traités identiquement pour le calcul des heures
```

### Scénario 6 : Migration des absences "Férié" existantes
```gherkin
Given j'ai des absences de type "Autre" avec la description "Férié"
And je configure mon canton pour la première fois
When le système détecte ces absences manuelles
Then il me propose de les convertir en jours fériés officiels
And après confirmation, les absences sont remplacées par les marqueurs de jours fériés
And l'historique conserve une trace de cette migration
```

## Notes techniques
- Nécessite une base de données des jours fériés par canton
- Les jours fériés doivent être mis à jour annuellement
- Prévoir une API ou un fichier de configuration pour les jours fériés
- Gérer les cas particuliers (demi-journées fériées dans certains cantons)
- Support des 26 cantons suisses
- Migration des données existantes (absences "Autre" avec mention "Férié")

## Valeur / Effort / Priorité
- **Valeur Business** : Élevée - Gain de temps significatif et réduction des erreurs pour tous les utilisateurs suisses
- **Effort** : L (Large) - Nécessite la création d'une base de données complète des jours fériés et l'intégration dans plusieurs modules
- **Priorité** : Should Have - Fonctionnalité très utile mais l'application reste utilisable sans elle
- **Estimation** : 5-8 jours de développement

## Dépendances
- Module de préférences utilisateur
- Système de génération PDF
- Module calendrier
- Module d'absence (pour la migration)
- Base de données des jours fériés suisses (à créer ou intégrer)

## Risques
- Maintenance annuelle requise pour mettre à jour les jours fériés
- Complexité des règles cantonales (certains jours fériés dépendent de calculs religieux)
- Gestion des changements de canton en cours d'année
- Migration des données existantes peut être complexe si les descriptions ne sont pas uniformes