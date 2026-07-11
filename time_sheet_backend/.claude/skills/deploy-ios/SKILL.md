---
name: deploy-ios
description: >
  Déployer l'app iOS « Planet Time sheet » sur TestFlight (Codemagic, fastlane,
  signature, build number). Utiliser quand l'utilisateur demande de « déployer »,
  « publier sur TestFlight », « faire un build iOS », « prolonger la beta », ou
  quand un build Codemagic/TestFlight échoue.
---

# Déployer sur TestFlight

## Identité de l'app

| Élément | Valeur |
|---|---|
| Nom ASC | Planet Time sheet |
| Bundle ID | `com.jonathanlemaine.timeSheet` |
| Apple ID ASC | `6544810984` |
| Team | « Friendy fr » — Team ID `CSQ565C7YY` (PAS la team NOCHE) |
| Issuer ID ASC | `39f8805c-4dbb-41a8-a098-226953f8de98` |

## Voie normale : Codemagic (recommandée)

Le build local est **impossible** (Apple exige le SDK iOS 26 / Xcode 26 ; le Mac est sur macOS 14.6). Tout passe par Codemagic.

1. S'assurer que `pubspec.yaml` a le bon `version: X.Y.Z+N` (seul le NOM X.Y.Z compte ; le numéro de build est recalculé). ⚠️ `codemagic.yaml` contient aussi un `--build-name` codé en dur — le tenir aligné avec pubspec.
2. Pousser sur `main` (déclencheur automatique) ou lancer via l'UI Codemagic : app `avasad-sheet`, workflow **`ios-testflight`**, « Start new build ».
3. Le workflow : pub get → pod install → signature → `flutter build ipa` avec build number = dernier TestFlight + 1 → publication TestFlight automatique (`submit_to_testflight: true`). Durée ~8-9 min.
4. Vérifier sur App Store Connect → TestFlight que le build passe « Processing » → « Valid ».

### Signature (recette qui marche — ne pas changer)

- Certificat de distribution **persistant** `7Y9GDSUJ2L` (IOS_DISTRIBUTION, expire 2027-06-23), réutilisé à chaque build via `app-store-connect fetch-signing-files --certificate-key=@file:...`.
- Sa clé privée : `~/.appstoreconnect/timesheet_distribution_key.pem` (local, à sauvegarder) ET secret Codemagic `CM_CERTIFICATE_PRIVATE_KEY` (groupe `signing`, PEM encodé base64).
- Intégration ASC Codemagic : **« Sonrysa ASC »** avec la clé API **Admin `3CU9399LC5`**. Le rôle Admin est obligatoire (une clé App Manager ne peut pas créer de certificat).
- ⚠️ Ne JAMAIS regénérer une clé privée à chaque build : cela crée un certificat neuf à chaque fois et fait exploser la limite Apple (erreur 409 « You already have a current Distribution certificate »).

## fastlane local (secours / diagnostic)

- `cd time_sheet_backend/time_sheet_backend_flutter/ios`
- `fastlane verify_api_key` — teste l'auth ASC sans builder (clé « fastlane local », Key ID `P3A54R549V`, `.p8` dans `~/.appstoreconnect/private_keys/`, config dans `ios/fastlane/.env` non versionné).
- `fastlane beta` — build + upload complet ; ne marchera à nouveau que quand Xcode 26 sera installable.
- Ne PAS utiliser la clé `K65247D9S9` ni l'Issuer NOCHE `5616e408-…` (mauvaise team).

## Dépannage

- **Cert/profil introuvable sur Codemagic** : vérifier que le secret `CM_CERTIFICATE_PRIVATE_KEY` existe (groupe `signing`) et que le cert `7Y9GDSUJ2L` n'a pas été révoqué. Gérer les certs sans passer par developer.apple.com : `pip install codemagic-cli-tools` puis `app-store-connect certificates list/delete` avec la clé Admin.
- **« Cloud signing permission error »** : la clé API utilisée n'est pas Admin.
- **CocoaPods « installed but broken » sous fastlane** : fuite `GEM_HOME`/`GEM_PATH` — déjà corrigé dans le Fastfile (purge/restore), ne pas retirer ce bloc.
- **Build rejeté pour numéro déjà utilisé** : ne jamais fixer le build number à la main ; il est toujours calculé = dernier TestFlight + 1.
- **Builds TestFlight expirent après 90 jours** : relancer un build suffit à prolonger la beta.
