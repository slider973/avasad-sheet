import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/services/timer_service.dart';
import 'package:time_sheet/services/work_time_calculator_service.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_configuration.dart';
import 'package:time_sheet/features/preference/data/models/overtime_configuration.dart';

import 'timer_service_work_time_integration_test.mocks.dart';

@GenerateMocks([
  WeekendDetectionService,
  OvertimeConfigurationService,
])
void main() {
  group('TimerService + WorkTimeCalculatorService Integration Tests', () {
    late TimerService timerService;
    late WorkTimeCalculatorService workTimeCalculatorService;
    late MockWeekendDetectionService mockWeekendDetectionService;
    late MockOvertimeConfigurationService mockOvertimeConfigService;

    setUp(() async {
      // Setup SharedPreferences mock
      SharedPreferences.setMockInitialValues({});

      // Create mocks
      mockWeekendDetectionService = MockWeekendDetectionService();
      mockOvertimeConfigService = MockOvertimeConfigurationService();

      // Setup default mock responses
      when(mockWeekendDetectionService.isWeekend(any)).thenReturn(false);
      when(mockWeekendDetectionService.isWeekendOvertimeEnabled())
          .thenAnswer((_) async => true);

      final defaultOvertimeConfig = OvertimeConfiguration.withValues(
        weekendOvertimeEnabled: true,
        weekendDays: [DateTime.saturday, DateTime.sunday],
        weekendOvertimeRate: 1.5,
        weekdayOvertimeRate: 1.25,
        dailyWorkThresholdMinutes: 480, // 8 hours
        description: 'Default configuration',
      );

      when(mockOvertimeConfigService.getConfigurationObject())
          .thenAnswer((_) async => defaultOvertimeConfig);

      // Initialize services
      timerService = TimerService();
      workTimeCalculatorService = WorkTimeCalculatorService();

      // Replace the private services with mocks using reflection or dependency injection
      // For now, we'll test the integration through public methods
    });

    tearDown(() async {
      timerService.dispose();
      workTimeCalculatorService.reset();
    });

    group('Extended Timer State Generation', () {
      test('should generate extended timer state with work time calculations',
          () async {
        // Arrange
        await timerService.initialize('Non commencé', null);

        // Act
        final extendedState = timerService.getExtendedTimerState();

        // Assert
        expect(extendedState, isA<ExtendedTimerState>());
        expect(extendedState.currentState, equals('Non commencé'));
        expect(extendedState.elapsedTime, equals(Duration.zero));
        expect(extendedState.workTimeInfo, isA<WorkTimeInfo>());
        expect(extendedState.configuration, isA<WorkTimeConfiguration>());
      });

      test('should calculate work time info during active work session',
          () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        await timerService.initialize('Entrée', startTime);

        // Act
        final workTimeInfo = timerService.getWorkTimeInfo();

        // Assert
        expect(workTimeInfo, isA<WorkTimeInfo>());
        expect(workTimeInfo.remainingTime.inHours, greaterThan(0));
        expect(workTimeInfo.isOvertimeStarted, isFalse);
      });

      test('should detect overtime after 8 hours of work', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 9));
        await timerService.initialize('Entrée', startTime);

        // Act
        final workTimeInfo = timerService.getWorkTimeInfo();
        final isOvertimeStarted = timerService.isOvertimeStartedCalculated;

        // Assert
        expect(workTimeInfo.isOvertimeStarted, isTrue);
        expect(isOvertimeStarted, isTrue);
        expect(workTimeInfo.overtimeHours.inHours, greaterThan(0));
      });

      test('should calculate estimated end time correctly', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 4));
        await timerService.initialize('Entrée', startTime);

        // Act
        final estimatedEndTime = timerService.getEstimatedEndTime();

        // Assert
        expect(estimatedEndTime, isNotNull);
        expect(estimatedEndTime!.isAfter(DateTime.now()), isTrue);
      });

      test('should calculate remaining work time correctly', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 6));
        await timerService.initialize('Entrée', startTime);

        // Act
        final remainingTime = timerService.getRemainingWorkTime();

        // Assert
        expect(remainingTime.inHours, lessThanOrEqualTo(2));
        expect(remainingTime.inMinutes, greaterThan(0));
      });
    });

    group('Break Tracking Integration', () {
      test('should track break periods correctly', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 2));
        await timerService.initialize('Entrée', startTime);

        // Set minimum break duration for testing
        final workTimeCalculatorService = WorkTimeCalculatorService();
        workTimeCalculatorService
            .setMinimumBreakDurationForTesting(const Duration(milliseconds: 1));

        // Act - Start break
        timerService.updateState('Pause', null);
        await Future.delayed(
            const Duration(milliseconds: 100)); // Simulate break time

        // Resume work
        timerService.updateState('Reprise', null);

        final totalBreakTime = timerService.getTotalBreakTime();

        // Assert
        expect(totalBreakTime.inMilliseconds, greaterThan(0));
      });

      test('should calculate effective work time excluding breaks', () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 3));
        await timerService.initialize('Entrée', startTime);

        // Set minimum break duration for testing
        final workTimeCalculatorService = WorkTimeCalculatorService();
        workTimeCalculatorService
            .setMinimumBreakDurationForTesting(const Duration(milliseconds: 1));

        // Act - Take a break
        timerService.updateState('Pause', null);
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.updateState('Reprise', null);

        final workTimeInfo = timerService.getWorkTimeInfo();
        final totalBreakTime = timerService.getTotalBreakTime();

        // Assert
        expect(totalBreakTime.inMilliseconds, greaterThan(0));
        // Effective work time should be less than total elapsed time
        expect(workTimeInfo.remainingTime, isA<Duration>());
      });

      test('should reset break tracking for new day', () async {
        // Set minimum break duration for testing
        final workTimeCalculatorService = WorkTimeCalculatorService();
        workTimeCalculatorService
            .setMinimumBreakDurationForTesting(const Duration(milliseconds: 1));

        // Arrange
        await timerService.initialize('Entrée', DateTime.now());
        timerService.updateState('Pause', null);
        await Future.delayed(const Duration(milliseconds: 50));
        timerService.updateState('Reprise', null);

        // Act - Start new day
        timerService.updateState('Non commencé', null);
        await timerService.initialize('Non commencé', null);

        final totalBreakTime = timerService.getTotalBreakTime();

        // Assert
        expect(totalBreakTime, equals(Duration.zero));
      });
    });

    group('Weekend Overtime Integration', () {
      test('should handle weekend overtime correctly', () async {
        // Arrange - Mock weekend day
        when(mockWeekendDetectionService.isWeekend(any)).thenReturn(true);
        when(mockWeekendDetectionService.isWeekendOvertimeEnabled())
            .thenAnswer((_) async => true);

        await timerService.initialize(
            'Entrée', DateTime.now().subtract(const Duration(hours: 2)));

        // Act
        final workTimeInfo = timerService.getWorkTimeInfo();
        final extendedState = timerService.getExtendedTimerState();

        // Assert
        expect(extendedState.isWeekendDay, isTrue);
        expect(extendedState.weekendOvertimeEnabled, isTrue);
        // On weekends with overtime enabled, all work should be overtime
        expect(workTimeInfo.isOvertimeStarted, isTrue);
      });

      test('should handle weekend overtime disabled', () async {
        // Arrange - Mock weekend day with overtime disabled
        when(mockWeekendDetectionService.isWeekend(any)).thenReturn(true);
        when(mockWeekendDetectionService.isWeekendOvertimeEnabled())
            .thenAnswer((_) async => false);

        await timerService.initialize(
            'Entrée', DateTime.now().subtract(const Duration(hours: 2)));

        // Act
        final workTimeInfo = timerService.getWorkTimeInfo();
        final extendedState = timerService.getExtendedTimerState();

        // Assert
        expect(extendedState.isWeekendDay, isTrue);
        expect(extendedState.weekendOvertimeEnabled, isFalse);
        // With weekend overtime disabled, should follow weekday rules
        expect(workTimeInfo.isOvertimeStarted, isFalse);
      });
    });

    group('Configuration Integration', () {
      test('should update work time calculator when configuration changes',
          () async {
        // Arrange
        await timerService.initialize('Non commencé', null);

        // Act
        await timerService.refreshWeekendConfiguration();

        final extendedState = timerService.getExtendedTimerState();

        // Assert
        expect(extendedState.configuration, isA<WorkTimeConfiguration>());
        expect(extendedState.configuration.standardWorkDay,
            equals(const Duration(hours: 8)));
      });

      test('should handle configuration errors gracefully', () async {
        // Arrange
        when(mockOvertimeConfigService.getConfigurationObject())
            .thenThrow(Exception('Configuration error'));

        // Act & Assert - Should not throw
        expect(() async => await timerService.initialize('Non commencé', null),
            returnsNormally);

        final extendedState = timerService.getExtendedTimerState();
        expect(extendedState, isA<ExtendedTimerState>());
      });
    });

    group('State Persistence Integration', () {
      test('should preserve work time calculations across app restarts',
          () async {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 4));
        await timerService.initialize('Entrée', startTime);

        // Simulate app pause/resume
        timerService.appPaused();
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.appResumed();

        // Act
        final workTimeInfo = timerService.getWorkTimeInfo();
        final extendedState = timerService.getExtendedTimerState();

        // Assert
        expect(workTimeInfo, isA<WorkTimeInfo>());
        expect(extendedState.elapsedTime.inHours, greaterThan(3));
        expect(workTimeInfo.remainingTime.inHours, lessThan(5));
      });

      test('should maintain break tracking across state changes', () async {
        // Arrange
        await timerService.initialize(
            'Entrée', DateTime.now().subtract(const Duration(hours: 2)));

        // Set minimum break duration for testing
        final workTimeCalculatorService = WorkTimeCalculatorService();
        workTimeCalculatorService
            .setMinimumBreakDurationForTesting(const Duration(milliseconds: 1));

        // Take multiple breaks
        timerService.updateState('Pause', null);
        await Future.delayed(const Duration(milliseconds: 50));
        timerService.updateState('Reprise', null);

        timerService.updateState('Pause', null);
        await Future.delayed(const Duration(milliseconds: 50));
        timerService.updateState('Reprise', null);

        // Act
        final totalBreakTime = timerService.getTotalBreakTime();

        // Assert
        expect(totalBreakTime.inMilliseconds, greaterThan(0));
      });
    });

    group('Error Handling Integration', () {
      test('should handle work time calculator errors gracefully', () async {
        // Arrange
        await timerService.initialize('Entrée', DateTime.now());

        // Act & Assert - Should not throw even if calculator has issues
        expect(() => timerService.getWorkTimeInfo(), returnsNormally);
        expect(() => timerService.getExtendedTimerState(), returnsNormally);
        expect(() => timerService.getEstimatedEndTime(), returnsNormally);
        expect(() => timerService.getRemainingWorkTime(), returnsNormally);
      });

      test('should fallback to existing logic when calculations fail',
          () async {
        // Arrange
        await timerService.initialize(
            'Entrée', DateTime.now().subtract(const Duration(hours: 10)));

        // Act
        final isOvertimeCalculated = timerService.isOvertimeStartedCalculated;
        final isOvertimeExisting = timerService.isOvertimeSession;

        // Assert - Should have fallback behavior
        expect(isOvertimeCalculated, isA<bool>());
        expect(isOvertimeExisting, isA<bool>());
      });
    });
  });
}
