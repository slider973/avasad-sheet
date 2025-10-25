import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../../../config/theme.dart';
import '../../../../../enum/absence_period.dart';

/// Comprehensive theme configuration for the Syncfusion calendar
class CalendarThemeConfig {
  const CalendarThemeConfig._();

  /// Gets the calendar header style matching the app theme
  static CalendarHeaderStyle getHeaderStyle(BuildContext context) {
    return CalendarHeaderStyle(
      textAlign: TextAlign.center,
      backgroundColor: TimeSheetTheme.white,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: TimeSheetTheme.primary,
        letterSpacing: 0.8,
      ),
    );
  }

  /// Gets the view header style (day names) matching the app theme
  static ViewHeaderStyle getViewHeaderStyle(BuildContext context) {
    return ViewHeaderStyle(
      backgroundColor: TimeSheetTheme.primary,
      dayTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: TimeSheetTheme.white,
        letterSpacing: 1.2,
      ),
      dateTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: TimeSheetTheme.white,
      ),
    );
  }

  /// Gets the month view settings with custom styling
  static MonthViewSettings getMonthViewSettings(BuildContext context) {
    return const MonthViewSettings(
      appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
      showAgenda: false,
      appointmentDisplayCount: 6, // Augmenté de 4 à 6 pour voir plus d'événements
      dayFormat: 'EEE',
      showTrailingAndLeadingDates: true,
    );
  }

  /// Gets the month cell style with weekend and holiday styling
  static MonthCellStyle getMonthCellStyle(BuildContext context) {
    return MonthCellStyle(
      // Regular dates
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: TimeSheetTheme.dark,
      ),
      // Today's date - moved to SfCalendar class
      // Weekend dates
      trailingDatesTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: TimeSheetTheme.grey.withValues(alpha: 0.6),
      ),
      // Leading dates (previous month)
      leadingDatesTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: TimeSheetTheme.grey.withValues(alpha: 0.6),
      ),
      // Background color for cells
      backgroundColor: TimeSheetTheme.white,
    );
  }

  /// Gets the agenda style for agenda view
  static AgendaStyle getAgendaStyle(BuildContext context) {
    return AgendaStyle(
      backgroundColor: TimeSheetTheme.white,
      appointmentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: TimeSheetTheme.dark,
      ),
      dayTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: TimeSheetTheme.primary,
      ),
      dateTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: TimeSheetTheme.primary,
      ),
    );
  }

  /// Gets the selection decoration for selected dates
  static BoxDecoration getSelectionDecoration(BuildContext context) {
    return BoxDecoration(
      color: TimeSheetTheme.primary.withValues(alpha: 0.2),
      border: Border.all(
        color: TimeSheetTheme.primary,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(6),
    );
  }

  /// Gets the today highlight color
  static Color getTodayHighlightColor(BuildContext context) {
    return TimeSheetTheme.secondary;
  }

  /// Gets weekend cell decoration
  static BoxDecoration getWeekendCellDecoration(BuildContext context) {
    return BoxDecoration(
      color: TimeSheetTheme.grey.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Gets holiday cell decoration
  static BoxDecoration getHolidayCellDecoration(BuildContext context) {
    return BoxDecoration(
      color: TimeSheetTheme.tertiary.withValues(alpha: 0.2),
      border: Border.all(
        color: TimeSheetTheme.tertiary,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(4),
    );
  }

  /// Gets the loading indicator theme
  static Widget getLoadingIndicator(BuildContext context, {String? message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TimeSheetTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: TimeSheetTheme.dark.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(TimeSheetTheme.primary),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: TimeSheetTheme.dark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Gets the error state widget theme
  static Widget getErrorWidget(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: TimeSheetTheme.dark,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TimeSheetTheme.primary,
                foregroundColor: TimeSheetTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Gets the refresh indicator theme
  static Widget getRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TimeSheetTheme.primary,
      backgroundColor: TimeSheetTheme.white,
      strokeWidth: 3,
      displacement: 40,
      child: child,
    );
  }

  /// Gets the loading overlay for data refresh
  static Widget getLoadingOverlay(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TimeSheetTheme.primary.withValues(alpha: 0.3),
              TimeSheetTheme.primary,
              TimeSheetTheme.primary.withValues(alpha: 0.3),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: const LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
        ),
      ),
    );
  }

  /// Gets custom appointment decoration based on appointment type
  static BoxDecoration getAppointmentDecoration(
    Color appointmentColor, {
    bool isSelected = false,
    bool isWeekend = false,
    bool isHoliday = false,
  }) {
    Color borderColor = CalendarColorScheme.getDarkColor(appointmentColor);
    double borderWidth = 1;

    if (isSelected) {
      borderColor = TimeSheetTheme.primary;
      borderWidth = 2;
    }

    if (isWeekend) {
      borderColor = TimeSheetTheme.grey;
    }

    if (isHoliday) {
      borderColor = TimeSheetTheme.tertiary;
    }

    return BoxDecoration(
      color: appointmentColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: appointmentColor.withValues(alpha: 0.3),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Gets text style for appointment text
  static TextStyle getAppointmentTextStyle({
    bool isSelected = false,
    bool isSmall = false,
  }) {
    return TextStyle(
      color: TimeSheetTheme.white,
      fontSize: isSmall ? 10 : 12,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      shadows: [
        Shadow(
          color: TimeSheetTheme.dark.withValues(alpha: 0.5),
          blurRadius: 1,
          offset: const Offset(0, 0.5),
        ),
      ],
    );
  }

  /// Gets the calendar background gradient
  static BoxDecoration getCalendarBackgroundDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TimeSheetTheme.white,
          TimeSheetTheme.primary.withValues(alpha: 0.02),
        ],
      ),
    );
  }

  /// Gets the app bar theme for calendar
  static AppBarTheme getCalendarAppBarTheme(BuildContext context) {
    return AppBarTheme(
      backgroundColor: TimeSheetTheme.primary,
      foregroundColor: TimeSheetTheme.white,
      elevation: 2,
      shadowColor: TimeSheetTheme.dark.withValues(alpha: 0.2),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: TimeSheetTheme.white,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(
        color: TimeSheetTheme.white,
        size: 24,
      ),
    );
  }
}

