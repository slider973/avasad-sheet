# User Story : Configuration de la Période de Calcul Mensuelle

## User Story
**En tant qu'** employé ou administrateur RH  
**Je veux** pouvoir configurer les jours de début et fin de période de calcul mensuel  
**Afin de** adapter l'application aux règles spécifiques de mon entreprise pour le calcul des heures mensuelles

## Contexte
Actuellement, l'application utilise une période fixe du 21 du mois précédent au 20 du mois en cours pour calculer les heures mensuelles. Cette règle est spécifique à HeyTalent mais d'autres entreprises peuvent avoir des périodes différentes (du 1er au dernier jour du mois, du 26 au 25, etc.). Cette fonctionnalité permettrait de paramétrer cette période selon les besoins de chaque entreprise.

## Critères d'acceptation

### Scénario 1 : Configuration initiale de la période
```gherkin
Given je suis dans la page des paramètres de l'application
When j'accède à la section "Période de calcul mensuel"
Then je vois les champs "Jour de début" et "Jour de fin" avec les valeurs par défaut (21 et 20)
And je peux modifier ces valeurs entre 1 et 31
And un texte explicatif indique "La période s'étend du [jour début] du mois précédent au [jour fin] du mois en cours"
```

### Scénario 2 : Sauvegarde et application de la nouvelle période
```gherkin
Given j'ai configuré la période du 26 au 25
When je sauvegarde les paramètres
Then la nouvelle période est enregistrée dans mes préférences
And tous les calculs futurs (anomalies, PDF, statistiques) utilisent cette nouvelle période
And un message de confirmation s'affiche "Période de calcul mise à jour avec succès"
```

### Scénario 3 : Impact sur la génération de PDF
```gherkin
Given j'ai configuré la période du 1er au 31
And nous sommes le 15 mars 2024
When je génère le PDF pour le mois en cours
Then le PDF contient les entrées du 1er mars au 31 mars 2024
And le titre du PDF indique "Feuille de temps - Mars 2024 (01/03 - 31/03)"
```

### Scénario 4 : Gestion des jours invalides
```gherkin
Given je tente de configurer le jour de fin à 31
And nous sommes en février (28 ou 29 jours)
When le système calcule la période
Then il ajuste automatiquement au dernier jour du mois (28 ou 29 février)
And un message informatif apparaît "Le jour de fin a été ajusté au dernier jour du mois pour les mois courts"
```

### Scénario 5 : Migration des données existantes
```gherkin
Given j'ai des données calculées avec l'ancienne période (21-20)
When je change la période pour (1-31)
Then un avertissement s'affiche "Les rapports et anomalies passés ne seront pas recalculés"
And seuls les nouveaux calculs utilisent la nouvelle période
And je peux toujours consulter l'historique avec l'ancienne période
```

### Scénario 6 : Validation de cohérence
```gherkin
Given je tente de configurer le jour de début à 25 et le jour de fin à 10
When je sauvegarde
Then le système détecte que la période est valide (25 du mois N-1 au 10 du mois N)
And la période couvre bien environ 30 jours
And la configuration est acceptée
```

## Notes techniques
- Les valeurs doivent être stockées dans les préférences utilisateur
- Tous les modules utilisant la période (anomalies, PDF, statistiques, génération automatique) doivent être mis à jour
- Gérer les cas particuliers des mois courts (février, mois de 30 jours)
- L'interface doit clairement expliquer la logique de calcul
- Prévoir une valeur par défaut (21-20) pour la compatibilité arrière

## Valeur / Effort / Priorité
- **Valeur Business** : Moyenne à Élevée - Permet l'adoption de l'application par d'autres entreprises avec des règles différentes
- **Effort** : M (Medium) - Nécessite de modifier plusieurs modules mais la logique reste simple
- **Priorité** : Should Have - Important pour la flexibilité mais non bloquant pour l'utilisation actuelle
- **Estimation** : 3-4 jours de développement

## Dépendances
- Module de préférences utilisateur
- Module de calcul des anomalies
- Module de génération PDF
- Module de génération automatique des pointages
- Module de statistiques (dashboard, rapports)

## Risques
- Impact sur tous les calculs de l'application
- Confusion possible pour les utilisateurs si mal expliqué
- Gestion des données historiques avec différentes périodes