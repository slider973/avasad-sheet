import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/features/pointage/presentation/widgets/syncfusion_calendar/calendar_theme_config.dart';
import '../lib/features/pointage/presentation/widgets/syncfusion_calendar/custom_appointment_builder.dart';
import '../lib/features/pointage/presentation/widgets/syncfusion_calendar/calendar_loading_manager.dart';
import '../lib/config/theme.dart';

void main() {
  group('Calendar Theming Tests', () {
    testWidgets('CalendarThemeConfig provides consistent theming',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test header style
              final headerStyle = CalendarThemeConfig.getHeaderStyle(context);
              expect(headerStyle.textStyle?.color, TimeSheetTheme.primary);
              expect(headerStyle.textStyle?.fontWeight, FontWeight.bold);

              // Test view header style
              final viewHeaderStyle =
                  CalendarThemeConfig.getViewHeaderStyle(context);
              expect(
                  viewHeaderStyle.dayTextStyle?.color, TimeSheetTheme.primary);
              expect(viewHeaderStyle.dayTextStyle?.fontWeight, FontWeight.w600);

              // Test selection decoration
              final selectionDecoration =
                  CalendarThemeConfig.getSelectionDecoration(context);
              expect(selectionDecoration.border, isA<Border>());

              // Test today highlight color
              final todayColor =
                  CalendarThemeConfig.getTodayHighlightColor(context);
              expect(todayColor, TimeSheetTheme.secondary);

              return const Scaffold(
                body: Center(child: Text('Theme Test')),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
    });

    testWidgets('CalendarLoadingManager creates proper loading widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test loading indicator
              final loadingWidget =
                  CalendarLoadingManager.buildFullScreenLoading(
                context,
                message: 'Test loading...',
              );
              expect(loadingWidget, isA<Widget>());

              // Test error widget
              final errorWidget = CalendarLoadingManager.buildErrorState(
                context,
                message: 'Test error',
                onRetry: () {},
              );
              expect(errorWidget, isA<Widget>());

              return const Scaffold(
                body: Center(child: Text('Loading Test')),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
    });

    test('CalendarColorScheme provides correct colors', () {
      // Test work day color matches theme
      expect(CalendarColorScheme.workDayColor, TimeSheetTheme.green);

      // Test weekend work color matches theme
      expect(CalendarColorScheme.weekendWorkColor, TimeSheetTheme.secondary);

      // Test overtime work color matches theme
      expect(CalendarColorScheme.overtimeWorkColor, TimeSheetTheme.tertiary);

      // Test today color matches theme
      expect(CalendarColorScheme.todayColor, TimeSheetTheme.primary);

      // Test selected date color matches theme
      expect(CalendarColorScheme.selectedDateColor, TimeSheetTheme.primaryDark);
    });

    test('CalendarColorScheme utility methods work correctly', () {
      const testColor = Colors.blue;

      // Test light color generation
      final lightColor = CalendarColorScheme.getLightColor(testColor);
      expect(lightColor.a, closeTo(0.3, 0.01));

      // Test dark color generation
      final darkColor = CalendarColorScheme.getDarkColor(testColor);
      expect(darkColor, isA<Color>());
      expect(darkColor.red, lessThan(testColor.red));
    });

    testWidgets('Loading feedback methods work correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Test success feedback
                    CalendarLoadingManager.showSuccessFeedback(
                      context,
                      message: 'Success test',
                    );
                  },
                  child: const Text('Test Success'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger success feedback
      await tester.tap(find.text('Test Success'));
      await tester.pumpAndSettle();

      // Verify snackbar appears
      expect(find.text('Success test'), findsOneWidget);
    });

    testWidgets('Error feedback with retry works correctly',
        (WidgetTester tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Test error feedback with retry
                    CalendarLoadingManager.showErrorFeedback(
                      context,
                      message: 'Error test',
                      onRetry: () {
                        retryPressed = true;
                      },
                    );
                  },
                  child: const Text('Test Error'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to trigger error feedback
      await tester.tap(find.text('Test Error'));
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('Error test'), findsOneWidget);

      // Verify retry button appears and works
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(retryPressed, true);
    });

    test('Appointment color selection works correctly', () {
      // Test work day color
      final workColor = CalendarColorScheme.getAppointmentColor(
        isAbsence: false,
        isWeekend: false,
        isPartial: false,
        hasOvertime: false,
      );
      expect(workColor, CalendarColorScheme.workDayColor);

      // Test weekend work color
      final weekendColor = CalendarColorScheme.getAppointmentColor(
        isAbsence: false,
        isWeekend: true,
        isPartial: false,
        hasOvertime: false,
      );
      expect(weekendColor, CalendarColorScheme.weekendWorkColor);

      // Test overtime color
      final overtimeColor = CalendarColorScheme.getAppointmentColor(
        isAbsence: false,
        isWeekend: false,
        isPartial: false,
        hasOvertime: true,
      );
      expect(overtimeColor, CalendarColorScheme.overtimeWorkColor);

      // Test partial work color
      final partialColor = CalendarColorScheme.getAppointmentColor(
        isAbsence: false,
        isWeekend: false,
        isPartial: true,
        hasOvertime: false,
      );
      expect(partialColor, CalendarColorScheme.partialWorkColor);
    });
  });
}
