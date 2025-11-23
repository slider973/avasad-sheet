# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Time Sheet Backend** - A comprehensive timesheet management system built with Serverpod backend and Flutter multi-platform frontend. This is a monorepo containing three interconnected packages:

- `time_sheet_backend_server/` - Serverpod backend API server
- `time_sheet_backend_client/` - Auto-generated Serverpod client library
- `time_sheet_backend_flutter/` - Flutter application (iOS, Android, Web, Windows, macOS, Linux)

The system manages employee time tracking, absence management, overtime calculation, PDF report generation, anomaly detection, and manager validation workflows.

## Architecture

### Monorepo Structure

This is a Serverpod monorepo where the three packages work together:

- **Server** defines the protocol (data models) in YAML files
- **Client** is auto-generated from the server's protocol definitions
- **Flutter** consumes the client to communicate with the server

**Critical**: Changes to server protocol require regeneration before the Flutter app can use them.

### Server Architecture (Serverpod)

The backend follows Serverpod's architecture:

- **Protocol Files** (`time_sheet_backend_server/lib/src/protocol/*.yaml`): Define data models as YAML, which generate Dart classes
- **Endpoints** (`time_sheet_backend_server/lib/src/endpoints/*.dart`): API endpoints that handle client requests
- **Services** (`time_sheet_backend_server/lib/src/services/*.dart`): Business logic (PDF generation, weekend overtime calculation)
- **Generated Code** (`time_sheet_backend_server/lib/src/generated/*.dart`): Auto-generated from protocol YAML files

Key endpoints:
- `TimesheetEndpoint`: Unified endpoint using action pattern ('save', 'get', 'update', 'generatePdf')
- `ValidationEndpoint`: Manager validation workflows
- `ManagerEndpoint`: Manager registration and management
- `NotificationEndpoint`: Push notifications

### Flutter Architecture (Clean Architecture + BLoC)

The Flutter app follows Clean Architecture with BLoC pattern:

```
lib/features/
├── pointage/          # Time tracking (core feature)
│   ├── domain/        # Business logic, use cases, entities
│   ├── data/          # Isar models, repositories, data sources
│   └── presentation/  # BLoC, pages, widgets
├── absence/           # Absence management
├── preference/        # User preferences and settings
├── validation/        # Manager validation workflows (Serverpod-based)
└── bottom_nav_tab/    # Navigation components
```

**Data Persistence**: Uses Isar (NoSQL) for local storage and Serverpod client for server communication.

## Essential Development Commands

### Server Development

```bash
# Navigate to server directory
cd time_sheet_backend_server

# Install dependencies
dart pub get

# Start infrastructure (PostgreSQL + Redis)
docker compose up -d

# Start the Serverpod server
dart bin/main.dart

# Generate code after protocol changes (CRITICAL)
serverpod generate

# Create database migration
serverpod create-migration

# Stop infrastructure
docker compose stop
```

### Flutter Development

```bash
# Navigate to Flutter directory
cd time_sheet_backend_flutter

# Install dependencies
flutter pub get

# Generate Isar models and code
flutter packages pub run build_runner build

# Clean and regenerate (when models change)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run tests
flutter test

# Run specific test
flutter test test/[test_file]_test.dart
```

### Client Regeneration

The client is auto-generated. After server protocol changes:

```bash
cd time_sheet_backend_server
serverpod generate  # This regenerates both server and client code

cd ../time_sheet_backend_flutter
flutter pub get  # Pick up the regenerated client
```

## Key Technologies & Patterns

### Backend (Serverpod)

- **Serverpod 2.9.1**: Backend framework with auto-generated client/server code
- **PostgreSQL**: Primary database (runs in Docker on port 8090)
- **Redis**: Caching and sessions (runs in Docker on port 8091)
- **PDF Generation**: Custom PDF layouts with `pdf ^3.11.0` package
- **OpenAI Integration**: AI-powered validation with `dart_openai ^5.1.0`

### Frontend (Flutter)

- **Isar Database**: NoSQL local storage with auto-generated models (`*.g.dart`)
- **BLoC Pattern**: State management with `flutter_bloc` (events/states/blocs)
- **GetIt**: Dependency injection container (`services/injection_container.dart`)
- **Serverpod Flutter**: Client integration with `serverpod_flutter ^2.9.1`
- **Syncfusion**: Calendar and charts (`syncfusion_flutter_calendar`, `syncfusion_flutter_charts`)
- **Signature Capture**: Digital signatures with `signature ^6.3.0`

### Design Patterns

**Unified Endpoint Pattern (Server)**: The `TimesheetEndpoint` uses an action-based pattern where a single endpoint handles multiple operations via an `action` parameter ('save', 'get', 'update', 'generatePdf'). This provides a clean API surface and centralized error handling.

**Anomaly Detection System (Flutter)**: Extensible rule-based system using the Registry pattern. Rules are defined in `lib/features/pointage/domain/rules/` and registered in `AnomalyRuleRegistry`. See `time_sheet_backend_flutter/lib/features/pointage/domain/rules/README.md` for detailed documentation on adding new rules.

**Use Case Pattern**: Business logic is encapsulated in single-responsibility use cases (20+ in `features/pointage/domain/use_cases/`), injected via GetIt.

## Critical Workflows

### Modifying Server Protocol

When adding or changing data models:

1. Edit or create YAML files in `time_sheet_backend_server/lib/src/protocol/`
2. Run `serverpod generate` in the server directory
3. Create migration if database tables changed: `serverpod create-migration`
4. Update client in Flutter app: `cd time_sheet_backend_flutter && flutter pub get`
5. Use the new models in endpoints and Flutter code

