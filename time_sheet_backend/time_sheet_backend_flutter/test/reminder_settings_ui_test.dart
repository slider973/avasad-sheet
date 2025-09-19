import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/preference/presentation/widgets/reminder_settings_form.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';

void main() {
  group('ReminderSettingsForm', () {
    testWidgets('should display time settings and day selection',
        (tester) async {
      // Arrange
      final reminderSettings =
          ReminderSettings.defaultSettings.copyWith(enabled: true);
      bool settingsChanged = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderSettingsForm(
              reminderSettings: reminderSettings,
              onSettingsChanged: (settings) {
                settingsChanged = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Horaires de rappel'), findsOneWidget);
      expect(find.text('Heure de pointage d\'entrée'), findsOneWidget);
      expect(find.text('Heure de pointage de sortie'), findsOneWidget);
      expect(find.text('Jours actifs'), findsOneWidget);
      expect(find.text('Paramètres avancés'), findsOneWidget);

      // Check day chips
      expect(find.text('Lun'), findsOneWidget);
      expect(find.text('Mar'), findsOneWidget);
      expect(find.text('Mer'), findsOneWidget);
      expect(find.text('Jeu'), findsOneWidget);
      expect(find.text('Ven'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Dim'), findsOneWidget);
    });

    testWidgets(
        'should show time validation error when clock-out is before clock-in',
        (tester) async {
      // Arrange
      final reminderSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 17, minute: 0), // 5 PM
        clockOutTime: const TimeOfDay(hour: 8, minute: 0), // 8 AM (invalid)
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderSettingsForm(
              reminderSettings: reminderSettings,
              onSettingsChanged: (settings) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('L\'heure de sortie doit être après l\'heure d\'entrée'),
          findsOneWidget);
    });

    testWidgets('should update settings when day chip is tapped',
        (tester) async {
      // Arrange
      final reminderSettings =
          ReminderSettings.defaultSettings.copyWith(enabled: true);
      ReminderSettings? updatedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderSettingsForm(
              reminderSettings: reminderSettings,
              onSettingsChanged: (settings) {
                updatedSettings = settings;
              },
            ),
          ),
        ),
      );

      // Act - tap Saturday chip to add it
      await tester.tap(find.text('Sam'));
      await tester.pump();

      // Assert
      expect(updatedSettings, isNotNull);
      expect(
          updatedSettings!.activeDays.contains(6), isTrue); // Saturday is day 6
    });

    testWidgets('should display correct time format', (tester) async {
      // Arrange
      final reminderSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 30),
        clockOutTime: const TimeOfDay(hour: 17, minute: 15),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderSettingsForm(
              reminderSettings: reminderSettings,
              onSettingsChanged: (settings) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('17:15'), findsOneWidget);
    });

    testWidgets('should show advanced settings with correct values',
        (tester) async {
      // Arrange
      final reminderSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: false,
        snoozeMinutes: 30,
        maxSnoozes: 1,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReminderSettingsForm(
              reminderSettings: reminderSettings,
              onSettingsChanged: (settings) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Respecter les jours fériés'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('1 reports par rappel'), findsOneWidget);
    });
  });
}
