# Design Document - Hardcoded Threshold Fix

## Overview

Cette conception vise à éliminer toutes les valeurs de seuil de travail journalier codées en dur (8h18) et à les remplacer par l'utilisation systématique du paramètre `dailyWorkThresholdMinutes` stocké dans `OvertimeConfiguration`. Le système doit charger dynamiquement ce paramètre depuis la base de données Isar et l'utiliser dans tous les calculs et affichages.

## Architecture

### Composants Modifiés

1. **WeekendOvertimeCalculator** - Accepter le seuil en paramètre au lieu d'utiliser une constante
2. **MonthlyOvertimeCalculator** - Accepter le seuil en paramètre au lieu d'utiliser une constante
3. **CustomAppointmentBuilder** - Charger le seuil depuis OvertimeConfiguration pour les indicateurs visuels
4. **WeekendConfigurationWidget** - Charger le seuil depuis OvertimeConfiguration au lieu d'une valeur par défaut
5. **OvertimeConfigurationWidget** - Charger le seuil depuis OvertimeConfiguration au lieu d'une valeur par défaut
6. **Use Cases** - Passer le seuil configuré aux calculateurs

### Flux de Données

```
OvertimeConfiguration (Isar DB)
        ↓
OvertimeConfigurationRepository
        ↓
Use Cases (CalculateOvertimeHoursUseCase, GeneratePdfUseCase)
        ↓
Calculators (WeekendOvertimeCalculator, MonthlyOvertimeCalculator)
        ↓
UI Components (CustomAppointmentBuilder, Widgets)
```

## Components and Interfaces

### 1. Enhanced WeekendOvertimeCalculator

```dart
class WeekendOvertimeCalculator {
  final WeekendDetectionService _weekendDetectionService;

  /// Default standard work day - used only as fallback
  static const Duration defaultStandardWorkDay = Duration(hours: 8, minutes: 18);

  /// Default overtime rates
  static const double defaultWeekdayOvertimeRate = 1.25;
  static const double defaultWeekendOvertimeRate = 1.5;

  WeekendOvertimeCalculator({
    WeekendDetectionService? weekendDetectionService,
  }) : _weekendDetectionService =
            weekendDetectionService ?? WeekendDetectionService();

  /// Calculates weekday overtime with configurable threshold
  Duration calculateWeekdayOvertime(
    TimesheetEntry entry, {
    Duration? dailyThreshold,
  }) {
    if (entry.isWeekend || !entry.hasOvertimeHours) {
      return Duration.zero;
    }

    final threshold = dailyThreshold ?? defaultStandardWorkDay;
    final totalHours = entry.calculateDailyTotal();
    
    if (totalHours > threshold) {
      return totalHours - threshold;
    }

    return Duration.zero;
  }

  /// Calculates monthly overtime with configurable threshold
  Future<OvertimeSummary> calculateMonthlyOvertime(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
    Duration? dailyThreshold, // NEW PARAMETER
  }) async {
    final effectiveDailyThreshold = dailyThreshold ?? defaultStandardWorkDay;
    // ... rest of implementation using effectiveDailyThreshold
  }

  /// Determines overtime type with configurable threshold
  Future<OvertimeType> determineOvertimeType(
    TimesheetEntry entry, {
    Duration? dailyThreshold, // NEW PARAMETER
  }) async {
    final threshold = dailyThreshold ?? defaultStandardWorkDay;
    // ... rest of implementation using threshold
  }
}
```

### 2. Enhanced MonthlyOvertimeCalculator

```dart
class MonthlyOvertimeCalculator {
  final WeekendDetectionService _weekendDetectionService;

  /// Default standard work day - used only as fallback
  static const Duration defaultStandardWorkDay = Duration(hours: 8, minutes: 18);

  /// Calculates monthly overtime with configurable threshold
  Future<MonthlyOvertimeSummary> calculateMonthlyOvertime(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
    Duration? dailyThreshold, // ALREADY EXISTS - just needs to be used consistently
  }) async {
    final effectiveDailyThreshold = dailyThreshold ?? defaultStandardWorkDay;
    // ... implementation already uses dailyThreshold parameter
  }

  /// Calculates weekly breakdown with configurable threshold
  Future<List<WeeklyOvertimeSummary>> calculateWeeklyBreakdown(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
    Duration? dailyThreshold, // ALREADY EXISTS
  }) async {
    // ... implementation already passes dailyThreshold
  }
}
```

### 3. Enhanced CustomAppointmentBuilder