### Modifying Flutter Isar Models

When changing local database models:

1. Update model class in `lib/features/*/data/models/` with `@collection` annotation
2. Run `flutter packages pub run build_runner build --delete-conflicting-outputs`
3. Update schema registration in `services/injection_container.dart` if needed

### Weekend Overtime Calculation

The system has specific logic for weekend overtime:
- Service: `time_sheet_backend_server/lib/src/services/weekend_overtime_calculator_service.dart`
- Flutter calculator: `time_sheet_backend_flutter/lib/services/weekend_overtime_calculator.dart`
- Recent implementation focuses on monthly-only calculation (see commit: "feat: Simplification du système d'heures supplémentaires - calcul mensuel uniquement")

### Validation Workflow

Manager validation uses Serverpod:
- Server endpoints: `ValidationEndpoint`, `ManagerEndpoint`
- Flutter feature: `lib/features/validation/`
- Local cache models: `ValidationRequestCache`, `NotificationCache`, `SyncQueueItem`
- Repository: `ValidationRepositoryServerpodImpl` (uses Serverpod client)

## Testing & Development Tools

### API Testing

**Bruno Collection**: API testing collection in `bruno_collection/` directory
- Contains pre-configured requests for all endpoints
- Useful for testing server endpoints directly
- See `bruno_collection/README.md` for usage

### Running Tests

```bash
# Server tests
cd time_sheet_backend_server
dart test

# Flutter tests
cd time_sheet_backend_flutter
flutter test

# Integration tests
cd time_sheet_backend_flutter
flutter test test/integration/
```

### Docker Services

Development services (docker-compose.yaml):
- PostgreSQL: `localhost:8090` (user: postgres, db: time_sheet_backend)
- Redis: `localhost:8091` (with auth)
- Test services run on ports 9090/9091

## Platform-Specific Considerations

### Desktop (Windows/macOS/Linux)
- Fixed window size: 500x1000 via `window_manager`
- Custom database paths: Windows uses `%LOCALAPPDATA%/TimeSheet`
- Path resolution in `injection_container.dart:74-100`

### Mobile (iOS/Android)
- Native splash screens with company branding
- Platform-specific permissions (camera, files, notifications)
- Google Sign-In integration (iOS/Android)

### Multi-Platform Support
- Conditional compilation for platform-specific features
- Path provider handles platform differences automatically
- Shared preferences for cross-platform settings

## Recent Changes & Migration Notes

### Serverpod Migration
This project is migrating from Supabase to Serverpod for cost reduction. Some features still use Supabase:
- Validation feature uses both Serverpod and Supabase (`supabase_flutter: ^2.3.4`)
- Check `time_sheet_backend_flutter/SERVERPOD_MIGRATION_PLAN.md` for migration status

### Overtime Calculation Simplification
Recent commit simplified overtime to monthly-only calculation (commit 6b4db23). Weekend overtime is still calculated but integrated into monthly totals.

### Overtime/Deficit Display Fix
Fixed PDF generation to always show daily surplus and deficits in the "Dont heures supplémentaires" column, even when monthly compensation results in zero overtime. This provides full transparency on daily work variations.

### UI Modernization
Navigation structure updated with 5 bottom tabs (Dashboard, Pointage, Time Sheet, Calendrier, Anomalies) and Settings moved to drawer menu.

## Planned Features

### Expense Management (Notes de Frais)
A comprehensive expense management feature is planned to handle:
- 🚗 Mileage tracking with automatic calculation (km × rate)
- 🍽️ Meal expenses
- 💼 Other professional expenses
- 📄 PDF expense report generation
- ✅ Manager validation workflow

See `EXPENSE_MANAGEMENT_PLAN.md` for complete implementation plan with architecture, data models, use cases, and UI designs. Estimated implementation: 16-22 hours.

## Dependency Injection

All services, repositories, and use cases are registered in `time_sheet_backend_flutter/lib/services/injection_container.dart`:

```dart
final getIt = GetIt.instance;

// Access services
final anomalyService = getIt<AnomalyDetectionService>();
final timerService = getIt<TimerService>();
```

Database initialization is platform-specific with proper path handling for Windows/macOS/Linux.

## Configuration Files

### Server Configuration
- `time_sheet_backend_server/config/development.yaml`: Dev settings
- `time_sheet_backend_server/config/passwords.yaml`: Secrets (DB, Redis, OpenAI API key)
- `time_sheet_backend_server/config/generator.yaml`: Code generation settings

### Flutter Configuration
- `time_sheet_backend_flutter/lib/config/theme.dart`: App theming
- `time_sheet_backend_flutter/analysis_options.yaml`: Linting rules (80-char limit disabled)

## Common Development Tasks

### Adding a New Anomaly Rule

See comprehensive guide in `time_sheet_backend_flutter/lib/features/pointage/domain/rules/README.md`. Quick steps:
1. Create rule class in `lib/features/pointage/domain/rules/impl/`
2. Register in `AnomalyRuleRegistry.initialize()`
3. Rule becomes immediately available throughout the app

### Creating a New Serverpod Endpoint

1. Create YAML model in `time_sheet_backend_server/lib/src/protocol/`
2. Create endpoint in `time_sheet_backend_server/lib/src/endpoints/`
3. Run `serverpod generate`
4. Access from Flutter via generated client: `client.yourEndpoint.methodName()`

### Generating PDF Reports

PDF generation happens both server-side and client-side:
- Server: `time_sheet_backend_server/lib/src/services/pdf_generator_service.dart`
- Flutter: Use case `GeneratePdfUseCase` with signature support
- Custom fonts: Helvetica in `assets/fonts/`
