import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/timesheet_entry.dart';
import 'timesheet_appointment.dart';
import '../pointage_widget/pointage_widget.dart';
import 'calendar_error_handler.dart';
import '../../../../../services/logger_service.dart';

/// A dedicated panel widget for displaying calendar event details for a selected date
class CalendarEventDetailsPanel extends StatelessWidget {
  /// The currently selected date
  final DateTime selectedDate;

  /// List of appointments for the selected date
  final List<TimesheetAppointment> appointments;

  /// Callback function when an individual event is tapped
  final Function(TimesheetEntry) onEventTap;

  /// Callback function when the "Add Entry" button is tapped
  final VoidCallback? onAddEntry;

  /// Whether to show the add entry button
  final bool showAddButton;

  /// Maximum height constraint for the panel
  final double? maxHeight;

  const CalendarEventDetailsPanel({
    required this.selectedDate,
    required this.appointments,
    required this.onEventTap,
    this.onAddEntry,
    this.showAddButton = true,
    this.maxHeight = 200,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? 200,
        minHeight: 80,
      ),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: appointments.isEmpty
                  ? _buildEmptyState(context)
                  : _buildEventsList(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the panel header with date and optional add button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.08),
            Theme.of(context).primaryColor.withValues(alpha: 0.03),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _buildHeaderTitle(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.9),
                  ),
            ),
          ),
          if (showAddButton && onAddEntry != null) ...[
            const SizedBox(width: 8),
            _buildAddButton(context),
          ],
        ],
      ),
    );
  }

  /// Builds the header title with date and appointment count
  String _buildHeaderTitle() {
    // Use a simple date format to avoid locale issues
    final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
    final count = appointments.length;

    if (count == 0) {
      return formattedDate;
    } else if (count == 1) {
      return '$formattedDate (1 événement)';
    } else {
      return '$formattedDate ($count événements)';
    }
  }

  /// Builds the add entry button
  Widget _buildAddButton(BuildContext context) {
    return Material(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onAddEntry,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Ajouter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the empty state when no events exist for the selected date
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun événement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aucune entrée de pointage pour cette date',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            if (showAddButton && onAddEntry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onAddEntry,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Créer une entrée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the list of events for the selected date
  Widget _buildEventsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildEventTile(context, appointment);
      },
    );
  }

  /// Builds an individual event tile
  Widget _buildEventTile(
      BuildContext context, TimesheetAppointment appointment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: appointment.color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appointment.color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleEventTap(context, appointment),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildEventIndicator(appointment),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEventContent(context, appointment),
                ),
                _buildEventTrailing(context, appointment),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the colored indicator for the event type
  Widget _buildEventIndicator(TimesheetAppointment appointment) {
    return Container(
      width: 6,
      height: 45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            appointment.color,
            appointment.color.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: appointment.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  /// Builds the main content of the event tile
  Widget _buildEventContent(
      BuildContext context, TimesheetAppointment appointment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appointment.subject,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            appointment.notes!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        _buildEventMetadata(context, appointment),
      ],
    );
  }

  /// Builds metadata information for the event
  Widget _buildEventMetadata(
      BuildContext context, TimesheetAppointment appointment) {
    final metadata = <Widget>[];

    // Add work duration for work appointments
    if (!appointment.isAbsence) {
      final duration = appointment.timesheetEntry.calculateDailyTotal();
      if (duration.inMinutes > 0) {
        metadata.add(_buildMetadataChip(
          context,
          Icons.schedule,
          _formatDuration(duration),
          Colors.blue,
        ));
      }
    }

    // Add absence period for absence appointments
    if (appointment.isAbsence && appointment.absencePeriod != null) {
      metadata.add(_buildMetadataChip(
        context,
        Icons.event_busy,
        appointment.absencePeriod!.value,
        Colors.orange,
      ));
    }

    // Add weekend indicator
    if (appointment.isWeekendWork) {
      metadata.add(_buildMetadataChip(
        context,
        Icons.weekend,
        'Week-end',
        Colors.purple,
      ));
    }

    // Add overtime indicator
    if (!appointment.isAbsence && appointment.timesheetEntry.hasOvertimeHours) {
      metadata.add(_buildMetadataChip(
        context,
        Icons.trending_up,
        'Heures sup.',
        Colors.cyan,
      ));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: metadata,
    );
  }

  /// Builds a small metadata chip
  Widget _buildMetadataChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the trailing widget for the event tile
  Widget _buildEventTrailing(
      BuildContext context, TimesheetAppointment appointment) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (appointment.isAbsence)
          Icon(
            Icons.event_busy,
            color: appointment.color,
            size: 20,
          )
        else
          Icon(
            Icons.work,
            color: appointment.color,
            size: 20,
          ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
          size: 20,
        ),
      ],
    );
  }

  /// Handles event tap and navigates to the appropriate page
  void _handleEventTap(BuildContext context, TimesheetAppointment appointment) {
    try {
      logger
          .i('Event tapped in details panel: ${appointment.timesheetEntry.id}');

      // Validate appointment data
      if (appointment.timesheetEntry.dayDate.isEmpty) {
        throw ArgumentError('Appointment entry has empty dayDate');
      }

      // Call the provided callback
      onEventTap(appointment.timesheetEntry);

      // Navigate to pointage details page
      _navigateToPointageDetails(context, appointment);

      logger.i(
          'Successfully handled event tap for entry ${appointment.timesheetEntry.id}');
    } catch (e, stackTrace) {
      logger.e('Error handling event tap in details panel',
          error: e, stackTrace: stackTrace);

      // Use centralized error handling
      if (context.mounted) {
        if (e is ArgumentError) {
          CalendarErrorHandler.handleAppointmentError(
            context,
            appointment.timesheetEntry.id?.toString() ?? "unknown",
            e,
            stackTrace,
            onRetry: () => _handleEventTap(context, appointment),
          );
        } else {
          CalendarErrorHandler.handleInteractionError(
            context,
            'event tap in details panel',
            e,
            stackTrace,
            onRetry: () => _handleEventTap(context, appointment),
          );
        }
      }
    }
  }

  /// Navigates to the pointage details page for the specific entry
  void _navigateToPointageDetails(
    BuildContext context,
    TimesheetAppointment appointment,
  ) {
    try {
      logger.i(
          'Navigating to pointage details for entry ${appointment.timesheetEntry.id}');

      final entry = appointment.timesheetEntry;

      // Validate context and navigation
      if (!context.mounted) {
        logger.w('Context not mounted, cancelling navigation');
        return;
      }

      final navigator = Navigator.of(context);
      if (navigator == null) {
        throw StateError('Navigator not available');
      }

      navigator
          .push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                'Détails du ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
              ),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            backgroundColor: Colors.teal[50],
            body: PointageWidget(
              entry: entry,
              selectedDate: selectedDate,
            ),
          ),
        ),
      )
          .then((_) {
        logger.i('Returned from pointage details navigation');
      }).catchError((error, stackTrace) {
        logger.e('Navigation error from pointage details',
            error: error, stackTrace: stackTrace);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Erreur lors du retour de la navigation'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      logger.i('Successfully initiated navigation to pointage details');
    } catch (e, stackTrace) {
      logger.e('Error navigating to pointage details',
          error: e, stackTrace: stackTrace);

      if (context.mounted) {
        CalendarErrorHandler.handleNavigationError(
          context,
          'détails du pointage depuis le panel',
          e,
          stackTrace,
          onRetry: () => _navigateToPointageDetails(context, appointment),
        );
      }
    }
  }

  /// Formats a duration to a human-readable string
  String _formatDuration(Duration duration) {
    try {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);

      if (hours > 0 && minutes > 0) {
        return '${hours}h${minutes.toString().padLeft(2, '0')}';
      } else if (hours > 0) {
        return '${hours}h';
      } else if (minutes > 0) {
        return '${minutes}min';
      } else {
        return '0min';
      }
    } catch (e, stackTrace) {
      logger.e('Error formatting duration', error: e, stackTrace: stackTrace);
      return 'N/A';
    }
  }
}
