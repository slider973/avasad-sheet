# Architecture Technique - Système de Validation Manager

## Vue d'ensemble de l'architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Application Flutter                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   Employé   │  │   Manager    │  │  Services Partagés   │   │
│  │  - Pointage │  │ - Validation │  │ - Authentication     │   │
│  │  - Export   │  │ - Signature  │  │ - Notifications      │   │
│  │  - Upload   │  │ - Feedback   │  │ - Sync Service       │   │
│  └─────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Base Locale (Isar)                    │    │
│  │  - Pointages    - Signatures    - Cache validations     │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 │ HTTPS + JWT
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Cloud Services                           │
├──────────────────────────────┬──────────────────────────────────┤
│         Supabase             │            Firebase               │
│  - PostgreSQL Database       │   - Cloud Messaging (FCM)        │
│  - Storage (PDFs)            │   - Analytics                    │
│  - Realtime subscriptions    │   - Crashlytics                 │
│  - Row Level Security        │                                  │
└──────────────────────────────┴──────────────────────────────────┘
```

## Composants principaux

### 1. Module Employé

**Responsabilités :**
- Génération du PDF avec signature automatique
- Upload sécurisé vers Supabase
- Gestion des statuts de validation
- Réception des feedbacks

**Services utilisés :**
```dart
- TimesheetUploadService
- SignatureService (existant)
- PdfGeneratorService (existant)
- NotificationHandlerService
```

### 2. Module Manager

**Responsabilités :**
- Réception des notifications de validation
- Téléchargement et visualisation des timesheets
- Ajout de signature sur PDF existant
- Signalement d'erreurs avec commentaires

**Services utilisés :**
```dart
- ValidationService
- ManagerSignatureService
- FeedbackService
- DownloadService
```

### 3. Services Cloud

#### Supabase

**Tables principales :**
- `timesheet_validations` : Métadonnées des validations
- `validation_feedback` : Commentaires et erreurs
- `organizations` : Multi-tenancy
- `user_roles` : Gestion des rôles (employé/manager)

**Storage Buckets :**
- `timesheet-pdfs` : PDFs temporaires (30 jours TTL)
- `signatures` : Signatures des managers (optionnel)

#### Firebase

**Services utilisés :**
- **FCM** : Notifications push cross-platform
- **Analytics** : Tracking des validations
- **Remote Config** : Configuration dynamique

### 4. Architecture de sécurité

```
┌─────────────────────────────────────────────────────┐
│                  Couches de sécurité                 │
├─────────────────────────────────────────────────────┤
│                                                      │
│  1. Authentification (Supabase Auth)                │
│     - JWT tokens avec expiration                    │
│     - Refresh tokens automatiques                   │
│                                                      │
│  2. Chiffrement des données                         │
│     - AES-256 pour les PDFs                        │
│     - TLS 1.3 pour les transmissions               │
│                                                      │
│  3. Row Level Security (RLS)                        │
│     - Isolation par organisation                    │
│     - Permissions basées sur les rôles             │
│                                                      │
│  4. Validation côté serveur                         │
│     - Vérification des signatures                   │
│     - Contrôle d'intégrité des PDFs               │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## Flux de données détaillé

### 1. Upload d'une timesheet (Employé → Cloud)

```dart
// 1. Génération du PDF signé localement
final pdf = await pdfGenerator.generate(timesheet, employeeSignature);

// 2. Chiffrement du PDF
final encryptedPdf = await encryptionService.encrypt(pdf);

// 3. Upload vers Supabase Storage
final pdfUrl = await supabase.storage
  .from('timesheet-pdfs')
  .upload('${orgId}/${userId}/${timestamp}.pdf', encryptedPdf);

// 4. Création de l'entrée de validation
final validation = await supabase
  .from('timesheet_validations')
  .insert({
    'employee_id': userId,
    'manager_id': managerId,
    'pdf_url': pdfUrl,
    'status': 'pending',
    'metadata': {
      'month': timesheet.month,
      'year': timesheet.year,
      'total_hours': timesheet.totalHours,
    }
  });

// 5. Trigger de la notification Firebase
await firebaseService.sendNotification(
  to: managerFcmToken,
  title: 'Nouvelle timesheet à valider',
  body: 'De ${employeeName} pour ${month}/${year}',
  data: {'validation_id': validation.id}
);
```

### 2. Validation par le Manager

```dart
// 1. Réception de la notification
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final validationId = message.data['validation_id'];
  // Afficher dans l'UI
});

// 2. Téléchargement et déchiffrement
final validation = await supabase
  .from('timesheet_validations')
  .select()
  .eq('id', validationId)
  .single();

final encryptedPdf = await supabase.storage
  .from('timesheet-pdfs')
  .download(validation['pdf_url']);

final pdf = await encryptionService.decrypt(encryptedPdf);

// 3. Ajout de la signature manager
final signedPdf = await pdfService.addSecondSignature(
  pdf, 
  managerSignature,
  position: SignaturePosition.bottomRight
);

// 4. Upload du PDF doublement signé
final signedUrl = await supabase.storage
  .from('timesheet-pdfs')
  .upload('signed/${validationId}.pdf', signedPdf);

// 5. Mise à jour du statut
await supabase
  .from('timesheet_validations')
  .update({
    'status': 'validated',
    'signed_pdf_url': signedUrl,
    'validated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', validationId);
```

## Gestion du mode offline

### Stratégie de synchronisation

```dart
class OfflineSyncService {
  final Queue<SyncOperation> _pendingOperations = Queue();
  
  Future<void> executeOperation(SyncOperation operation) async {
    if (await isOnline()) {
      await operation.execute();
    } else {
      _pendingOperations.add(operation);
      await _saveToLocalCache(operation);
    }
  }
  
  Future<void> syncPendingOperations() async {
    while (_pendingOperations.isNotEmpty && await isOnline()) {
      final operation = _pendingOperations.removeFirst();
      try {
        await operation.execute();
        await _removeFromLocalCache(operation);
      } catch (e) {
        _pendingOperations.addFirst(operation);
        break;
      }
    }
  }
}
```

### Cache local des validations

```dart
// Modèle Isar pour le cache
@collection
class CachedValidation {
  Id id = Isar.autoIncrement;
  
  late String validationId;
  late String status;
  late DateTime cachedAt;
  
  @Index()
  late bool needsSync;
  
  late List<int> pdfBytes;
  late String metadata;
}
```

## Performance et optimisation

### 1. Compression des PDFs
- Utilisation de la compression ZLIB
- Réduction moyenne de 60% de la taille
- Décompression transparente côté client

### 2. Lazy loading
- Chargement des PDFs à la demande
- Pagination des listes de validation
- Cache LRU pour les PDFs consultés

### 3. Optimisation réseau
- Utilisation du HTTP/2
- Connection pooling
- Retry automatique avec backoff exponentiel

## Monitoring et logs

### Métriques suivies
- Temps de validation moyen
- Taux de succès des uploads
- Nombre de validations par jour/semaine
- Temps de réponse des managers

### Logs structurés
```dart
logger.info('validation_started', {
  'validation_id': validationId,
  'employee_id': employeeId,
  'manager_id': managerId,
  'timestamp': DateTime.now().toIso8601String(),
});
```

## Évolutions futures possibles

1. **Workflow multi-niveaux** : Validation par plusieurs managers
2. **Intégration ERP** : Export automatique vers SAP/Oracle
3. **Signature électronique qualifiée** : Conformité eIDAS
4. **Dashboard web** : Interface de gestion pour RH
5. **API REST** : Pour intégrations tierces