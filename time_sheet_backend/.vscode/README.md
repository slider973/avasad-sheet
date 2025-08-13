# Configuration VSCode pour Time Sheet Backend

## Lancer le Projet

### Option 1: Tout lancer automatiquement
1. Ouvrir VSCode dans le dossier `time_sheet_backend`
2. Aller dans l'onglet "Run and Debug" (Ctrl+Shift+D)
3. Sélectionner **"Full Stack (Server + App)"**
4. Cliquer sur Start (F5)

Cela va :
- Démarrer Docker (PostgreSQL + Redis)
- Lancer le serveur Serverpod
- Lancer l'app Flutter

### Option 2: Lancer séparément

#### 1. Démarrer Docker
- Ouvrir le Command Palette (Cmd+Shift+P)
- Taper "Tasks: Run Task"
- Sélectionner **"docker-compose-up"**

#### 2. Lancer le serveur
- Dans "Run and Debug", sélectionner **"Serverpod Server"**
- F5 pour lancer

#### 3. Lancer l'app Flutter
- Dans "Run and Debug", sélectionner **"Flutter App"**
- F5 pour lancer

## Configurations Disponibles

### Debug Configurations
- **Flutter App**: Lance l'app Flutter en mode debug
- **Flutter App (profile)**: Mode profile (performances)
- **Flutter App (release)**: Mode release
- **Serverpod Server**: Lance le serveur avec migrations
- **Serverpod Server (no migrations)**: Sans appliquer les migrations
- **Full Stack**: Lance tout automatiquement

### Tasks (Cmd+Shift+P > "Tasks: Run Task")
- **docker-compose-up**: Démarre PostgreSQL et Redis
- **docker-compose-down**: Arrête les conteneurs
- **serverpod-generate**: Génère le code Serverpod
- **flutter-pub-get**: Installe les dépendances Flutter
- **create-migration**: Crée une nouvelle migration

## Raccourcis Utiles

- **F5**: Lancer la configuration sélectionnée
- **Shift+F5**: Arrêter le debug
- **Ctrl+F5**: Relancer
- **F9**: Toggle breakpoint
- **F10**: Step over
- **F11**: Step into

## Structure du Projet

```
time_sheet_backend/
├── .vscode/                    # Configurations VSCode
├── time_sheet_backend_server/  # Serveur Serverpod
├── time_sheet_backend_client/  # Client généré
└── time_sheet_backend_flutter/ # App Flutter
```

## URLs Importantes

- **API Serverpod**: http://localhost:8080
- **Serverpod Insights**: http://localhost:8081
- **PostgreSQL**: localhost:8090
- **Redis**: localhost:8091