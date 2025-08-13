# Plan de Migration Supabase → Serverpod

## Vue d'ensemble

Serverpod est un framework backend Dart/Flutter qui permet d'auto-héberger votre infrastructure, réduisant ainsi les coûts par rapport à Supabase. Cette migration vous permettra de garder le contrôle total sur votre infrastructure et vos données.

## Architecture Proposée

### 1. Structure du Projet Serverpod

```
time_sheet_backend/
├── time_sheet_server/
│   ├── lib/
│   │   ├── src/
│   │   │   ├── generated/          # Code généré automatiquement
│   │   │   ├── endpoints/          # Points d'API
│   │   │   ├── models/             # Modèles YAML
│   │   │   └── business/           # Logique métier
│   │   └── server.dart
│   ├── migrations/                  # Migrations SQL
│   ├── config/                      # Configuration
│   └── pubspec.yaml
├── time_sheet_client/              # Client Dart généré
└── time_sheet_flutter/             # Votre app Flutter existante

```

### 2. Modèles de Données Serverpod

#### Validation Request Model
```yaml
# validation_request.yaml
class: ValidationRequest
table: validation_requests
fields:
  employeeId: String
  managerId: String
  periodStart: DateTime
  periodEnd: DateTime
  status: ValidationStatus
  pdfPath: String
  pdfHash: String
  pdfSizeBytes: int
  managerSignature: String?
  managerComment: String?
  validatedAt: DateTime?
  expiresAt: DateTime?
  createdAt: DateTime, defaultPersist=now
  updatedAt: DateTime, defaultPersist=now
indexes:
  validation_employee_idx:
    fields: employeeId
  validation_manager_idx:
    fields: managerId
  validation_status_idx:
    fields: status
```

#### Manager Model
```yaml
# manager.yaml
class: Manager
table: managers
fields:
  email: String
  firstName: String
  lastName: String
  company: String
  signature: String?
  isActive: bool, default=true
indexes:
  manager_email_idx:
    fields: email
    unique: true
  manager_company_idx:
    fields: company
```

#### PDF Regeneration Queue
```yaml
# pdf_regeneration_queue.yaml
class: PdfRegenerationQueue
table: pdf_regeneration_queue
fields:
  validationId: String
  status: QueueStatus, default='pending'
  createdAt: DateTime, defaultPersist=now
  processedAt: DateTime?
  errorMessage: String?
indexes:
  queue_status_idx:
    fields: status
  queue_created_idx:
    fields: createdAt
```

### 3. Endpoints Serverpod

#### Validation Endpoint
```dart
// lib/src/endpoints/validation_endpoint.dart
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ValidationEndpoint extends Endpoint {
  // Créer une demande de validation
  Future<ValidationRequest> createValidation(
    Session session,
    String employeeId,
    String managerId,
    DateTime periodStart,
    DateTime periodEnd,
    List<int> pdfBytes,
  ) async {
    // Upload PDF vers stockage local ou S3
    final pdfPath = await _uploadPdf(pdfBytes, employeeId, periodStart);
    
    // Créer l'entrée en base
    final validation = ValidationRequest(
      employeeId: employeeId,
      managerId: managerId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: ValidationStatus.pending,
      pdfPath: pdfPath,
      pdfHash: _calculateHash(pdfBytes),
      pdfSizeBytes: pdfBytes.length,
    );
    
    await ValidationRequest.db.insertRow(session, validation);
    
    // Notifier le manager
    await _notifyManager(session, managerId, validation);
    
    return validation;
  }
  
  // Approuver une validation
  Future<ValidationRequest> approveValidation(
    Session session,
    String validationId,
    String managerSignature,
    String? comment,
  ) async {
    final validation = await ValidationRequest.db.findById(
      session,
      int.parse(validationId),
    );
    
    if (validation == null) {
      throw Exception('Validation not found');
    }
    
    validation.status = ValidationStatus.approved;
    validation.managerSignature = managerSignature;
    validation.managerComment = comment;
    validation.validatedAt = DateTime.now();
    
    await ValidationRequest.db.updateRow(session, validation);
    
    // Ajouter à la queue de régénération PDF
    await PdfRegenerationQueue.db.insertRow(
      session,
      PdfRegenerationQueue(
        validationId: validationId,
        status: QueueStatus.pending,
      ),
    );
    
    return validation;
  }
  
  // Lister les validations d'un employé
  Future<List<ValidationRequest>> getEmployeeValidations(
    Session session,
    String employeeId,
  ) async {
    return await ValidationRequest.db.find(
      session,
      where: (t) => t.employeeId.equals(employeeId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }
  
  // Lister les validations d'un manager
  Future<List<ValidationRequest>> getManagerValidations(
    Session session,
    String managerId,
  ) async {
    return await ValidationRequest.db.find(
      session,
      where: (t) => t.managerId.equals(managerId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }
}
```

