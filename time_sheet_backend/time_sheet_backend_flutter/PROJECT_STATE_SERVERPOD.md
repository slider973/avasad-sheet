# État du Projet - Migration Serverpod

## Contexte Initial
- **Problème**: Coûts élevés avec Supabase pour l'hébergement
- **Solution**: Migration vers Serverpod (framework Dart/Flutter auto-hébergé)
- **Date**: 2025-07-31

## Architecture Serverpod Planifiée

### 1. Modèles de Données

#### ValidationRequest
```yaml
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
```

#### Manager
```yaml
class: Manager
table: managers
fields:
  email: String
  firstName: String
  lastName: String
  company: String
  signature: String?
  isActive: bool
```

#### PdfRegenerationQueue
```yaml
class: PdfRegenerationQueue
table: pdf_regeneration_queue
fields:
  validationId: String
  status: QueueStatus
  createdAt: DateTime
  processedAt: DateTime?
  errorMessage: String?
```

### 2. Endpoints Principaux

#### ValidationEndpoint
- `createValidation`: Créer une demande de validation avec upload PDF
- `approveValidation`: Approuver avec signature du manager
- `getEmployeeValidations`: Lister les validations d'un employé
- `getManagerValidations`: Lister les validations à traiter par un manager

#### PdfProcessorEndpoint
- Tâche planifiée: `@Scheduled(cron: '*/5 * * * *')`
- Traite la queue de régénération PDF
- Ajoute les signatures des managers aux PDF approuvés
- Gestion des erreurs et retry automatique

### 3. Fonctionnalités Clés Migrées

1. **Système de Validation**
   - Création de demandes de validation
   - Workflow d'approbation/rejet
   - Signature électronique des managers
   - Commentaires sur les validations

2. **Génération PDF**
   - Upload des timesheets en PDF
   - Régénération automatique avec signature après approbation
   - Stockage local ou S3
   - Vérification d'intégrité avec hash

3. **Notifications**
   - Notification des managers pour nouvelles validations
   - Confirmation aux employés après traitement

4. **Queue de Traitement**
   - Traitement asynchrone des PDF
   - Retry automatique en cas d'échec
   - Monitoring des jobs

## Plan de Migration

### Phase 1: Setup Initial (Semaine 1)
- [x] Analyse de l'architecture actuelle
- [x] Conception des modèles Serverpod
- [x] Plan de migration détaillé
- [x] Installation Serverpod CLI
- [x] Création du projet backend

### Phase 2: Backend (Semaine 2)
- [x] Implémentation des modèles
- [x] Création des endpoints
- [ ] Configuration du stockage
- [ ] Tests unitaires

### Phase 3: Migration Données (Semaine 3)
- [ ] Export depuis Supabase
- [ ] Scripts de migration
- [ ] Import dans PostgreSQL
- [ ] Validation des données

### Phase 4: Intégration (Semaine 4)
- [ ] Adaptation du client Flutter
- [ ] Tests d'intégration
- [ ] Déploiement staging
- [ ] Go-live production

## Infrastructure

### Hébergement Recommandé
- **Option 1**: VPS (DigitalOcean/Hetzner)
  - 2 vCPU, 4GB RAM, 80GB SSD
  - Coût: 20-40€/mois
  - Docker + PostgreSQL

- **Option 2**: Serveur Dédié
  - Pour plus de performances
  - Coût: 50-100€/mois

### Stack Technique
- **Backend**: Serverpod (Dart)
- **Database**: PostgreSQL 15
- **Stockage**: Local ou S3
- **Déploiement**: Docker Compose
- **Monitoring**: Health endpoints + logs

## Avantages de la Migration

1. **Économies**: ~80% de réduction des coûts vs Supabase
2. **Contrôle**: Infrastructure 100% maîtrisée
3. **Performance**: Code natif Dart optimisé
4. **Type Safety**: Client/Server générés automatiquement
5. **Scalabilité**: Architecture modulaire

## Points d'Attention

1. **Backup**: Scripts automatiques quotidiens
2. **Monitoring**: Endpoints de santé + alertes
3. **Sécurité**: Firewall + SSL/TLS
4. **Maintenance**: Updates régulières

## État Actuel

### ✅ Modèles créés
- [x] ValidationRequest (validation_request.yaml)
- [x] ValidationStatus (validation_status.yaml)
- [x] Manager (manager.yaml)
- [x] PdfRegenerationQueue (pdf_regeneration_queue.yaml)
- [x] QueueStatus (queue_status.yaml)
- [x] Notification (notification.yaml)
- [x] NotificationType (notification_type.yaml)

### ✅ Endpoints créés
- [x] **ValidationEndpoint** (validation_endpoint.dart)
  - createValidation
  - approveValidation
  - rejectValidation
  - getEmployeeValidations
  - getManagerValidations
  - getValidation
  - downloadValidationPdf
  - checkExpiredValidations

- [x] **ManagerEndpoint** (manager_endpoint.dart)
  - createManager
  - updateManager
  - getActiveManagers
  - getManagerById
  - getManagerByEmail
  - deactivateManager
  - getManagerStatistics
  - searchManagers
  - importManagers

- [x] **PdfProcessorEndpoint** (pdf_processor_endpoint.dart)
  - processPdfQueue
  - cleanupOldJobs
  - _regeneratePdfWithSignature

- [x] **NotificationEndpoint** (notification_endpoint.dart)
  - getUserNotifications
  - markAsRead
  - markAllAsRead
  - deleteNotification
  - deleteReadNotifications
  - getUnreadCount
  - createNotification
  - createBulkNotifications
  - cleanupOldNotifications
  - getNotificationsByType
  - sendValidationReminders

### 🚧 Prochaines étapes
1. Créer les migrations de base de données
2. Configurer le client Flutter avec Serverpod
3. Implémenter le stockage des fichiers PDF
4. Configurer Docker pour le déploiement
5. Tester l'intégration complète