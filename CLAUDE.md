# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Time Sheet Application for HeyTalent** - A comprehensive Flutter timesheet management application with multi-platform support (iOS, Android, Web, Windows, macOS, Linux). Features include time tracking, absence management, PDF report generation, anomaly detection, and user preferences.

## Architecture

### Clean Architecture Implementation
The project follows **Clean Architecture** with clear separation:

- **Domain Layer**: Business logic in `lib/features/*/domain/` with entities, use cases, and repository interfaces
- **Data Layer**: External interfaces in `lib/features/*/data/` with models (Isar annotations), data sources, and repository implementations  
- **Presentation Layer**: UI in `lib/features/*/presentation/` using BLoC pattern for state management

### Feature Organization
```
lib/features/
├── pointage/          # Core time tracking functionality
├── absence/           # Absence management (vacation, sick leave, holidays)
├── preference/        # User preferences and settings
└── bottom_nav_tab/    # Navigation components
```

## Essential Development Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Generate Isar models and code generation
flutter packages pub run build_runner build

# Clean and regenerate (when models change)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Testing & Quality
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/[test_file]_test.dart

# Run tests with coverage
flutter test --coverage
```

### Build Commands
```bash
# Development builds
flutter run                    # Hot reload development
flutter build apk --debug      # Android debug
flutter build ios --debug      # iOS debug

# Release builds  
flutter build apk --release    # Android release
flutter build ios --release    # iOS release
flutter build web --release    # Web release
flutter build windows          # Windows
flutter build macos            # macOS
```

## Key Technologies

### Database & State Management
- **Isar Database**: NoSQL database with auto-generated models (`*.g.dart` files)
- **BLoC Pattern**: `flutter_bloc` for state management with events/states/blocs
- **GetIt**: Dependency injection container (`services/injection_container.dart`)

### Core Features
- **PDF Generation**: Custom PDF layouts with `pdf ^3.11.0`
- **Calendar Integration**: `table_calendar` and `syncfusion_flutter_calendar`
- **Charts & Analytics**: `fl_chart` and `syncfusion_flutter_charts`
- **Notifications**: `flutter_local_notifications` with timezone support

## Development Patterns

### Dependency Injection Setup
All services and use cases are registered in `services/injection_container.dart` using lazy singletons. Database paths are platform-specific (Windows uses `%LOCALAPPDATA%/TimeSheet`).

### Database Schema Changes
When modifying Isar models:
1. Update model class with `@collection` annotation
2. Run `flutter packages pub run build_runner build --delete-conflicting-outputs`
3. Update schema registration in `injection_container.dart`

### Use Case Pattern
Business logic is encapsulated in use cases (20+ in `features/pointage/use_cases/`). Each use case follows single responsibility and is injected via GetIt.

### Anomaly Detection System
Custom anomaly detection with multiple detectors (`AnomalyDetectorFactory`) for insufficient hours, scheduling conflicts, etc.

## Platform-Specific Notes

### Desktop Applications
- Fixed window size: 500x1000 for consistent UX
- Custom database paths with proper permissions
- Window management via `window_manager`

### Mobile Applications  
- Native splash screens with company branding
- Multiple app icon resolutions
- Platform-specific permissions (camera, files, notifications)

### Testing Strategy
- Unit tests for use cases and business logic
- Mockito for mocking dependencies
- Test utilities in `test/test_utils.dart`

## Code Quality
- Flutter lints enabled with custom analysis options
- 80-character line limit disabled for practical development
- French locale support (fr_CH) with localization