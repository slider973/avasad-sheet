# Technical Stack & Build System

## Architecture Overview
**Monorepo structure** with three main components:
- `time_sheet_backend_server/`: Serverpod backend server
- `time_sheet_backend_client/`: Auto-generated Serverpod client
- `time_sheet_backend_flutter/`: Flutter application

## Tech Stack

### Backend (Serverpod)
- **Framework**: Serverpod 2.9.1 (Dart backend framework)
- **Language**: Dart 3.5.0+
- **Database**: PostgreSQL (via Docker)
- **Cache**: Redis (via Docker)
- **PDF Processing**: pdf package for generation
- **Encryption**: crypto package for security

### Frontend (Flutter)
- **Framework**: Flutter 3.1.2+ with Dart 3.1.2+
- **State Management**: flutter_bloc 9.1.1 + get 4.6.6
- **Local Storage**: Isar 3.1.0+1 (NoSQL database)
- **Architecture**: Clean Architecture with BLoC pattern
- **Error Handling**: Custom Failure classes with Equatable

### Key Dependencies
- **UI**: Syncfusion widgets, Lottie animations, Material Design
- **Platform**: Multi-platform support (iOS, Android, Web, macOS, Windows)
- **Services**: Supabase (legacy), Firebase (legacy), Serverpod (current)
- **Monitoring**: Sentry for error tracking
- **Localization**: French (Switzerland) - fr_CH locale

## Common Commands

### Development Setup
```bash
# Start Docker services (PostgreSQL + Redis)
cd time_sheet_backend_server
docker-compose up -d

# Generate Serverpod code after model changes
cd time_sheet_backend_server
serverpod generate

# Create database migrations
cd time_sheet_backend_server
serverpod create-migration --force
```

### Running Services
```bash
# Start backend server
cd time_sheet_backend_server
dart bin/main.dart --apply-migrations

# Start Flutter app
cd time_sheet_backend_flutter
flutter pub get
flutter run
```

### Development Ports
- **8080**: Serverpod API
- **8081**: Serverpod Insights (monitoring)
- **8082**: Serverpod web server
- **8090**: PostgreSQL
- **8091**: Redis

### Testing
```bash
# Run Flutter tests
cd time_sheet_backend_flutter
flutter test

# Run server tests
cd time_sheet_backend_server
dart test
```

### Build & Deploy
```bash
# Build Flutter for production
cd time_sheet_backend_flutter
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
flutter build macos        # macOS
flutter build windows      # Windows

# Docker deployment
cd time_sheet_backend_server
docker build -t timesheet-server .
```

## Code Generation
- **Serverpod**: Auto-generates client code from server models
- **Isar**: Database schema generation with build_runner
- **Icons**: flutter_launcher_icons for app icons
- **Splash**: flutter_native_splash for launch screens

## Migration Notes
- **Legacy**: Supabase and Firebase services (being phased out)
- **Current**: Serverpod migration in progress
- **Target**: Self-hosted solution for cost reduction