```dart
class CustomAppointmentBuilder {
  /// Builds appointment with configurable threshold
  static Widget buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details, {
    Duration? dailyThreshold, // CHANGED from double to Duration
  }) {
    final appointment = details.appointments.first as TimesheetAppointment;
    final threshold = dailyThreshold ?? const Duration(hours: 8, minutes: 18);
    
    // ... rest of implementation
  }

  /// Checks if entry has excess hours using configurable threshold
  static bool _hasExcessHours(
    TimesheetAppointment appointment,
    Duration threshold,
  ) {
    final duration = appointment.timesheetEntry.calculateDailyTotal();
    return duration > threshold;
  }
}
```

### 4. Configuration Loading Service

```dart
/// Helper service to load overtime configuration
class OvertimeConfigurationLoader {
  final OvertimeConfigurationRepository _repository;

  OvertimeConfigurationLoader(this._repository);

  /// Gets the configured daily work threshold
  Future<Duration> getDailyWorkThreshold() async {
    final config = await _repository.getOrCreateDefaultConfiguration();
    return config.dailyWorkThreshold;
  }

  /// Gets the configured overtime rates
  Future<OvertimeRates> getOvertimeRates() async {
    final config = await _repository.getOrCreateDefaultConfiguration();
    return OvertimeRates(
      weekdayRate: config.weekdayOvertimeRate,
      weekendRate: config.weekendOvertimeRate,
    );
  }

  /// Gets complete overtime configuration
  Future<OvertimeConfiguration> getConfiguration() async {
    return await _repository.getOrCreateDefaultConfiguration();
  }
}

class OvertimeRates {
  final double weekdayRate;
  final double weekendRate;

  const OvertimeRates({
    required this.weekdayRate,
    required this.weekendRate,
  });
}
```

## Data Flow

### 1. Use Case Level (CalculateOvertimeHoursUseCase)

```dart
class CalculateOvertimeHoursUseCase {
  final OvertimeConfigurationRepository _configRepository;
  final WeekendOvertimeCalculator _weekendCalculator;
  final MonthlyOvertimeCalculator _monthlyCalculator;

  Future<MonthlyOvertimeSummary> executeMonthly(
    List<TimesheetEntry> entries,
  ) async {
    // Load configuration
    final config = await _configRepository.getOrCreateDefaultConfiguration();
    final dailyThreshold = config.dailyWorkThreshold;

    // Pass threshold to calculator
    return await _monthlyCalculator.calculateMonthlyOvertime(
      entries,
      dailyThreshold: dailyThreshold,
      weekdayRate: config.weekdayOvertimeRate,
      weekendRate: config.weekendOvertimeRate,
    );
  }
}
```

### 2. PDF Generation Level (GeneratePdfUseCase)

```dart
class GeneratePdfUseCase {
  final OvertimeConfigurationRepository _configRepository;
  final MonthlyOvertimeCalculator _monthlyCalculator;

  Future<Either<Failure, File>> call(GeneratePdfParams params) async {
    // Load configuration
    final config = await _configRepository.getOrCreateDefaultConfiguration();
    final dailyThreshold = config.dailyWorkThreshold;

    // Use threshold in calculations
    final weeklySummaries = await _monthlyCalculator.calculateWeeklyBreakdown(
      entries,
      dailyThreshold: dailyThreshold,
      weekdayRate: config.weekdayOvertimeRate,
      weekendRate: config.weekendOvertimeRate,
    );

    // ... rest of PDF generation
  }
}
```

### 3. UI Widget Level (WeekendConfigurationWidget)

```dart
class _WeekendConfigurationWidgetState extends State<WeekendConfigurationWidget> {
  Duration _dailyWorkThreshold = const Duration(hours: 8, minutes: 18);

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final config = await widget.configService.getConfiguration();
    if (config != null) {
      setState(() {
        _dailyWorkThreshold = config.dailyWorkThreshold;
        // ... load other settings
      });
    }
  }

  Future<void> _saveConfiguration() async {
    await widget.configService.updateConfiguration(
      dailyWorkThresholdMinutes: _dailyWorkThreshold.inMinutes,
      // ... other settings
    );
  }
}
```

### 4. Calendar Widget Level (CustomAppointmentBuilder)