#### PDF Processor Endpoint
```dart
// lib/src/endpoints/pdf_processor_endpoint.dart
import 'package:serverpod/serverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../generated/protocol.dart';

class PdfProcessorEndpoint extends Endpoint {
  // Traiter la queue de régénération PDF
  @Scheduled(cron: '*/5 * * * *') // Toutes les 5 minutes
  Future<void> processPdfQueue(Session session) async {
    final pendingJobs = await PdfRegenerationQueue.db.find(
      session,
      where: (t) => t.status.equals(QueueStatus.pending),
      limit: 10,
    );
    
    for (final job in pendingJobs) {
      try {
        // Marquer comme en cours
        job.status = QueueStatus.processing;
        await PdfRegenerationQueue.db.updateRow(session, job);
        
        // Récupérer la validation
        final validation = await ValidationRequest.db.findById(
          session,
          int.parse(job.validationId),
        );
        
        if (validation == null || validation.managerSignature == null) {
          throw Exception('Invalid validation or missing signature');
        }
        
        // Régénérer le PDF avec signature
        final newPdfPath = await _regeneratePdfWithSignature(
          session,
          validation,
        );
        
        // Mettre à jour le chemin du PDF
        validation.pdfPath = newPdfPath;
        await ValidationRequest.db.updateRow(session, validation);
        
        // Marquer comme complété
        job.status = QueueStatus.completed;
        job.processedAt = DateTime.now();
        await PdfRegenerationQueue.db.updateRow(session, job);
        
      } catch (e) {
        // Marquer comme échoué
        job.status = QueueStatus.failed;
        job.errorMessage = e.toString();
        await PdfRegenerationQueue.db.updateRow(session, job);
      }
    }
  }
  
  Future<String> _regeneratePdfWithSignature(
    Session session,
    ValidationRequest validation,
  ) async {
    // Télécharger le PDF original
    final originalPdfBytes = await _downloadPdf(validation.pdfPath);
    
    // Charger le PDF
    final pdf = pw.Document();
    // ... Logique pour ajouter la signature au PDF ...
    
    // Sauvegarder le nouveau PDF
    final newPath = validation.pdfPath.replaceAll('.pdf', '_validated.pdf');
    await _uploadPdf(pdfBytes, newPath);
    
    return newPath;
  }
}
```

### 4. Configuration Serverpod

#### Configuration du serveur
```yaml
# config/development.yaml
apiServer:
  port: 8080
  publicHost: localhost
  publicPort: 8080
  publicScheme: http

database:
  host: localhost
  port: 5432
  name: timesheet
  user: postgres

redis:
  enabled: false

# Stockage des fichiers
fileStorage:
  type: local # ou 's3' pour AWS
  localPath: ./uploads
```

### 5. Intégration Flutter

#### Mise à jour du client Flutter
```dart
// lib/services/api_client.dart
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:time_sheet_client/time_sheet_client.dart';

class ApiService {
  static late Client _client;
  
  static Future<void> initialize() async {
    _client = Client(
      'http://localhost:8080/',
      authenticationKeyManager: FlutterAuthenticationKeyManager(),
    )..connectivityMonitor = FlutterConnectivityMonitor();
  }
  
  static Client get client => _client;
}
```

