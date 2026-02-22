# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Time Sheet** - A comprehensive timesheet management system with Supabase self-hosted backend, PowerSync offline-first sync, and Flutter multi-platform frontend. The system manages employee time tracking, absence management, overtime calculation, PDF report generation, anomaly detection, expense management, and manager validation workflows.

## Architecture

### High-Level Architecture

```
Flutter App  <-->  PowerSync (sync engine)  <-->  Supabase (PostgreSQL + Auth + Storage)
  (SQLite)           (Docker)                       (Docker, self-hosted)
```

- **Supabase self-hosted** : PostgreSQL, GoTrue (Auth), PostgREST, Realtime, Storage, Kong API Gateway, Studio
- **PowerSync self-hosted** : Bidirectional sync between local SQLite and PostgreSQL
- **Flutter** : `supabase_flutter`, `powersync` packages, BLoC + Clean Architecture
- **Edge Functions** : TypeScript/Deno for server-side logic (validations, notifications)

### Repository Structure

```
time_sheet_backend/
├── infrastructure/                      # Backend infrastructure (Docker)
│   ├── docker-compose.yml               # Supabase + PowerSync services
│   ├── .env / .env.example              # Configuration
│   ├── nginx/timesheet.conf             # Reverse proxy + SSL
│   ├── powersync/powersync.yaml         # Sync rules (bucket definitions)
│   ├── volumes/kong/kong.yml            # API Gateway routing
│   └── supabase/
│       ├── migrations/                  # SQL schema, RLS policies, storage buckets
│       │   ├── 00001_create_schema.sql  # 11 tables + triggers
│       │   ├── 00002_rls_policies.sql   # Row Level Security
│       │   └── 00003_storage_buckets.sql
│       └── functions/                   # Edge Functions (TypeScript/Deno)
│           ├── create-validation/
│           ├── approve-validation/
│           └── check-expired/
├── time_sheet_backend_flutter/          # Flutter application
├── time_sheet_backend_server/           # [LEGACY - being removed] Serverpod backend
└── time_sheet_backend_client/           # [LEGACY - being removed] Serverpod client
```

### Database Schema (PostgreSQL)

11 tables with RLS policies:

| Table | Description |
|-------|-------------|
| `profiles` | User profiles (linked to auth.users), roles: employee/manager/admin |
| `organizations` | Companies/organizations |
| `timesheet_entries` | Daily time tracking (morning/afternoon slots) |
| `absences` | Vacation, sick leave, holidays |
| `anomalies` | Detected anomalies (insufficient hours, missing entries, etc.) |
| `overtime_configurations` | Per-user overtime settings |
| `expenses` | Professional expense claims |
| `validation_requests` | Manager validation workflow |
| `notifications` | In-app notifications |
| `generated_pdfs` | PDF report metadata |
| `manager_employees` | Manager-employee relationships |

### PowerSync Sync Rules

Three sync buckets defined in `infrastructure/powersync/powersync.yaml`:
- **user_data** : Employee's own data (timesheet, absences, expenses, etc.)
- **manager_data** : Team data for managers (employee timesheets, anomalies, validations)
- **org_data** : Shared organizational data (profiles, org info, manager-employee links)

### Flutter Architecture (Clean Architecture + BLoC)

```
lib/
├── core/
│   ├── auth/                        # AuthRepository interface + implementation
│   ├── database/                    # PowerSync (schema, connector, manager)
│   │   ├── schema.dart              # PowerSync table definitions (SQLite)
│   │   ├── supabase_connector.dart  # Auth + upload connector
│   │   └── powersync_database.dart  # PowerSyncDatabase singleton
│   ├── error/                       # Failure classes
│   ├── migration/                   # Isar -> PowerSync one-time migration
│   ├── responsive/                  # Responsive layout (mobile/tablet/desktop)
│   └── services/
│       ├── supabase/                # SupabaseService (auth, client)
│       └── storage/                 # StorageService (PDFs, signatures, receipts)
├── features/
│   ├── auth/                        # Login, Register, Forgot Password
│   ├── pointage/                    # Time tracking (core feature)
│   │   ├── domain/                  # Entities, use cases, rules, repositories
│   │   ├── data/                    # PowerSync data sources, models, repository impl
│   │   └── presentation/           # BLoCs, pages (dashboard, pointage, calendar, anomalies, PDF)
│   ├── absence/                     # Absence management
│   ├── expense/                     # Expense claims with receipt upload
│   ├── validation/                  # Manager validation workflow (Supabase-based)
│   ├── preference/                  # User preferences and onboarding
│   ├── manager/                     # Manager dashboard (team overview, approvals)
│   └── bottom_nav_tab/              # Navigation (BottomNav + Drawer)
└── services/
    ├── injection_container.dart     # GetIt dependency injection
    └── service_factory.dart         # MultiBlocProvider
```

