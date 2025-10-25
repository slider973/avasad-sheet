import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'timesheet_appointment.dart';
import 'calendar_theme_config.dart';
import '../../../../../enum/absence_period.dart';

/// Custom appointment builder for different entry types with enhanced theming
class CustomAppointmentBuilder {
  const CustomAppointmentBuilder._();

  /// Builds a custom appointment widget with enhanced styling
  static Widget buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final appointment = details.appointments.first as TimesheetAppointment;
    final isSelected = details.isMoreAppointmentRegion;
    final bounds = details.bounds;

    // Determine if this is a small appointment (limited space)
    final isSmall = bounds.height < 30 || bounds.width < 80;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: CalendarThemeConfig.getAppointmentDecoration(
        appointment.color,
        isSelected: isSelected,
        isWeekend: appointment.isWeekendWork,
        isHoliday: false, // TODO: Add holiday detection
      ),
      child: _buildAppointmentContent(
        context,
        appointment,
        isSelected: isSelected,
        isSmall: isSmall,
      ),
    );
  }

  /// Builds the content inside the appointment widget
  static Widget _buildAppointmentContent(
    BuildContext context,
    TimesheetAppointment appointment, {
    required bool isSelected,
    required bool isSmall,
  }) {
    if (isSmall) {
      return _buildCompactAppointment(context, appointment, isSelected);
    } else {
      return _buildDetailedAppointment(context, appointment, isSelected);
    }
  }

  /// Builds a compact appointment for small spaces
  static Widget _buildCompactAppointment(
    BuildContext context,
    TimesheetAppointment appointment,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Type indicator icon
          _buildTypeIcon(appointment, size: 12),
          const SizedBox(width: 2),
          // Abbreviated text
          Expanded(
            child: Text(
              _getAbbreviatedSubject(appointment),
              style: CalendarThemeConfig.getAppointmentTextStyle(
                isSelected: isSelected,
                isSmall: true,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a detailed appointment for larger spaces
  static Widget _buildDetailedAppointment(
    BuildContext context,
    TimesheetAppointment appointment,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main content row
          Row(
            children: [
              // Type indicator icon
              _buildTypeIcon(appointment, size: 14),
              const SizedBox(width: 4),
              // Subject text
              Expanded(
                child: Text(
                  appointment.subject,
                  style: CalendarThemeConfig.getAppointmentTextStyle(
                    isSelected: isSelected,
                    isSmall: false,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status indicators
              ..._buildStatusIndicators(appointment),
            ],
          ),
          // Additional info if space allows
          if (appointment.notes != null && appointment.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                appointment.notes!,
                style: CalendarThemeConfig.getAppointmentTextStyle(
                  isSelected: isSelected,
                  isSmall: true,
                ).copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the type indicator icon based on appointment type
  static Widget _buildTypeIcon(TimesheetAppointment appointment,
      {required double size}) {
    IconData iconData;
    Color iconColor = Colors.white;

    if (appointment.isAbsence) {
      switch (appointment.absencePeriod) {
        case AbsencePeriod.fullDay:
          iconData = Icons.event_busy;
          break;
        case AbsencePeriod.halfDay:
          iconData = Icons.schedule;
          break;
        default:
          iconData = Icons.event_busy;
      }
    } else if (appointment.isWeekendWork) {
      iconData = Icons.weekend;
    } else if (appointment.isPartialWorkDay) {
      iconData = Icons.access_time;
    } else if (appointment.timesheetEntry.hasOvertimeHours) {
      iconData = Icons.trending_up;
    } else {
      iconData = Icons.work;
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }

  /// Builds status indicators for the appointment
  static List<Widget> _buildStatusIndicators(TimesheetAppointment appointment) {
    final indicators = <Widget>[];

    // Overtime indicator
    if (appointment.timesheetEntry.hasOvertimeHours) {
      indicators.add(
        Container(
          margin: const EdgeInsets.only(left: 2),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            '+',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Weekend indicator
    if (appointment.isWeekendWork) {
      indicators.add(
        Container(
          margin: const EdgeInsets.only(left: 2),
          child: const Icon(
            Icons.weekend,
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    }

    return indicators;
  }

  /// Gets abbreviated subject text for compact display
  static String _getAbbreviatedSubject(TimesheetAppointment appointment) {
    if (appointment.isAbsence) {
      switch (appointment.absencePeriod) {
        case AbsencePeriod.fullDay:
          return 'Abs';
        case AbsencePeriod.halfDay:
          return 'Abs½';
        default:
          return 'Abs';
      }
    }

    if (appointment.isWeekendWork) {
      return 'WE';
    }

    if (appointment.isPartialWorkDay) {
      return 'Part';
    }

    if (appointment.timesheetEntry.hasOvertimeHours) {
      return 'Trav+';
    }

    return 'Trav';
  }

  /// Builds a more appointments indicator when there are too many appointments
  static Widget buildMoreAppointmentsIndicator(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final moreAppointmentCount = details.appointments.length;

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '+$moreAppointmentCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Builds a custom month cell with weekend and holiday styling
  static Widget buildMonthCell(
    BuildContext context,
    MonthCellDetails details,
  ) {
    final isWeekend = details.date.weekday == DateTime.saturday ||
        details.date.weekday == DateTime.sunday;
    final isToday = _isSameDay(details.date, DateTime.now());
    final isCurrentMonth =
        details.date.month == details.visibleDates.first.month;

    BoxDecoration? decoration;
    TextStyle? textStyle;

    if (isWeekend && isCurrentMonth) {
      decoration = CalendarThemeConfig.getWeekendCellDecoration(context);
    }

    if (isToday) {
      decoration = BoxDecoration(
        color: CalendarThemeConfig.getTodayHighlightColor(context)
            .withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CalendarThemeConfig.getTodayHighlightColor(context),
          width: 2,
        ),
      );
      textStyle = const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
    }

    return Container(
      // Augmenter la hauteur minimale de la cellule
      constraints: const BoxConstraints(
        minHeight: 80, // Hauteur minimale augmentée de ~50 à 80
      ),
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              details.date.day.toString(),
              style: textStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isCurrentMonth
                        ? (isWeekend ? Colors.grey[600] : Colors.black87)
                        : Colors.grey[400],
                  ),
            ),
            // Espace pour les événements en dessous du numéro de jour
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  /// Checks if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
