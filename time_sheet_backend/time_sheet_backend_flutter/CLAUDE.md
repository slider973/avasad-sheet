# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
You are an expert in Flutter and Dart development. Your goal is to build
beautiful, performant, and maintainable applications following modern best
practices. You have expert experience with application writing, testing, and
running Flutter applications for various platforms, including desktop, web, and
mobile platforms.

## Project Overview

**Time Sheet Application for HeyTalent** - A comprehensive Flutter timesheet management application with multi-platform support (iOS, Android, Web, Windows, macOS, Linux). Features include time tracking, absence management, expense management, PDF report generation, anomaly detection, manager dashboard, and authentication with Supabase.

## Architecture

### Clean Architecture Implementation
The project follows **Clean Architecture** with clear separation:

- **Domain Layer**: Business logic in `lib/features/*/domain/` with entities, use cases, and repository interfaces. Never imports data layer or infrastructure (PowerSync, Supabase).
- **Data Layer**: External interfaces in `lib/features/*/data/` with PowerSync data sources, models, and repository implementations
- **Presentation Layer**: UI in `lib/features/*/presentation/` using BLoC pattern for state management

### Data Stack
- **PowerSync** : Offline-first local SQLite database that auto-syncs with PostgreSQL (Supabase)
- **Supabase Auth** : Authentication (email/password, Google Sign-In)
- **Supabase Storage** : File storage for PDFs, signatures, receipt photos

### Feature Organization
```
lib/
├── core/
│   ├── auth/                        # AuthRepository (interface + Supabase impl)
│   ├── database/                    # PowerSync config
│   │   ├── schema.dart              # Local SQLite table definitions
│   │   ├── supabase_connector.dart  # PowerSync <-> Supabase connector
│   │   └── powersync_database.dart  # PowerSyncDatabase singleton
│   ├── error/                       # Failure classes (GeneralFailure, ServerFailure, etc.)
│   ├── migration/                   # Isar -> PowerSync one-time migration
│   ├── responsive/                  # Responsive layout (breakpoints, AdaptiveScaffold)
│   └── services/
│       ├── supabase/                # SupabaseService singleton
│       └── storage/                 # StorageService (PDFs, signatures, receipts)
├── features/
│   ├── auth/                        # Login, Register, Forgot Password (BLoC)
│   ├── pointage/                    # Core: time tracking, dashboard, calendar, anomalies, PDF
│   ├── absence/                     # Absence management (vacation, sick, holidays)
│   ├── expense/                     # Expense claims with receipt upload + manager approval
│   ├── validation/                  # Manager validation workflow (Supabase + Edge Functions)
│   ├── preference/                  # User preferences, onboarding, settings
│   ├── manager/                     # Manager dashboard (team view, approvals, anomalies)
│   └── bottom_nav_tab/              # Navigation (BottomNav + Drawer, role-conditional)
└── services/
    ├── injection_container.dart     # GetIt DI (all registrations)
    └── service_factory.dart         # MultiBlocProvider (global BLoCs)
```

## Essential Development Commands

### Setup & Dependencies
```bash
flutter pub get

# Generate Isar models (still needed during migration period)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Running
```bash
flutter run                    # Mobile (default device)
flutter run -d chrome          # Web
flutter run -d macos           # Desktop
```

### Testing & Quality
```bash
flutter test                          # All tests
flutter test test/[test_file].dart    # Specific test
flutter test --coverage               # With coverage
```

### Build Commands
```bash
flutter build apk --release    # Android
flutter build ios --release    # iOS
flutter build web --release    # Web
flutter build macos --release  # macOS
```

## Key Technologies

### Database & Sync
- **PowerSync** (`powersync`): Offline-first SQLite with auto-sync to PostgreSQL
- **Supabase Flutter** (`supabase_flutter`): Auth, Storage, Edge Function calls
- Schema defined in `lib/core/database/schema.dart` (must match PostgreSQL schema)

### State Management
- **BLoC Pattern** (`flutter_bloc`): Events/states/blocs for all features
- **GetIt**: Dependency injection (`services/injection_container.dart`)
- **fpdart**: Functional error handling with `Either<Failure, T>`

### UI & Features
- **Syncfusion**: Calendar (`syncfusion_flutter_calendar`) and charts (`syncfusion_flutter_charts`)
- **PDF Generation**: `pdf` package, use case `GeneratePdfUseCase`
- **Digital Signature**: `signature` package
- **Image Picker**: `image_picker` for receipt photos
- **Responsive**: `lib/core/responsive/responsive_layout.dart` (mobile/tablet/desktop breakpoints)

## Development Patterns

### Dependency Injection
All services, repositories, use cases, and BLoCs registered in `services/injection_container.dart` using GetIt lazy singletons and factories. BLoCs are factories (new instance per widget), use cases are singletons.

### Data Source Pattern (PowerSync)
Data sources execute SQL queries on the local PowerSync SQLite database:

```dart
// Example: reading data
final rows = await db.getAll('SELECT * FROM timesheet_entries WHERE user_id = ?', [userId]);

