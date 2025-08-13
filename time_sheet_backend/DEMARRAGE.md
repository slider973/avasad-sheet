# Guide de Démarrage - Time Sheet Backend

## Prérequis

1. **Docker Desktop** installé et lancé
2. **Dart SDK** (version 3.0+)
3. **Flutter SDK** (version 3.0+)
4. **Serverpod CLI** installé :
   ```bash
   dart pub global activate serverpod_cli
   ```

## 1. Démarrer les Services Docker

### Terminal 1 - Base de données
```bash
cd /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend/time_sheet_backend_server
docker-compose up -d
```

Cela démarre :
- PostgreSQL sur le port 8090
- Redis sur le port 8091

Vérifier que les conteneurs sont lancés :
```bash
docker ps
```

## 2. Initialiser la Base de Données

### Créer les tables (première fois uniquement)
```bash
cd time_sheet_backend_server
serverpod create-migration --force
```

## 3. Démarrer le Serveur Backend

### Terminal 2 - Serveur Serverpod
```bash
cd /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend/time_sheet_backend_server
dart bin/main.dart --apply-migrations
```

Le serveur démarre sur :
- API : http://localhost:8080
- Insights (monitoring) : http://localhost:8081
- Web server : http://localhost:8082

## 4. Démarrer l'Application Flutter

### Terminal 3 - App Flutter
```bash
cd /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend/time_sheet_backend_flutter
flutter pub get
flutter run
```

Choisir la plateforme :
- 1 pour iOS Simulator
- 2 pour Android
- 3 pour Chrome (web)
- 4 pour macOS

## 5. Vérifier que tout fonctionne

1. Ouvrir http://localhost:8081 pour voir Serverpod Insights
2. L'app Flutter devrait se connecter au backend
3. Vérifier les logs du serveur pour voir les requêtes

## Commandes Utiles

### Régénérer le code après modification des modèles
```bash
cd time_sheet_backend_server
serverpod generate
```

### Voir les logs Docker
```bash
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Arrêter tous les services
```bash
# Arrêter Docker
docker-compose down

# Arrêter le serveur : Ctrl+C dans le terminal
# Arrêter Flutter : q dans le terminal
```

### Réinitialiser la base de données
```bash
docker-compose down -v  # Supprime les volumes
docker-compose up -d
dart bin/main.dart --apply-migrations
```

## Structure des Ports

- 8080 : API Serverpod
- 8081 : Serverpod Insights (monitoring)
- 8082 : Web server Serverpod
- 8090 : PostgreSQL
- 8091 : Redis

## Troubleshooting

### Erreur "Port already in use"
```bash
# Trouver le processus qui utilise le port
lsof -i :8080
# Tuer le processus
kill -9 [PID]
```

### Erreur de connexion à la DB
- Vérifier que Docker est lancé
- Vérifier avec `docker ps` que les conteneurs tournent
- Vérifier les logs : `docker-compose logs postgres`

### Erreur "serverpod command not found"
```bash
# Réinstaller Serverpod CLI
dart pub global activate serverpod_cli
# Ajouter au PATH si nécessaire
export PATH="$PATH":"$HOME/.pub-cache/bin"
```