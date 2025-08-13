# User Story : Gestion des heures supplémentaires par jour

## User Story
**En tant qu'** employé  
**Je veux** pouvoir marquer certains jours comme comportant des heures supplémentaires  
**Afin de** faire apparaître correctement mes heures supplémentaires dans le rapport PDF et être rémunéré en conséquence

## Description détaillée
L'utilisateur doit pouvoir sélectionner spécifiquement les jours où il a effectué des heures supplémentaires. Par exemple, s'il a travaillé de 07h00 à 21h00 le mardi 12 juin, il peut activer les heures supplémentaires pour cette journée afin que les heures au-delà du temps normal soient comptabilisées comme supplémentaires et apparaissent dans la section appropriée du PDF.

## Critères d'acceptation

### Scénario 1 : Activation des heures supplémentaires sur une journée
```gherkin
Given je suis sur la page de saisie des heures
When je sélectionne le mardi 12 juin où j'ai travaillé de 07h00 à 21h00
And j'active l'option "Heures supplémentaires" pour cette journée
Then les heures au-delà de 8h de travail (soit 6h) sont marquées comme supplémentaires
And un indicateur visuel confirme que les heures supplémentaires sont activées pour ce jour
```

### Scénario 2 : Visualisation des heures supplémentaires dans le rapport PDF
```gherkin
Given j'ai marqué des jours avec des heures supplémentaires
When je génère le rapport PDF mensuel
Then les heures supplémentaires apparaissent dans la section dédiée du PDF
And le total des heures supplémentaires est correctement calculé
And les jours concernés sont clairement identifiés
```

### Scénario 3 : Désactivation des heures supplémentaires
```gherkin
Given j'ai activé les heures supplémentaires pour le mardi 12 juin
When je désactive l'option "Heures supplémentaires" pour cette journée
Then toutes les heures de cette journée sont comptabilisées comme heures normales
And l'indicateur visuel des heures supplémentaires disparaît
```

### Scénario 4 : Configuration du seuil d'heures normales
```gherkin
Given je suis dans les paramètres de l'application
When je configure le seuil d'heures normales journalières (par défaut 8h)
Then le calcul des heures supplémentaires se base sur ce nouveau seuil
And cette configuration s'applique à tous les jours marqués avec heures supplémentaires
```

## Valeur / Effort / Priorité

### Valeur Business : ÉLEVÉE
- Impact direct sur la paie des employés
- Conformité légale avec le droit du travail
- Amélioration significative de la précision des rapports
- Réduction des erreurs de calcul manuel

### Effort de développement : M (Medium)
- Modification de l'interface de saisie des heures
- Ajout d'un système de marquage par jour
- Adaptation de la logique de calcul des heures
- Mise à jour du générateur PDF
- Tests d'intégration nécessaires

### Priorité : MUST HAVE
- Fonctionnalité critique pour la gestion correcte des heures supplémentaires
- Impact financier direct pour les utilisateurs
- Demandé explicitement par les utilisateurs

## Notes techniques
- Nécessite de stocker un flag "heures_supplementaires" dans l'entité Pointage
- Le calcul doit tenir compte du seuil configurable (par défaut 8h/jour)
- L'interface doit permettre une activation/désactivation rapide par jour
- Le PDF doit avoir une section dédiée aux heures supplémentaires