/// Extended color scheme with additional calendar-specific colors
class CalendarColorScheme {
  /// Color for regular work days
  static const Color workDayColor = TimeSheetTheme.green;

  /// Color for full day absences
  static const Color fullDayAbsenceColor = Color(0xFFF44336); // Red

  /// Color for half day absences
  static const Color halfDayAbsenceColor = Color(0xFFFF9800); // Orange

  /// Color for partial work days (morning or afternoon only)
  static const Color partialWorkColor = Color(0xFF2196F3); // Blue

  /// Color for weekend work
  static const Color weekendWorkColor = TimeSheetTheme.secondary;

  /// Color for overtime work
  static const Color overtimeWorkColor = TimeSheetTheme.tertiary;

  /// Color for weekends (non-working days)
  static const Color weekendColor = TimeSheetTheme.grey;

  /// Color for holidays
  static const Color holidayColor = Color(0xFFFFEB3B); // Yellow

  /// Color for today's date highlight
  static const Color todayColor = TimeSheetTheme.primary;

  /// Color for selected date
  static const Color selectedDateColor = TimeSheetTheme.primaryDark;

  /// Gets a lighter version of the given color for backgrounds
  static Color getLightColor(Color color) {
    return color.withValues(alpha: 0.3);
  }

  /// Gets a darker version of the given color for borders
  static Color getDarkColor(Color color) {
    return Color.fromRGBO(
      ((color.r * 255.0).round() * 0.8).round(),
      ((color.g * 255.0).round() * 0.8).round(),
      ((color.b * 255.0).round() * 0.8).round(),
      1.0,
    );
  }

  /// Gets color based on appointment type with theme integration
  static Color getAppointmentColor({
    required bool isAbsence,
    required bool isWeekend,
    required bool isPartial,
    required bool hasOvertime,
    AbsencePeriod? absencePeriod,
  }) {
    if (isAbsence) {
      switch (absencePeriod) {
        case AbsencePeriod.fullDay:
          return fullDayAbsenceColor;
        case AbsencePeriod.halfDay:
          return halfDayAbsenceColor;
        default:
          return fullDayAbsenceColor;
      }
    }

    if (isWeekend) {
      return weekendWorkColor;
    }

    if (hasOvertime) {
      return overtimeWorkColor;
    }

    if (isPartial) {
      return partialWorkColor;
    }

    return workDayColor;
  }
}