```dart
// In the parent widget that uses CustomAppointmentBuilder
class CalendarView extends StatefulWidget {
  // ...
}

class _CalendarViewState extends State<CalendarView> {
  Duration? _dailyThreshold;

  @override
  void initState() {
    super.initState();
    _loadThreshold();
  }

  Future<void> _loadThreshold() async {
    final config = await _configRepository.getOrCreateDefaultConfiguration();
    setState(() {
      _dailyThreshold = config.dailyWorkThreshold;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      appointmentBuilder: (context, details) {
        return CustomAppointmentBuilder.buildAppointment(
          context,
          details,
          dailyThreshold: _dailyThreshold,
        );
      },
    );
  }
}
```

## Migration Strategy

### Phase 1: Add Optional Parameters
1. Ajouter le paramètre `dailyThreshold` optionnel à toutes les méthodes de calcul
2. Utiliser la valeur par défaut si le paramètre n'est pas fourni
3. Maintenir la compatibilité avec le code existant

### Phase 2: Update Use Cases
1. Modifier les use cases pour charger la configuration
2. Passer le seuil configuré aux calculateurs
3. Tester les calculs avec différents seuils

### Phase 3: Update UI Components
1. Modifier les widgets pour charger la configuration au démarrage
2. Passer le seuil aux composants d'affichage
3. Mettre à jour les indicateurs visuels

### Phase 4: Remove Hardcoded Values
1. Identifier tous les usages de `Duration(hours: 8, minutes: 18)`
2. Remplacer par des appels à la configuration
3. Supprimer les constantes inutilisées

## Error Handling

### Configuration Loading Errors

```dart
class ConfigurationLoadError extends Failure {
  const ConfigurationLoadError(String message) : super(message);
}

// In use cases
try {
  final config = await _configRepository.getOrCreateDefaultConfiguration();
  final dailyThreshold = config.dailyWorkThreshold;
} catch (e) {
  // Fallback to default
  final dailyThreshold = const Duration(hours: 8, minutes: 18);
  logger.warning('Failed to load configuration, using default: $e');
}
```

### Validation

```dart
// In OvertimeConfiguration.validate()
if (dailyWorkThresholdMinutes < 60) {
  throw ArgumentError('Daily work threshold must be at least 1 hour');
}

if (dailyWorkThresholdMinutes > 1440) {
  throw ArgumentError('Daily work threshold cannot exceed 24 hours');
}
```

## Testing Strategy

### Unit Tests

1. **Calculator Tests with Custom Thresholds**
   - Test WeekendOvertimeCalculator with different thresholds (7h, 8h, 8h18, 9h)
   - Test MonthlyOvertimeCalculator with different thresholds
   - Verify calculations are correct for each threshold

2. **Configuration Loading Tests**
   - Test loading configuration from repository
   - Test fallback to default when configuration is missing
   - Test error handling when loading fails

3. **Widget Tests**
   - Test widgets load configuration on init
   - Test widgets save configuration correctly
   - Test widgets update UI when configuration changes

### Integration Tests

1. **End-to-End Configuration Flow**
   - User changes threshold in settings
   - Verify calculations use new threshold
   - Verify UI indicators reflect new threshold
   - Verify PDF uses new threshold

2. **Default Configuration**
   - First app launch with no configuration
   - Verify default configuration is created
   - Verify default threshold (8h18) is used

## Implementation Notes

### Backward Compatibility

- Tous les paramètres `dailyThreshold` sont optionnels
- Les valeurs par défaut sont maintenues dans les constantes
- Le code existant continue de fonctionner sans modification

### Performance Considerations

- Charger la configuration une fois au démarrage de l'écran
- Mettre en cache la configuration dans les widgets
- Éviter de charger la configuration à chaque calcul

### Code Organization

- Garder les constantes par défaut dans les calculateurs
- Utiliser les constantes uniquement comme fallback
- Documenter clairement que les constantes sont des fallbacks

## Files to Modify

1. **Services**
   - `lib/services/weekend_overtime_calculator.dart`
   - `lib/services/monthly_overtime_calculator.dart`

2. **Use Cases**
   - `lib/features/pointage/domain/use_cases/calculate_overtime_hours_use_case.dart`
   - `lib/features/pointage/domain/use_cases/generate_pdf_usecase.dart`

3. **UI Components**
   - `lib/features/pointage/presentation/widgets/syncfusion_calendar/custom_appointment_builder.dart`
   - `lib/features/preference/presentation/widgets/weekend_configuration_widget.dart`
   - `lib/features/preference/presentation/widgets/overtime_configuration_widget.dart`

4. **Tests**
   - Update all existing tests to pass dailyThreshold parameter
   - Add new tests for configuration loading
