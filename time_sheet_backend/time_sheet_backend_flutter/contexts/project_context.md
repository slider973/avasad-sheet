# Contexte Projet - time_sheet

## Vue d'ensemble
`time_sheet` est une application mobile Flutter conçue pour HeyTalent permettant de gérer le temps de travail des employés. L'application permet de pointer l'entrée/sortie, suivre les pauses, et visualiser le temps de travail avec un timer élégant style horloge.

## Architecture
Le projet suit une architecture modulaire Flutter avec une séparation claire des responsabilités :

- **`lib/features/`**: Contient les différentes fonctionnalités de l'application organisées par domaine métier
- **`lib/services/`**: Services partagés pour la gestion des données, API, et logique métier
- **`lib/config/`**: Configuration de l'application (thèmes, constantes, etc.)
- **`lib/utils/`**: Utilitaires et helpers partagés
- **`lib/enum/`**: Énumérations utilisées dans l'application
- **`assets/`**: Ressources statiques (images, fonts, etc.)
- **`test/`**: Tests unitaires et d'intégration
