# Technology Stack

## Core Technologies
- **Framework**: Flutter (SDK >=3.1.2 <4.0.0)
- **Language**: Dart
- **Backend**: Serverpod 2.9.1 (migrating from Supabase)
- **Database**: PostgreSQL (via Serverpod)
- **Local Storage**: Isar ^3.1.0+1
- **State Management**: Flutter BLoC ^9.1.1

## Key Dependencies
- **UI Components**: Syncfusion Calendar/Charts, Lottie animations
- **PDF Processing**: pdf ^3.11.0, printing ^5.13.1
- **Authentication**: Supabase Flutter (transitioning), Firebase Core
- **File Handling**: file_picker, path_provider, open_file
- **Notifications**: flutter_local_notifications
- **Platform Integration**: watch_connectivity (Apple Watch), permission_handler

## Development Tools
- **Linting**: flutter_lints with custom rules in analysis_options.yaml
- **Testing**: mockito, flutter_test, build_runner
- **Code Generation**: Serverpod generate, Isar generator

## Common Commands

### Serverpod Backend
```bash
# Generate Serverpod code
cd time_sheet_backend_server
serverpod generate

# Start backend server
dart bin/main.dart

# Start database services
docker-compose up -d

# Create database migration
serverpod create-migration
```

### Flutter App
```bash
# Run Flutter app
cd time_sheet_backend_flutter
flutter run

# Generate code (Isar, etc.)
flutter packages pub run build_runner build

# Run tests
flutter test

# Build for production
flutter build apk --release
flutter build ios --release
```

### Project Setup
```bash
# Install dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons

# Generate splash screens
flutter pub run flutter_native_splash:create
```

## Architecture Notes
- Follow Serverpod's 3-project structure: server, client, flutter
- Use Clean Architecture principles with feature-based organization
- Prefer composition over inheritance
- Implement proper error handling with Either<Failure, Success> pattern
- Use dependency injection via get_it