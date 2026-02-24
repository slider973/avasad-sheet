# 🚀 Configuration Fastlane iOS - Guide Complet

## ✅ Fichiers Créés

Les fichiers suivants ont été configurés pour le déploiement automatique iOS :

```
time_sheet_backend/
├── .github/
│   └── workflows/
│       └── deploy-ios.yml          ✅ Workflow GitHub Actions
├── time_sheet_backend_flutter/
│   ├── Gemfile                      ✅ Dépendances Ruby
│   └── ios/
│       ├── exportOptions.plist      ✅ Déjà existant
│       └── fastlane/
│           ├── Appfile              ✅ Configuration app
│           ├── Fastfile             ✅ Lanes de déploiement
│           └── .gitignore           ✅ Fichiers à ignorer
```

## 📋 Configuration Détectée

- **Bundle Identifier**: `com.jonathanlemaine.timeSheet`
- **Team ID**: `CSQ565C7YY`
- **Apple ID**: `jonathan.lemaine@outlook.fr` (à vérifier)
- **App Name**: Time Sheet

## 🔧 Étapes d'Installation

### 1. Installer les Dépendances Localement

```bash
cd time_sheet_backend_flutter

# Installer les gems Ruby (fastlane)
bundle install

# Installer les pods iOS
cd ios
pod install
cd ..
```

### 2. Configurer les Secrets GitHub

Allez dans **Settings > Secrets and variables > Actions** de votre repo GitHub et ajoutez :

#### Méthode 1️⃣ : Apple ID + App-Specific Password (Plus Simple)

- `FASTLANE_USER` : Votre Apple ID (jonathan.lemaine@outlook.fr)
- `FASTLANE_PASSWORD` : Mot de passe de votre Apple ID
- `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` :
  - Créez-en un sur https://appleid.apple.com
  - Account Security > App-Specific Passwords
  - Générez un nouveau mot de passe nommé "GitHub Actions"

#### Méthode 2️⃣ : App Store Connect API (Recommandé pour Production)

**Avantages** : Pas besoin de 2FA, plus sécurisé, ne nécessite pas de mot de passe

