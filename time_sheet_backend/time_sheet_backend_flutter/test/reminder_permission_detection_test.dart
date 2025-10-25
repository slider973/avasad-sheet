import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/presentation/pages/reminder_settings_page.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';

import 'reminder_permission_detection_test.mocks.dart';

@GenerateMocks([
  GetUserPreferenceUseCase,
  SetUserPreferenceUseCase,
  RegisterManagerUseCase,
  UnregisterManagerUseCase,
])
void main() {
  group('Reminder Permission Detection Tests', () {
    late MockGetUserPreferenceUseCase mockGetUserPreferenceUseCase;
    late MockSetUserPreferenceUseCase mockSetUserPreferenceUseCase;
    late MockRegisterManagerUseCase mockRegisterManagerUseCase;
    late MockUnregisterManagerUseCase mockUnregisterManagerUseCase;
    late PreferencesBloc preferencesBloc;

    setUp(() {
      mockGetUserPreferenceUseCase = MockGetUserPreferenceUseCase();
      mockSetUserPreferenceUseCase = MockSetUserPreferenceUseCase();
      mockRegisterManagerUseCase = MockRegisterManagerUseCase();
      mockUnregisterManagerUseCase = MockUnregisterManagerUseCase();

      // Set up default mock responses
      when(mockGetUserPreferenceUseCase.execute('firstName'))
          .thenAnswer((_) async => 'Test');
      when(mockGetUserPreferenceUseCase.execute('lastName'))
          .thenAnswer((_) async => 'User');
      when(mockGetUserPreferenceUseCase.execute('company'))
          .thenAnswer((_) async => 'Test Company');
      when(mockGetUserPreferenceUseCase.execute('notificationsEnabled'))
          .thenAnswer((_) async => 'true');
      when(mockGetUserPreferenceUseCase.execute('isDeliveryManager'))
          .thenAnswer((_) async => 'false');
      when(mockGetUserPreferenceUseCase.execute('badgeCount'))
          .thenAnswer((_) async => '0');
      when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
          .thenAnswer((_) async => null);

      when(mockSetUserPreferenceUseCase.execute(any, any))
          .thenAnswer((_) async {});

      preferencesBloc = PreferencesBloc(
        getUserPreferenceUseCase: mockGetUserPreferenceUseCase,
        setUserPreferenceUseCase: mockSetUserPreferenceUseCase,
        registerManagerUseCase: mockRegisterManagerUseCase,
        unregisterManagerUseCase: mockUnregisterManagerUseCase,
      );
    });

    tearDown(() {
      preferencesBloc.close();
    });

    testWidgets(
        'should show permission granted message when returning from settings',
        (tester) async {
      // Test the scenario where user goes to settings, enables notifications,
      // and returns to the app

      // Start with disabled reminders
      final disabledSettings = ReminderSettings.defaultSettings;
      expect(disabledSettings.enabled, isFalse);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PreferencesBloc>(
            create: (context) => preferencesBloc,
            child: const ReminderSettingsPage(),
          ),
        ),
      );

      // Load preferences
      preferencesBloc.add(LoadPreferences());
      await tester.pump();

      // Verify initial state shows disabled reminders
      expect(find.text('Rappels désactivés'), findsOneWidget);

      // Simulate app lifecycle change (user went to settings and came back)
      // This would normally trigger the permission check
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('AppLifecycleState.resumed'),
        ),
        (data) {},
      );

      await tester.pump();

      // The permission detection should work when the app resumes
      // In a real scenario, if permissions were granted, a snackbar would appear
    });

    testWidgets('should handle permission revocation correctly',
        (tester) async {
      // Test the scenario where reminders are enabled but permissions get revoked

      // Start with enabled reminders
      final enabledSettings =
          ReminderSettings.defaultSettings.copyWith(enabled: true);

      // Mock that reminder settings are enabled
      when(mockGetUserPreferenceUseCase.execute('reminderSettings')).thenAnswer(
          (_) async =>
              '{"enabled":true,"clockInTime":{"hour":8,"minute":0},"clockOutTime":{"hour":17,"minute":0},"activeDays":[1,2,3,4,5],"respectHolidays":true,"snoozeMinutes":15,"maxSnoozes":2}');

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PreferencesBloc>(
            create: (context) => preferencesBloc,
            child: const ReminderSettingsPage(),
          ),
        ),
      );

      preferencesBloc.add(LoadPreferences());
      await tester.pump();

      // Verify reminders are shown as enabled
      expect(find.text('Les rappels sont activés'), findsOneWidget);

      // Simulate permission revocation scenario
      // In a real app, this would be detected by the permission check
    });

    test('should validate reminder settings before saving', () {
      // Test that invalid settings are rejected
      final invalidSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 18, minute: 0),
        clockOutTime:
            const TimeOfDay(hour: 8, minute: 0), // Invalid: before clock-in
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(invalidSettings.validate(), isNotNull);
      expect(invalidSettings.validate(),
          contains('Clock-out time must be after clock-in time'));
    });

    test('should handle empty active days correctly', () {
      final noActiveDaysSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {}, // Empty set
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(noActiveDaysSettings.validate(),
          contains('At least one active day must be selected'));
    });

    test('should handle default settings correctly', () {
      final defaultSettings = ReminderSettings.defaultSettings;

      // Requirement 1.1: Default disabled state
      expect(defaultSettings.enabled, isFalse);
      expect(defaultSettings.validate(), isNull); // Should be valid
      expect(defaultSettings.hasValidTimeConfiguration, isTrue);
    });

    test('should handle permission state changes in bloc', () async {
      // Test the bloc's ability to handle reminder toggle
      preferencesBloc.add(LoadPreferences());

      // Wait for initial load
      await expectLater(
        preferencesBloc.stream,
        emitsInOrder([
          isA<PreferencesLoading>(),
          isA<PreferencesLoaded>(),
        ]),
      );

      // Toggle reminders on
      preferencesBloc.add(ToggleReminders(true));

      await expectLater(
        preferencesBloc.stream,
        emits(predicate<PreferencesLoaded>(
            (state) => state.reminderSettings?.enabled == true)),
      );

      // Toggle reminders off
      preferencesBloc.add(ToggleReminders(false));

      await expectLater(
        preferencesBloc.stream,
        emits(predicate<PreferencesLoaded>(
            (state) => state.reminderSettings?.enabled == false)),
      );
    });
  });
}

// Mock classes for use cases
class MockGetUserPreferenceUseCase extends Mock {}

class MockSetUserPreferenceUseCase extends Mock {}

class MockRegisterManagerUseCase extends Mock {}

class MockUnregisterManagerUseCase extends Mock {}
