# Déploiement iOS - Time Sheet v1.0.2

## Étapes de déploiement pour TestFlight et App Store

### 1. ✅ Version mise à jour
- Version: 1.0.2
- Build: 2

### 2. ✅ Build iOS créé avec succès
- Taille: 89.1MB
- Build path: build/ios/iphoneos/Runner.app

### 3. Prochaines étapes dans Xcode

#### Ouvrir le projet dans Xcode
```bash
open ios/Runner.xcworkspace
```

#### Créer l'archive
1. Dans Xcode, sélectionnez "Product" → "Archive"
2. Assurez-vous que le schéma est sur "Runner" et l'appareil sur "Generic iOS Device"
3. Attendez que l'archive soit créé

#### Distribuer sur TestFlight
1. Une fois l'archive créé, la fenêtre "Organizer" s'ouvrira
2. Sélectionnez votre archive et cliquez sur "Distribute App"
3. Choisissez "App Store Connect"
4. Sélectionnez "Upload"
5. Suivez les étapes de validation
6. Uploadez vers App Store Connect

#### Configuration dans App Store Connect
1. Connectez-vous à https://appstoreconnect.apple.com
2. Sélectionnez votre app
3. Allez dans "TestFlight"
4. Votre build apparaîtra après traitement (environ 10-30 minutes)
5. Ajoutez des testeurs internes/externes
6. Soumettez pour TestFlight

### 4. Nouvelles fonctionnalités v1.0.2
- Ajout de la gestion des heures supplémentaires
- Possibilité de marquer des jours spécifiques comme ayant des heures supplémentaires
- Les heures supplémentaires apparaissent dans le PDF avec une couleur orange
- Amélioration de la génération automatique des pointages (suppression du champ durée de pause)

### 5. Notes importantes
- Assurez-vous d'avoir un certificat de distribution valide
- Vérifiez que le profil de provisioning est à jour
- Le bundle identifier doit correspondre: com.jonathanlemaine.timeSheet

### Commandes utiles
```bash
# Si besoin de rebuild avec signature
flutter build ios --release

# Vérifier les certificats
security find-identity -p codesigning

# Nettoyer les caches si problème
flutter clean
cd ios && pod deintegrate && pod install
```