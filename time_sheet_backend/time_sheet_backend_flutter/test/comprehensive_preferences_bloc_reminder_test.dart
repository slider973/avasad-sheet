import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/set_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/register_manager_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/unregister_manager_use_case.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';

import 'comprehensive_preferences_bloc_reminder_test.mocks.dart';

@GenerateMocks([
  GetUserPreferenceUseCase,
  SetUserPreferenceUseCase,
  RegisterManagerUseCase,
  UnregisterManagerUseCase,
])
void main() {
  group('PreferencesBloc - Comprehensive Reminder Tests', () {
    late PreferencesBloc preferencesBloc;
    late MockGetUserPreferenceUseCase mockGetUserPreferenceUseCase;
    late MockSetUserPreferenceUseCase mockSetUserPreferenceUseCase;
    late MockRegisterManagerUseCase mockRegisterManagerUseCase;
    late MockUnregisterManagerUseCase mockUnregisterManagerUseCase;

    setUp(() {
      mockGetUserPreferenceUseCase = MockGetUserPreferenceUseCase();
      mockSetUserPreferenceUseCase = MockSetUserPreferenceUseCase();
      mockRegisterManagerUseCase = MockRegisterManagerUseCase();
      mockUnregisterManagerUseCase = MockUnregisterManagerUseCase();

      preferencesBloc = PreferencesBloc(
        getUserPreferenceUseCase: mockGetUserPreferenceUseCase,
        setUserPreferenceUseCase: mockSetUserPreferenceUseCase,
        registerManagerUseCase: mockRegisterManagerUseCase,
        unregisterManagerUseCase: mockUnregisterManagerUseCase,
      );

      // Setup default mock behaviors
      when(mockGetUserPreferenceUseCase.execute(any))
          .thenAnswer((_) async => null);
      when(mockSetUserPreferenceUseCase.execute(any, any))
          .thenAnswer((_) async {});
    });

    tearDown(() {
      preferencesBloc.close();
    });

    group('LoadPreferences with Reminder Settings', () {
      blocTest<PreferencesBloc, PreferencesState>(
        'should load default reminder settings when none are saved',
        build: () {
          // Setup mocks for basic user data
          when(mockGetUserPreferenceUseCase.execute('firstName'))
              .thenAnswer((_) async => 'John');
          when(mockGetUserPreferenceUseCase.execute('lastName'))
              .thenAnswer((_) async => 'Doe');
          when(mockGetUserPreferenceUseCase.execute('company'))
              .thenAnswer((_) async => 'Test Company');
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async => null); // No saved settings

          return preferencesBloc;
        },
        act: (bloc) => bloc.add(LoadPreferences()),
        expect: () => [
          PreferencesLoading(),
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings,
            'reminderSettings',
            equals(ReminderSettings.defaultSettings),
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should load saved reminder settings correctly',
        build: () {
          final savedSettings = ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 9, minute: 0),
            clockOutTime: const TimeOfDay(hour: 18, minute: 0),
            activeDays: {1, 2, 3},
            respectHolidays: false,
            snoozeMinutes: 20,
            maxSnoozes: 3,
          );

          // Setup mocks
          when(mockGetUserPreferenceUseCase.execute('firstName'))
              .thenAnswer((_) async => 'John');
          when(mockGetUserPreferenceUseCase.execute('lastName'))
              .thenAnswer((_) async => 'Doe');
          when(mockGetUserPreferenceUseCase.execute('company'))
              .thenAnswer((_) async => 'Test Company');
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async => jsonEncode(savedSettings.toJson()));

          return preferencesBloc;
        },
        act: (bloc) => bloc.add(LoadPreferences()),
        expect: () => [
          PreferencesLoading(),
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings?.enabled,
            'reminderSettings.enabled',
            isTrue,
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should handle corrupted reminder settings gracefully',
        build: () {
          // Setup mocks with corrupted JSON
          when(mockGetUserPreferenceUseCase.execute('firstName'))
              .thenAnswer((_) async => 'John');
          when(mockGetUserPreferenceUseCase.execute('lastName'))
              .thenAnswer((_) async => 'Doe');
          when(mockGetUserPreferenceUseCase.execute('company'))
              .thenAnswer((_) async => 'Test Company');
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async => 'invalid_json_data');

          return preferencesBloc;
        },
        act: (bloc) => bloc.add(LoadPreferences()),
        expect: () => [
          PreferencesLoading(),
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings,
            'reminderSettings',
            equals(ReminderSettings.defaultSettings),
          ),
        ],
      );
    });

    group('SaveReminderSettings', () {
      blocTest<PreferencesBloc, PreferencesState>(
        'should save valid reminder settings successfully',
        build: () {
          // Setup initial loaded state
          when(mockGetUserPreferenceUseCase.execute('firstName'))
              .thenAnswer((_) async => 'John');
          when(mockGetUserPreferenceUseCase.execute('lastName'))
              .thenAnswer((_) async => 'Doe');
          when(mockGetUserPreferenceUseCase.execute('company'))
              .thenAnswer((_) async => 'Test Company');

          return preferencesBloc;
        },
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) {
          final newSettings = ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 9, minute: 0),
            clockOutTime: const TimeOfDay(hour: 18, minute: 0),
            activeDays: {1, 2, 3, 4, 5},
            respectHolidays: true,
            snoozeMinutes: 15,
            maxSnoozes: 2,
          );
          bloc.add(SaveReminderSettings(newSettings));
        },
        expect: () => [
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings?.enabled,
            'reminderSettings.enabled',
            isTrue,
          ),
        ],
        verify: (_) {
          verify(mockSetUserPreferenceUseCase.execute(
            'reminderSettings',
            any,
          )).called(1);
        },
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should reject invalid reminder settings',
        build: () => preferencesBloc,
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) {
          final invalidSettings = ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 10, minute: 0),
            clockOutTime:
                const TimeOfDay(hour: 8, minute: 0), // Invalid: before clock-in
            activeDays: {1, 2, 3, 4, 5},
            respectHolidays: true,
            snoozeMinutes: 15,
            maxSnoozes: 2,
          );
          bloc.add(SaveReminderSettings(invalidSettings));
        },
        expect: () => [
          isA<PreferencesError>().having(
            (state) => state.message,
            'error message',
            contains('Configuration invalide'),
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should handle save errors gracefully',
        build: () {
          when(mockSetUserPreferenceUseCase.execute('reminderSettings', any))
              .thenThrow(Exception('Save failed'));
          return preferencesBloc;
        },
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) {
          final settings = ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 8, minute: 0),
            clockOutTime: const TimeOfDay(hour: 17, minute: 0),
            activeDays: {1, 2, 3, 4, 5},
            respectHolidays: true,
            snoozeMinutes: 15,
            maxSnoozes: 2,
          );
          bloc.add(SaveReminderSettings(settings));
        },
        expect: () => [
          isA<PreferencesError>(),
        ],
      );
    });

    group('LoadReminderSettings', () {
      blocTest<PreferencesBloc, PreferencesState>(
        'should load reminder settings when preferences are already loaded',
        build: () {
          final savedSettings = ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 9, minute: 30),
            clockOutTime: const TimeOfDay(hour: 17, minute: 30),
            activeDays: {1, 3, 5},
            respectHolidays: false,
            snoozeMinutes: 10,
            maxSnoozes: 1,
          );

          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async => jsonEncode(savedSettings.toJson()));

          return preferencesBloc;
        },
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) => bloc.add(LoadReminderSettings()),
        expect: () => [
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings?.clockInTime.hour,
            'reminderSettings.clockInTime.hour',
            equals(9),
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should use default settings when no saved settings exist',
        build: () {
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async => null);
          return preferencesBloc;
        },
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: null,
        ),
        act: (bloc) => bloc.add(LoadReminderSettings()),
        expect: () => [
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings,
            'reminderSettings',
            equals(ReminderSettings.defaultSettings),
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should handle load errors gracefully',
        build: () {
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenThrow(Exception('Load failed'));
          return preferencesBloc;
        },
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) => bloc.add(LoadReminderSettings()),
        expect: () => [
          isA<PreferencesError>(),
        ],
      );
    });

    group('ToggleReminders', () {
      blocTest<PreferencesBloc, PreferencesState>(
        'should enable reminders when currently disabled',
        build: () => preferencesBloc,
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings:
              ReminderSettings.defaultSettings, // Disabled by default
        ),
        act: (bloc) => bloc.add(ToggleReminders(true)),
        expect: () => [
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings?.enabled,
            'reminderSettings.enabled',
            isTrue,
          ),
        ],
        verify: (_) {
          verify(mockSetUserPreferenceUseCase.execute(
            'reminderSettings',
            any,
          )).called(1);
        },
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should disable reminders when currently enabled',
        build: () => preferencesBloc,
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings:
              ReminderSettings.defaultSettings.copyWith(enabled: true),
        ),
        act: (bloc) => bloc.add(ToggleReminders(false)),
        expect: () => [
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings?.enabled,
            'reminderSettings.enabled',
            isFalse,
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should preserve other reminder settings when toggling',
        build: () => preferencesBloc,
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings(
            enabled: false,
            clockInTime: const TimeOfDay(hour: 9, minute: 30),
            clockOutTime: const TimeOfDay(hour: 18, minute: 15),
            activeDays: {1, 3, 5},
            respectHolidays: false,
            snoozeMinutes: 20,
            maxSnoozes: 3,
          ),
        ),
        act: (bloc) => bloc.add(ToggleReminders(true)),
        expect: () => [
          isA<PreferencesLoaded>()
              .having(
                (state) => state.reminderSettings?.enabled,
                'reminderSettings.enabled',
                isTrue,
              )
              .having(
                (state) => state.reminderSettings?.clockInTime.hour,
                'reminderSettings.clockInTime.hour',
                equals(9),
              )
              .having(
                (state) => state.reminderSettings?.activeDays,
                'reminderSettings.activeDays',
                equals({1, 3, 5}),
              ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should handle toggle errors gracefully',
        build: () {
          when(mockSetUserPreferenceUseCase.execute('reminderSettings', any))
              .thenThrow(Exception('Toggle failed'));
          return preferencesBloc;
        },
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) => bloc.add(ToggleReminders(true)),
        expect: () => [
          isA<PreferencesError>(),
        ],
      );
    });

    group('Integration with Other Preferences', () {
      blocTest<PreferencesBloc, PreferencesState>(
        'should preserve reminder settings when saving other preferences',
        build: () {
          when(mockGetUserPreferenceUseCase.execute('signature'))
              .thenAnswer((_) async => null);
          when(mockGetUserPreferenceUseCase.execute('lastGenerationDate'))
              .thenAnswer((_) async => null);
          when(mockGetUserPreferenceUseCase.execute('badgeCount'))
              .thenAnswer((_) async => '0');
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async => null);

          return preferencesBloc;
        },
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 9, minute: 0),
            clockOutTime: const TimeOfDay(hour: 18, minute: 0),
            activeDays: {1, 2, 3, 4, 5},
            respectHolidays: true,
            snoozeMinutes: 15,
            maxSnoozes: 2,
          ),
        ),
        act: (bloc) => bloc.add(SavePreferences(
          firstName: 'Jane',
          lastName: 'Smith',
          company: 'New Company',
        )),
        expect: () => [
          PreferencesSaved(),
          isA<PreferencesLoaded>()
              .having(
                (state) => state.firstName,
                'firstName',
                equals('Jane'),
              )
              .having(
                (state) => state.reminderSettings?.enabled,
                'reminderSettings.enabled',
                isTrue,
              ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should preserve reminder settings when saving user info',
        build: () {
          when(mockGetUserPreferenceUseCase.execute('notificationsEnabled'))
              .thenAnswer((_) async => 'true');
          when(mockGetUserPreferenceUseCase.execute('isDeliveryManager'))
              .thenAnswer((_) async => 'false');
          when(mockGetUserPreferenceUseCase.execute('lastGenerationDate'))
              .thenAnswer((_) async => null);
          when(mockGetUserPreferenceUseCase.execute('badgeCount'))
              .thenAnswer((_) async => '0');
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async => null);

          return preferencesBloc;
        },
        act: (bloc) {
          final customReminderSettings = ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 8, minute: 30),
            clockOutTime: const TimeOfDay(hour: 17, minute: 30),
            activeDays: {1, 3, 5},
            respectHolidays: false,
            snoozeMinutes: 10,
            maxSnoozes: 1,
          );

          bloc.add(SaveUserInfoEvent(
            firstName: 'Alice',
            lastName: 'Johnson',
            company: 'Tech Corp',
            signature: Uint8List.fromList([1, 2, 3]),
          ));
        },
        expect: () => [
          PreferencesLoading(),
          PreferencesSaved(),
          isA<PreferencesLoaded>()
              .having(
                (state) => state.firstName,
                'firstName',
                equals('Alice'),
              )
              .having(
                (state) => state.reminderSettings,
                'reminderSettings',
                equals(ReminderSettings.defaultSettings),
              ),
        ],
      );
    });

    group('State Transitions and Error Recovery', () {
      blocTest<PreferencesBloc, PreferencesState>(
        'should handle multiple rapid reminder setting changes',
        build: () => preferencesBloc,
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) {
          // Rapid changes
          bloc.add(ToggleReminders(true));
          bloc.add(ToggleReminders(false));
          bloc.add(ToggleReminders(true));
        },
        expect: () => [
          // Should handle all changes
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings?.enabled,
            'final enabled state',
            isTrue,
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should recover from error state when loading reminder settings',
        build: () {
          when(mockGetUserPreferenceUseCase.execute('reminderSettings'))
              .thenAnswer((_) async =>
                  jsonEncode(ReminderSettings.defaultSettings.toJson()));
          return preferencesBloc;
        },
        seed: () => PreferencesError('Previous error'),
        act: (bloc) => bloc.add(LoadReminderSettings()),
        expect: () => [
          // Should not emit anything since state is not PreferencesLoaded
        ],
      );
    });

    group('Requirement Validation', () {
      test(
          'should ensure reminder settings are disabled by default (requirement 1.1)',
          () {
        final defaultSettings = ReminderSettings.defaultSettings;
        expect(defaultSettings.enabled, isFalse,
            reason: 'Requirement 1.1: Reminders must be disabled by default');
      });

      blocTest<PreferencesBloc, PreferencesState>(
        'should validate reminder time configuration (requirement 2.4)',
        build: () => preferencesBloc,
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings: ReminderSettings.defaultSettings,
        ),
        act: (bloc) {
          // Try to save invalid settings (clock-out before clock-in)
          final invalidSettings = ReminderSettings(
            enabled: true,
            clockInTime: const TimeOfDay(hour: 17, minute: 0),
            clockOutTime: const TimeOfDay(hour: 8, minute: 0),
            activeDays: {1, 2, 3, 4, 5},
            respectHolidays: true,
            snoozeMinutes: 15,
            maxSnoozes: 2,
          );
          bloc.add(SaveReminderSettings(invalidSettings));
        },
        expect: () => [
          isA<PreferencesError>().having(
            (state) => state.message,
            'error message',
            contains('Clock-out time must be after clock-in time'),
          ),
        ],
      );

      blocTest<PreferencesBloc, PreferencesState>(
        'should handle reminder cancellation when disabled (requirement 2.5)',
        build: () => preferencesBloc,
        seed: () => PreferencesLoaded(
          firstName: 'John',
          lastName: 'Doe',
          company: 'Test Company',
          signature: null,
          lastGenerationDate: null,
          notificationsEnabled: true,
          isDeliveryManager: false,
          badgeCount: 0,
          versionNumber: '1.0.0',
          buildNumber: '1',
          reminderSettings:
              ReminderSettings.defaultSettings.copyWith(enabled: true),
        ),
        act: (bloc) => bloc.add(ToggleReminders(false)),
        expect: () => [
          isA<PreferencesLoaded>().having(
            (state) => state.reminderSettings?.enabled,
            'reminderSettings.enabled',
            isFalse,
          ),
        ],
        verify: (_) {
          // Verify that settings are saved when disabled
          verify(mockSetUserPreferenceUseCase.execute(
            'reminderSettings',
            any,
          )).called(1);
        },
      );
    });
  });
}
