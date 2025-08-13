# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Time Sheet Application for HeyTalent** - A comprehensive Flutter timesheet management application with multi-platform support (iOS, Android, Web, Windows, macOS, Linux). Features include time tracking, absence management, PDF report generation, anomaly detection, user preferences, and onboarding flow.

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
- **Digital Signature**: `signature` package for capturing user signatures
- **Onboarding**: First-run experience to collect user info (name, company, signature)

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

## Recent Updates & Bug Fixes

### Timer Synchronization Fix (2025-07-10)
- Fixed timer bug where it wasn't synchronized with first pointage
- Modified `TimerService.initialize()` to handle null `dernierPointage` 
- Timer now uses actual pointage time instead of `DateTime.now()`
- Added proper handling for first pointage of the day

### Navigation Restructure (2025-07-10)
- Moved Settings tab from bottom navigation to drawer menu
- Added existing Dashboard as first tab in bottom navigation (reused from `pointage/presentation/pages/dashboard/`)
- Bottom navigation now has 5 tabs: Dashboard, Pointage, Time Sheet, Calendrier, Anomalies
- Settings accessible via "Paramètres" in drawer menu
- Updated all navigation-related BLoCs and widgets
- Dashboard features: metrics overview, weekly progress chart, monthly summary, recent activities, quick actions

### Onboarding System (2025-07-10)
- Added `OnboardingPage` with 2-step flow: user info + signature
- Created `InitialCheckPage` that verifies if onboarding is complete
- Added "company" field to user preferences (no longer hardcoded as "Avasad")
- Updated `PreferencesBloc`, `PreferencesState`, and `PreferencesEvent` for company support
- Fixed Scaffold context error in `PreferencesFormV2` using Builder pattern

### Navigation Architecture Fix (2025-07-10)
- Fixed setState after dispose error in PointageWidget by checking mounted in animation listener
- Added mounted check for async operations (showTimePicker)
- Navigation structure:
  - Main Scaffold with drawer is in `BottomNavigationBarPage`
  - Tab pages (PointagePage, etc.) have their own Scaffold for independence
  - Drawer is accessible via swipe gesture on mobile
  - Secondary pages (from drawer) show back arrow automatically
- Removed menu burger from tab pages to avoid Scaffold context issues

### User Preferences Enhancement
- Extended `User` entity to include company field
- Updated PDF generation to use company from preferences
- Modified preference forms to include company field
- Created reusable `SignaturePadWidget` component

## Code Quality
- Flutter lints enabled with custom analysis options
- 80-character line limit disabled for practical development
- French locale support (fr_CH) with localization
- Replace print statements with logger service