**Data flow** : UI -> BLoC -> UseCase -> Repository -> PowerSync DB (local SQLite) -> auto-sync -> PostgreSQL

## Essential Development Commands

### Infrastructure

```bash
cd infrastructure

# First time: copy and configure .env
cp .env.example .env
# Edit .env with your values (JWT_SECRET, POSTGRES_PASSWORD, domain URLs, SMTP, etc.)

# Start all services (Supabase + PowerSync)
docker compose up -d

# Check services are running
docker compose ps

# Apply SQL migrations (via psql or Supabase Studio SQL Editor)
psql -h localhost -p 5432 -U supabase_admin -d supabase -f supabase/migrations/00001_create_schema.sql
psql -h localhost -p 5432 -U supabase_admin -d supabase -f supabase/migrations/00002_rls_policies.sql
psql -h localhost -p 5432 -U supabase_admin -d supabase -f supabase/migrations/00003_storage_buckets.sql

# Stop services
docker compose stop
```

### Flutter Development

```bash
cd time_sheet_backend_flutter

# Install dependencies
flutter pub get

# Generate Isar models (still needed during migration period)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run on web
flutter run -d chrome

# Run tests
flutter test

# Build release
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## Key Technologies

### Backend
- **Supabase self-hosted** : PostgreSQL + GoTrue Auth + Storage + Realtime + Studio
- **PowerSync self-hosted** : Offline-first sync engine (SQLite <-> PostgreSQL)
- **Kong** : API Gateway
- **Edge Functions** : Deno/TypeScript for server-side logic

### Frontend (Flutter)
- **PowerSync** (`powersync`) : Local SQLite with automatic sync
- **Supabase Flutter** (`supabase_flutter`) : Auth, Storage client
- **BLoC Pattern** (`flutter_bloc`) : State management
- **GetIt** : Dependency injection
- **fpdart** : Functional programming (`Either<Failure, T>`)
- **Syncfusion** : Calendar and charts
- **image_picker** : Receipt photo capture
- **signature** : Digital signature capture

### Design Patterns
- **Clean Architecture** : Domain layer is backend-agnostic (entities, use cases, repository interfaces never import PowerSync/Supabase)
- **Use Case Pattern** : Single-responsibility use cases (30+), injected via GetIt
- **Anomaly Detection** : Extensible rule-based system with Registry pattern (`lib/features/pointage/domain/rules/`)
- **Role-based Navigation** : Bottom nav adapts based on `profiles.role` (employee: 5 tabs, manager: 6 tabs)

## Critical Workflows

### Authentication Flow

```
App Start -> Supabase.initialize() + PowerSync.initialize()
  -> AuthBloc checks session
    -> Not logged in -> LoginPage (email/password or Google)
    -> Logged in, no profile -> OnboardingPage
    -> Logged in + profile -> BottomNavigationBarPage