1. Connectez-vous à [App Store Connect](https://appstoreconnect.apple.com)
2. Allez dans **Users and Access > Keys** (sous Integrations)
3. Cliquez sur **+** pour créer une nouvelle clé
4. Donnez-lui un nom (ex: "GitHub Actions")
5. Sélectionnez le rôle **App Manager** ou **Admin**
6. Téléchargez le fichier `.p8` (⚠️ vous ne pourrez le télécharger qu'une seule fois!)
7. Notez le **Key ID** et **Issuer ID**

Ajoutez ces secrets :
- `APP_STORE_CONNECT_API_KEY_ID` : Le Key ID (ex: ABC123XYZ)
- `APP_STORE_CONNECT_API_ISSUER_ID` : L'Issuer ID (ex: a1b2c3d4-e5f6-...)
- `APP_STORE_CONNECT_API_KEY` : Le contenu complet du fichier .p8

#### Optionnel : Match (Gestion des Certificats)

Si vous utilisez `match` pour gérer les certificats :
- `MATCH_PASSWORD` : Mot de passe pour chiffrer/déchiffrer les certificats
- `MATCH_GIT_BASIC_AUTHORIZATION` : Token GitHub pour accéder au repo de certificats

### 3. Modifier le Fastfile pour App Store Connect API

Si vous utilisez la méthode 2️⃣, décommentez ces lignes dans `.github/workflows/deploy-ios.yml` :

```yaml
APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
```

Et ajoutez dans `ios/fastlane/Fastfile` au début de la lane `beta` :

```ruby
app_store_connect_api_key(
  key_id: ENV['APP_STORE_CONNECT_API_KEY_ID'],
  issuer_id: ENV['APP_STORE_CONNECT_API_ISSUER_ID'],
  key_content: ENV['APP_STORE_CONNECT_API_KEY'],
  is_key_content_base64: false
)
```

## 🧪 Test Local (IMPORTANT - À faire AVANT de push)

Testez le déploiement en local avant de configurer GitHub Actions :

```bash
cd time_sheet_backend_flutter/ios

# Test du build sans upload
bundle exec fastlane beta --verbose
```

Si vous obtenez des erreurs :
- **Code signing** : Vérifiez que votre Mac peut signer l'app dans Xcode
- **Certificates** : Assurez-vous d'avoir les certificats Apple installés
- **Provisioning** : Vérifiez les profils de provisioning

## 🚀 Utilisation

### Déploiement Automatique

Une fois configuré, le workflow se lance automatiquement quand :
1. Vous poussez du code sur la branche `main`
2. Les modifications touchent le dossier `time_sheet_backend_flutter/`

```bash
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin main
# 🎉 GitHub Actions lance automatiquement le déploiement !
```

### Déploiement Manuel

Vous pouvez aussi lancer le déploiement manuellement :
1. Allez sur GitHub > Actions
2. Sélectionnez "Deploy iOS to TestFlight"
3. Cliquez sur "Run workflow"
4. Choisissez la branche `main`
5. Cliquez "Run workflow"

### Déploiement Local

Pour déployer depuis votre Mac sans GitHub Actions :

```bash
cd time_sheet_backend_flutter/ios

# Déployer sur TestFlight
bundle exec fastlane beta

# Déployer sur App Store (production)
bundle exec fastlane release
```

## 📊 Lanes Disponibles

### `beta` - TestFlight
- Incrémente le build number automatiquement
- Build l'app en mode release
- Upload vers TestFlight
- **Ne soumet PAS** pour review automatiquement

### `release` - App Store
- Incrémente la version (patch/minor/major)
- Incrémente le build number
- Build l'app en mode release
- Upload vers App Store
- **Ne soumet PAS** pour review automatiquement

### `sync_certificates` - Match
- Télécharge et synchronise les certificats via Match
- Utile si vous travaillez en équipe

## 🔒 Sécurité - Vérifications Importantes

### ✅ À faire :
- ✅ Toujours utiliser les GitHub Secrets pour les credentials
- ✅ Ne jamais commit les fichiers `.p8`, `.p12`, `.mobileprovision`
- ✅ Activer la 2FA sur votre compte Apple Developer
- ✅ Utiliser l'App Store Connect API pour la production
- ✅ Revoir les permissions des clés API (minimum requis)

### ❌ À ne JAMAIS faire :
- ❌ Commit des mots de passe dans le code
- ❌ Partager vos clés API publiquement
- ❌ Désactiver `setup_ci` dans le Fastfile (sinon le build freeze!)

## 🐛 Troubleshooting

### Erreur : "Build freeze" ou timeout
**Solution** : Vérifiez que `setup_ci if ENV['CI']` est présent au début de votre lane

### Erreur : "No code signing identity found"
**Solutions** :
1. Vérifiez que vous avez les certificats Apple installés localement
2. Utilisez `match` pour gérer automatiquement les certificats
3. Vérifiez que `exportOptions.plist` a le bon `teamID`

### Erreur : "Invalid credentials"
**Solutions** :
1. Vérifiez les secrets GitHub (bon format, pas d'espaces)
2. Créez un nouveau App-Specific Password sur appleid.apple.com
3. Pour 2FA : Générez une session avec `fastlane spaceauth`

### Erreur : "User credentials invalid"
**Solution** : Utilisez l'App Store Connect API au lieu de l'Apple ID

### Le workflow ne se déclenche pas
**Vérifications** :
1. Le workflow est dans `.github/workflows/` à la racine du repo
2. Les modifications touchent `time_sheet_backend_flutter/`
3. Vous avez push sur `main` (pas une autre branche)
4. Regardez l'onglet "Actions" sur GitHub pour les erreurs

## 📚 Documentation Utile

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [GitHub Actions - Fastlane](https://docs.fastlane.tools/best-practices/continuous-integration/github/)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Flutter CD Guide](https://docs.flutter.dev/deployment/cd)

## 🎯 Prochaines Étapes

1. ✅ Installer les dépendances localement (`bundle install`)
2. ✅ Tester le build local (`bundle exec fastlane beta`)
3. ✅ Configurer les secrets GitHub
4. ✅ Pousser un commit sur `main` pour tester
5. 🎉 Profiter du déploiement automatique !

## 💡 Conseils Pro

- **Versioning** : Le build number s'incrémente automatiquement. Vous pouvez aussi gérer la version avec `increment_version_number`
- **Notifications** : Décommentez la section Slack dans le Fastfile pour recevoir des notifications
- **Testing** : Ajoutez une lane `test` pour lancer les tests avant le build
- **Screenshots** : Utilisez `snapshot` pour automatiser les captures d'écran
- **Metadata** : Utilisez `deliver` pour gérer les descriptions App Store

Bon déploiement ! 🚀
