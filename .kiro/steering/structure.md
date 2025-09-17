# Project Structure

## Root Structure
```
time_sheet_backend/
├── time_sheet_backend_server/    # Serverpod backend server
├── time_sheet_backend_client/    # Generated Serverpod client
└── time_sheet_backend_flutter/   # Main Flutter application
```

## Flutter App Structure (`time_sheet_backend_flutter/`)

### Core Directories
- **`lib/features/`** - Feature-based modules (absence, dashboard, pointage, validation, etc.)
- **`lib/services/`** - Shared services (API, backup, notifications, timer, etc.)
- **`lib/config/`** - App configuration (themes, constants)
- **`lib/core/`** - Core utilities (error handling, use cases, services)
- **`lib/utils/`** - Utility functions and helpers
- **`lib/enum/`** - Application enumerations

### Feature Organization
Each feature follows Clean Architecture:
```
lib/features/[feature_name]/
├── data/
│   ├── repositories/
│   └── datasources/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── use_cases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

### Assets Structure
- **`assets/images/`** - App logos and static images
- **`assets/animation/`** - Lottie animation files
- **`assets/fonts/`** - Custom fonts (Helvetica)

### Platform-Specific
- **`android/`** - Android configuration and native code
- **`ios/`** - iOS configuration, including TimeSheetWidget
- **`web/`** - Web platform assets and configuration
- **`linux/`, `windows/`** - Desktop platform configurations

## Serverpod Backend Structure (`time_sheet_backend_server/`)

### Core Directories
- **`lib/src/endpoints/`** - API endpoint definitions
- **`lib/src/protocol/`** - Generated protocol classes
- **`lib/src/models/`** - Data models
- **`lib/src/services/`** - Business logic services
- **`config/`** - Environment configurations
- **`migrations/`** - Database migration files
- **`web/`** - Static web assets and templates

## Important Files

### Configuration Files
- **`pubspec.yaml`** - Dependencies and Flutter configuration
- **`analysis_options.yaml`** - Dart linting rules
- **`docker-compose.yaml`** - Database services (PostgreSQL, Redis)

### Documentation
- **`README.md`** - Project setup and usage
- **`SERVERPOD_MIGRATION_PLAN.md`** - Migration strategy from Supabase
- **`contexts/`** - Project context documentation
- **`proposals/`** - Feature proposals and technical designs
- **`user_stories/`** - User story specifications

### Development Files
- **`bruno_collection/`** - API testing collection
- **`supabase/`** - Supabase functions and migrations (legacy)
- **`test/`** - Unit and integration tests

## Naming Conventions
- **Files**: snake_case (e.g., `time_utils.dart`)
- **Classes**: PascalCase (e.g., `ValidationManager`)
- **Variables/Functions**: camelCase (e.g., `calculateWorkTime`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `DEFAULT_WORK_HOURS`)
- **Directories**: snake_case (e.g., `validation_manager`)

## Code Organization Rules
1. Group imports: Dart SDK, Flutter, packages, relative imports
2. Use barrel exports for feature modules
3. Keep widgets under 300 lines, extract smaller widgets
4. Place business logic in use cases, not in UI components
5. Use dependency injection for service access
6. Follow feature-first organization over layer-first