```

### Data Flow (Offline-First)

1. User action in UI triggers BLoC event
2. BLoC calls UseCase
3. UseCase calls Repository
4. Repository executes SQL on PowerSync (local SQLite)
5. PowerSync automatically syncs changes to PostgreSQL via sync rules
6. Other devices/managers receive synced data through their sync buckets

### Modifying Database Schema

1. Edit SQL in `infrastructure/supabase/migrations/` (create new migration file)
2. Apply migration to PostgreSQL
3. Update PowerSync sync rules in `infrastructure/powersync/powersync.yaml` if needed
4. Update PowerSync schema in `lib/core/database/schema.dart`
5. Update data sources and repositories in Flutter

### Validation Workflow

1. Employee submits validation -> Edge Function `create-validation` -> notification to manager
2. Manager approves -> Edge Function `approve-validation` -> notification to employee
3. Cron job -> Edge Function `check-expired` -> expires pending validations > 30 days

### Manager Dashboard

Manager role detected from `profiles.role` via PowerSync. 6th tab "Manager" shows:
- Team overview (present/absent/not clocked in)
- Pending validations
- Pending expense approvals
- Team anomalies
- Individual employee timesheet view

### Isar to PowerSync Migration

For users upgrading from the old Isar version:
- `lib/core/migration/isar_to_powersync_migration.dart` handles one-time migration
- Runs automatically on first launch after update
- Detects Isar DB files, reads all data, inserts into PowerSync, marks complete

## Storage (Supabase Storage)

Three private buckets with RLS:
- `pdfs/` : Generated timesheet PDFs (`{userId}/{year}-{month}.pdf`)
- `signatures/` : User signatures (`{userId}/signature.png`)
- `receipts/` : Expense receipt photos (`{userId}/{expenseId}.jpg`)

Access: `StorageService` in `lib/core/services/storage/storage_service.dart`

## Configuration

### Infrastructure
- `infrastructure/.env` : All backend configuration (PostgreSQL, JWT, Supabase, PowerSync, SMTP, Google OAuth)
- `infrastructure/docker-compose.yml` : Service definitions
- `infrastructure/powersync/powersync.yaml` : Sync rules

### Flutter
- `lib/core/services/supabase/supabase_service.dart` : Supabase URL + anon key
- `lib/core/database/powersync_database.dart` : PowerSync URL
- `lib/config/theme.dart` : App theming
- `analysis_options.yaml` : Linting rules (80-char limit disabled)

## Dependency Injection

All services, repositories, use cases, and BLoCs registered in `time_sheet_backend_flutter/lib/services/injection_container.dart`:

```dart
final getIt = GetIt.instance;

// Examples
final authRepo = getIt<AuthRepository>();
final bloc = getIt<ManagerDashboardBloc>();
final storageService = StorageService(); // Uses SupabaseService.instance internally
```

## Testing

```bash
cd time_sheet_backend_flutter
flutter test                          # All tests
flutter test test/specific_test.dart  # Specific test
flutter test test/integration/        # Integration tests
```

## Platform-Specific Notes

### Desktop (Windows/macOS/Linux)
- Fixed window size: 500x1000 via `window_manager`
- Custom database paths: Windows uses `%LOCALAPPDATA%/TimeSheet`

### Mobile (iOS/Android)
- Native splash screens
- Camera/gallery access for receipt photos
- Google Sign-In

### Web
- Responsive layout: `lib/core/responsive/responsive_layout.dart`
- `ResponsiveLayout` widget with mobile/tablet/desktop breakpoints
- `AdaptiveScaffold` : NavigationRail (desktop/tablet) vs BottomNavigationBar (mobile)
- Build: `flutter build web --release`, serve `build/web/` with Nginx

## Adding New Features

### Adding a New Feature Module

1. Create feature directory: `lib/features/my_feature/domain/`, `data/`, `presentation/`
2. Domain: entity, repository interface, use cases
3. Data: PowerSync data source (SQL queries), repository implementation
4. Presentation: BLoC (events/states), pages, widgets
5. Register in `injection_container.dart`
6. Add BLoC to `service_factory.dart` if needed globally

### Adding a New Anomaly Rule

See `time_sheet_backend_flutter/lib/features/pointage/domain/rules/README.md`:
1. Create rule class in `lib/features/pointage/domain/rules/impl/`
2. Register in `AnomalyRuleRegistry.initialize()`

### Adding an Edge Function

1. Create `infrastructure/supabase/functions/my-function/index.ts`
2. Deploy: `supabase functions deploy my-function`
3. Call from Flutter: `SupabaseService.instance.client.functions.invoke('my-function', body: {...})`
