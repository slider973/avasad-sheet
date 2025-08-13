# Project Structure & Organization

## Root Structure
```
time_sheet_backend/
├── time_sheet_backend_server/     # Serverpod backend server
├── time_sheet_backend_client/     # Auto-generated Serverpod client
├── time_sheet_backend_flutter/    # Main Flutter application
├── bruno_collection/              # API testing collection
├── test_timesheet_direct.dart     # Direct database testing
└── *.md                          # Project documentation
```

## Backend Server (`time_sheet_backend_server/`)
```
lib/
├── src/
│   ├── endpoints/                 # API endpoints
│   ├── generated/                 # Auto-generated Serverpod code
│   ├── protocol/                  # Data models and protocol
│   ├── models/                    # Business logic models
│   └── web/                       # Web server assets
├── server.dart                    # Main server entry point
config/                            # Environment configurations
migrations/                        # Database migrations
web/                              # Static web assets
```

## Flutter App (`time_sheet_backend_flutter/`)

### Core Architecture (Clean Architecture + BLoC)
```
lib/
├── core/
│   ├── error/                     # Failure classes and exceptions
│   ├── services/                  # Service layer (Firebase, Supabase, Serverpod)
│   └── use_cases/                 # Abstract use case definitions
├── features/                      # Feature-based organization
│   ├── absence/
│   ├── bottom_nav_tab/
│   ├── dashboard/
│   ├── pointage/                  # Time tracking
│   ├── preference/
│   └── validation/
├── services/                      # App-wide services
├── config/                        # App configuration (theme, etc.)
├── enum/                          # Enumerations
├── utils/                         # Utility functions
└── main.dart                      # App entry point
```

### Feature Structure Pattern
Each feature follows Clean Architecture:
```
features/[feature_name]/
├── data/
│   ├── datasources/              # Remote/local data sources
│   ├── models/                   # Data models
│   └── repositories/             # Repository implementations
├── domain/
│   ├── entities/                 # Business entities
│   ├── repositories/             # Repository interfaces
│   └── usecases/                 # Business logic use cases
└── presentation/
    ├── bloc/                     # BLoC state management
    ├── pages/                    # UI screens
    └── widgets/                  # Reusable UI components
```

## Key Directories

### Services Layer
- `core/services/serverpod/`: Current backend service
- `core/services/supabase/`: Legacy service (being phased out)
- `core/services/firebase/`: Legacy service (being phased out)
- `services/`: App services (logger, PDF parser, notifications, etc.)

### Configuration
- `config/`: App-wide configuration (themes, constants)
- `assets/`: Images, animations, fonts
- `contexts/`: Documentation and context files

### Testing
- `test/`: Unit and integration tests
- `bruno_collection/`: API testing with Bruno HTTP client

## Naming Conventions

### Files & Directories
- **snake_case** for all file and directory names
- **Feature-based** organization over layer-based
- **Descriptive names** that indicate purpose

### Dart Code
- **PascalCase** for classes: `ValidationRequest`, `ServerFailure`
- **camelCase** for variables and methods: `employeeId`, `createValidation`
- **SCREAMING_SNAKE_CASE** for constants: `API_BASE_URL`

### Database
- **snake_case** for table and column names
- **Plural** table names: `validation_requests`, `managers`

## Import Organization
1. Dart/Flutter SDK imports
2. Third-party package imports
3. Local project imports (relative paths)
4. Separate groups with blank lines

## Error Handling Pattern
- Custom `Failure` classes extending `Equatable`
- Specific failure types: `ServerFailure`, `NetworkFailure`, `ValidationFailure`
- Consistent error propagation through Either<Failure, Success> pattern

## State Management
- **BLoC pattern** for complex state management
- **GetX** for simple state and navigation
- **Isar** for local data persistence
- **Serverpod client** for backend communication

## Localization
- **French (Switzerland)** as primary locale: `fr_CH`
- Internationalization support with `flutter_localizations`
- Date formatting with Swiss conventions