# Guide de Nettoyage - Ancienne Structure

## Situation Actuelle

Le projet Flutter a été déplacé dans `time_sheet_backend/time_sheet_backend_flutter/`.
Il reste des fichiers à la racine qui doivent être gérés.

## Fichiers à Gérer

### 1. Configuration Git (.git, .gitignore)
**Action**: GARDER à la racine
- Le dépôt git doit rester à la racine pour suivre tout le projet

### 2. Fichiers VSCode (.vscode/)
**Action**: SUPPRIMER
```bash
rm -rf /Users/jonathanlemaine/StudioProjects/time_sheet/.vscode
```
- On utilise maintenant la config dans time_sheet_backend/.vscode

### 3. Fichiers de configuration IDE (.idea/)
**Action**: SUPPRIMER
```bash
rm -rf /Users/jonathanlemaine/StudioProjects/time_sheet/.idea
```

### 4. Dossier build restant
**Action**: SUPPRIMER
```bash
rm -rf /Users/jonathanlemaine/StudioProjects/time_sheet/build
```

### 5. Fichiers de configuration (.env.example, .mcp.json)
**Action**: DÉPLACER
```bash
mv /Users/jonathanlemaine/StudioProjects/time_sheet/.env.example /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend/
mv /Users/jonathanlemaine/StudioProjects/time_sheet/.mcp.json /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend/
```

### 6. Fichiers cachés système (.DS_Store, .claude, .codeum)
**Action**: IGNORER ou SUPPRIMER
- .DS_Store : Fichier macOS (peut être supprimé)
- .claude et .codeum : Garder si tu utilises ces outils

## Commandes de Nettoyage Complètes

```bash
# 1. Supprimer l'ancien .vscode
rm -rf /Users/jonathanlemaine/StudioProjects/time_sheet/.vscode

# 2. Supprimer .idea
rm -rf /Users/jonathanlemaine/StudioProjects/time_sheet/.idea

# 3. Supprimer le dossier build
rm -rf /Users/jonathanlemaine/StudioProjects/time_sheet/build

# 4. Déplacer les fichiers de config
mv /Users/jonathanlemaine/StudioProjects/time_sheet/.env.example /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend/
mv /Users/jonathanlemaine/StudioProjects/time_sheet/.mcp.json /Users/jonathanlemaine/StudioProjects/time_sheet/time_sheet_backend/

# 5. Optionnel : Supprimer .DS_Store
rm /Users/jonathanlemaine/StudioProjects/time_sheet/.DS_Store
```

## Structure Finale

Après le nettoyage :
```
time_sheet/
├── .git/                    # Dépôt Git
├── .gitignore              # Configuration Git
├── time_sheet_backend/     # Tout le projet est ici
│   ├── .vscode/           # Configuration VSCode
│   ├── time_sheet_backend_server/
│   ├── time_sheet_backend_client/
│   └── time_sheet_backend_flutter/
└── README.md               # À créer pour expliquer la nouvelle structure
```

## Mise à jour du .gitignore

Ajouter dans .gitignore :
```
.DS_Store
.idea/
build/
*.log
```