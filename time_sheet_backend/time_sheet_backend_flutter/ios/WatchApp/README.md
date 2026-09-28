# App watchOS — « Planet Time sheet »

Pointer depuis l'Apple Watch. La montre ne contient **aucune logique métier** :
elle demande, l'iPhone décide et enregistre.

## Architecture

```
Apple Watch (SwiftUI)                 iPhone (Flutter)
┌──────────────────────┐              ┌────────────────────────────┐
│ PointageView         │  action      │ WatchService               │
│  bouton « Commencer »│ ───────────► │  actionStream               │
│                      │              │       │                    │
│ WatchConnectivity-   │              │       ▼                    │
│ Manager (WCSession)  │   state      │ TimeSheetBloc              │
│                      │ ◄─────────── │  _onWatchAction → pointage │
└──────────────────────┘              └────────────────────────────┘
```

* **montre → iPhone** : `["action": "toggle", "timestamp": "<ISO8601>"]`
* **iPhone → montre** : `["state": "Entrée", "lastUpdate": "<ISO8601>"]`

Le vocabulaire est verrouillé par `test/watch_pointage_action_test.dart` :
Swift écrit ces chaînes, Dart les décode, et rien ne relie les deux à la
compilation.

## Deux décisions structurantes

**La montre demande, elle ne décide pas.** Le bouton envoie toujours `toggle`.
C'est `TimeSheetBloc._onWatchAction` qui applique la transition valide pour
l'état réel de la journée (Non commencé → Entrée → Pause → Reprise → Sortie).
Une montre restée sur un écran périmé ne peut donc pas écrire un pointage
incohérent.

**L'heure voyage avec la demande.** `transferUserInfo` peut livrer un message
plusieurs minutes après l'appui (iPhone endormi ou hors de portée). Le pointage
utilise `occurredAt`, l'heure du geste, jamais l'heure de traitement.

## Chaîne d'envoi côté montre

1. `sendMessage` si l'iPhone est joignable — retour immédiat.
2. Sinon, ou en cas d'échec, `transferUserInfo` : le système met en file et
   livre au réveil de l'app iOS. **Un pointage n'est jamais perdu** parce que le
   téléphone dormait.

Limite connue : si l'application iOS a été *tuée* par l'utilisateur, iOS ne la
relance pas toujours en arrière-plan. La demande reste en file et s'applique au
prochain lancement — à la bonne heure, grâce à `occurredAt`.

## Intégration Xcode

La target a été ajoutée par script (`xcodeproj`), pas à la main :

| Réglage | Valeur |
|---|---|
| Bundle ID | `com.jonathanlemaine.timeSheet.watchkitapp` |
| watchOS minimum | 9.0 |
| xcconfig | `Flutter/WatchApp.xcconfig` → n'inclut que `Generated.xcconfig` |
| Versions | `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)` |
| Embarquement | phase « Embed Watch Content » de `Runner` |

Points à ne pas défaire :

* **Le xcconfig dédié n'inclut pas les pods.** Les CocoaPods du Runner sont
  compilés pour iOS ; les tirer dans la target watch casserait le link. Mais il
  doit inclure `Generated.xcconfig`, sinon les versions du bundle watch ne
  correspondent plus à celles de l'app iOS — et Apple rejette l'IPA.
* **La phase « Embed Watch Content » doit rester juste après « Resources »**,
  donc AVANT `Thin Binary` et les phases `[CP]` de CocoaPods. Placée en
  dernier, la copie de `WatchApp.app` entre dans la chaîne de dépendances de la
  signature du Runner et Xcode refuse de builder :

  ```
  Error (Xcode): Cycle inside Runner; building could produce unreliable results.
  → script phase "[CP] Embed Pods Frameworks"
  ○ script phase "Thin Binary"
  ○ copy command from Release-watchos/WatchApp.app to Runner.app/Watch/WatchApp.app
  ○ script phase "[CP] Copy Pods Resources"
  ```

  C'est l'échec du build du 2026-09-28. L'ordre est stable après `pod install`
  (vérifié), mais toute manipulation du projet doit le préserver.
* **`pod install` préserve la target** (vérifié) : le `Podfile` ne cible que
  `Runner` et `RunnerTests`.
* **L'icône ne doit pas avoir de canal alpha**, watchOS la refuse. Celle du
  dossier `Assets.xcassets` est dérivée de l'icône iOS, aplatie sur blanc.

## Signature

Un bundle embarqué exige **son propre** profil de provisioning. `codemagic.yaml`
récupère donc deux profils (`BUNDLE_ID` et `WATCH_BUNDLE_ID`) avant
`xcode-project use-profiles`. Le type reste `IOS_APP_STORE` : une app watchOS
s'appuie sur un App ID iOS, il n'existe pas de type watchOS distinct côté App
Store Connect.

## Vérification locale : ce qui est possible, ce qui ne l'est pas

```bash
# Type-check du Swift — fonctionne sur ce Mac
SDK=$(xcrun --sdk watchos --show-sdk-path)
xcrun --sdk watchos swiftc -typecheck -target arm64_32-apple-watchos9.0 \
  -sdk "$SDK" WatchApp/*.swift
```

Le **build complet de la target échoue localement** : `actool` réclame un
runtime de simulateur watchOS, absent de cette machine
(« No available simulator runtimes for platform watchsimulator »). Ce n'est pas
un défaut du code — le Swift type-check sans erreur. L'archive release iOS étant
de toute façon impossible en local (SDK iOS 26 requis), la validation complète
passe par Codemagic.