#### Repository de validation adapté
```dart
// lib/features/validation/data/repositories/validation_repository_serverpod.dart
class ValidationRepositoryServerpod implements ValidationRepository {
  final Client client;
  
  const ValidationRepositoryServerpod({required this.client});
  
  @override
  Future<Either<Failure, ValidationRequest>> createValidationRequest({
    required String employeeId,
    required String managerId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required Uint8List pdfBytes,
  }) async {
    try {
      final result = await client.validation.createValidation(
        employeeId,
        managerId,
        periodStart,
        periodEnd,
        pdfBytes,
      );
      
      return Right(_mapToEntity(result));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, ValidationRequest>> approveValidation({
    required String validationId,
    required String managerSignature,
    String? comment,
  }) async {
    try {
      final result = await client.validation.approveValidation(
        validationId,
        managerSignature,
        comment,
      );
      
      return Right(_mapToEntity(result));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

## Plan de Migration

### Phase 1: Setup Serverpod (Semaine 1)
1. **Installer Serverpod CLI**
   ```bash
   dart pub global activate serverpod_cli
   ```

2. **Créer le projet Serverpod**
   ```bash
   serverpod create time_sheet_backend
   ```

3. **Définir les modèles** dans `protocol/`

4. **Générer le code**
   ```bash
   serverpod generate
   serverpod create-migration
   ```

### Phase 2: Implémentation Backend (Semaine 2)
1. Implémenter les endpoints
2. Configurer le stockage des fichiers
3. Implémenter la queue de traitement PDF
4. Ajouter les tâches planifiées

### Phase 3: Migration des Données (Semaine 3)
1. Exporter les données depuis Supabase
2. Script de migration vers PostgreSQL
3. Vérifier l'intégrité des données
4. Migrer les fichiers PDF

### Phase 4: Intégration Flutter (Semaine 4)
1. Remplacer le client Supabase par Serverpod
2. Adapter les repositories
3. Tester toutes les fonctionnalités
4. Déploiement en production

## Hébergement Auto-géré

### Option 1: VPS (Recommandé)
- **Fournisseur**: DigitalOcean, Hetzner, OVH
- **Specs minimales**: 2 vCPU, 4GB RAM, 80GB SSD
- **Coût estimé**: 20-40€/mois

### Option 2: Serveur Dédié
- **Pour**: Plus de contrôle, meilleures performances
- **Coût estimé**: 50-100€/mois

### Configuration Docker
```yaml
# docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: timesheet
    volumes:
      - postgres_data:/var/lib/postgresql/data
    
  serverpod:
    build: .
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    environment:
      DATABASE_URL: postgresql://postgres:${DB_PASSWORD}@postgres:5432/timesheet
    volumes:
      - ./uploads:/app/uploads

volumes:
  postgres_data:
```

## Avantages de Serverpod

1. **Économies**: Pas de frais Supabase mensuels
2. **Contrôle total**: Vous gérez votre infrastructure
3. **Performance**: Code Dart optimisé
4. **Type-safe**: Génération de code client/serveur
5. **Intégration Flutter**: Conçu pour Flutter
6. **Scalabilité**: Architecture modulaire

## Monitoring et Maintenance

### Monitoring
```dart
// Endpoint de santé
class HealthEndpoint extends Endpoint {
  Future<Map<String, dynamic>> check(Session session) async {
    final dbHealth = await _checkDatabase(session);
    final storageHealth = await _checkStorage();
    
    return {
      'status': dbHealth && storageHealth ? 'healthy' : 'unhealthy',
      'database': dbHealth,
      'storage': storageHealth,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
```

### Backups Automatiques
```bash
#!/bin/bash
# backup.sh
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump timesheet > /backups/db_$DATE.sql
tar -czf /backups/files_$DATE.tar.gz /app/uploads
# Garder seulement les 7 derniers jours
find /backups -mtime +7 -delete
```

Cette architecture vous donnera un contrôle total sur votre infrastructure tout en réduisant significativement les coûts par rapport à Supabase.