// Example: writing data (auto-syncs to PostgreSQL)
await db.execute('INSERT INTO expenses (id, user_id, ...) VALUES (?, ?, ...)', [uuid, userId, ...]);

// Example: watching for changes (real-time)
db.watch('SELECT * FROM notifications WHERE user_id = ?', parameters: [userId]);
```

### Use Case Pattern
Business logic in single-responsibility use cases. Returns `Either<Failure, T>` (fpdart):

```dart
class CreateExpenseUseCase {
  final ExpenseRepository repository;
  Future<Either<Failure, Expense>> execute({...}) async { ... }
}
```

### Role-Based Navigation
`BottomNavigationBarPage` checks `profiles.role` via PowerSync:
- **employee**: 5 tabs (Dashboard, Pointage, Time Sheet, Calendrier, Anomalies)
- **manager/admin**: 6 tabs (+ Manager tab with team dashboard)

### Anomaly Detection System
Extensible rule-based system using Registry pattern. Rules in `lib/features/pointage/domain/rules/`. See `lib/features/pointage/domain/rules/README.md` for adding new rules.

## Critical Workflows

### Authentication Flow
```
App Start -> Supabase.initialize() + PowerSync.initialize()
  -> AuthBloc checks session
    -> Not logged in -> LoginPage
    -> Logged in, no profile -> OnboardingPage
    -> Logged in + profile -> BottomNavigationBarPage
```
Key files: `lib/features/auth/presentation/bloc/auth_bloc.dart`, `lib/features/preference/presentation/pages/initial_check_page.dart`

### Expense Workflow
1. Employee creates expense (with optional receipt photo via `image_picker`)
2. Receipt uploaded to Supabase Storage (`receipts/{userId}/{expenseId}.jpg`)
3. Expense saved via PowerSync (syncs to PostgreSQL)
4. Manager sees pending expenses in Manager tab -> approves/rejects
5. Approval status syncs back to employee

### Validation Workflow
1. Employee submits validation -> Edge Function `create-validation`
2. Manager approves -> Edge Function `approve-validation`
3. Cron: Edge Function `check-expired` expires pending > 30 days

### Isar Migration (Legacy)
One-time migration for users upgrading from old Isar version:
`lib/core/migration/isar_to_powersync_migration.dart`

## Storage (Supabase Storage)

Via `lib/core/services/storage/storage_service.dart`:
- `pdfs/{userId}/{year}-{month}.pdf` : Timesheet PDFs
- `signatures/{userId}/signature.png` : Digital signatures
- `receipts/{userId}/{expenseId}.jpg` : Expense receipts

## Configuration

- **Supabase URL + Key**: `lib/core/services/supabase/supabase_service.dart`
- **PowerSync URL**: `lib/core/database/powersync_database.dart`
- **Theme**: `lib/config/theme.dart`
- **Linting**: `analysis_options.yaml` (80-char limit disabled)

## Platform-Specific Notes

### Desktop (Windows/macOS/Linux)
- Fixed window size: 500x1000 via `window_manager`
- Custom database paths: Windows uses `%LOCALAPPDATA%/TimeSheet`
- Path resolution in `injection_container.dart`

### Mobile (iOS/Android)
- Native splash screens with company branding
- Camera/gallery access for receipt photos
- Google Sign-In integration
- Platform-specific permissions (camera, files, notifications)

### Web
- Responsive layout with `ResponsiveLayout` and `AdaptiveScaffold`
- Breakpoints: mobile (<600), tablet (<900), desktop (>=1200)
- NavigationRail on desktop/tablet, BottomNavigationBar on mobile
- Build: `flutter build web --release`

## Adding New Features

1. Create `lib/features/my_feature/domain/` (entity, repository interface, use cases)
2. Create `lib/features/my_feature/data/` (PowerSync data source with SQL queries, repository impl)
3. Create `lib/features/my_feature/presentation/` (BLoC, pages, widgets)
4. Register in `services/injection_container.dart`
5. Add global BLoC to `services/service_factory.dart` if needed
6. If new table: update `lib/core/database/schema.dart` + PostgreSQL migration + PowerSync sync rules

## Code Quality
- Flutter lints with custom analysis options
- 80-character line limit disabled
- French locale support (fr_CH)
- Logger service instead of print statements
- `fpdart` Either for error handling (no exceptions in business logic)
