import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/timesheet_entry.dart';
import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../pointage_widget/pointage_widget.dart';
import 'timesheet_appointment.dart';
import 'timesheet_appointment_data_source.dart';
import 'calendar_event_details_panel.dart';
import 'calendar_theme_config.dart';
import 'custom_appointment_builder.dart';
import 'calendar_loading_manager.dart';
import 'calendar_error_handler.dart';
import '../../../../../services/logger_service.dart';

/// Main Syncfusion calendar widget for displaying timesheet entries
class SyncfusionTimesheetCalendarWidget extends StatefulWidget {
  const SyncfusionTimesheetCalendarWidget({Key? key}) : super(key: key);

  @override
  State<SyncfusionTimesheetCalendarWidget> createState() =>
      _SyncfusionTimesheetCalendarWidgetState();
}

class _SyncfusionTimesheetCalendarWidgetState
    extends State<SyncfusionTimesheetCalendarWidget>
    with AutomaticKeepAliveClientMixin {
  // Calendar configuration
  late CalendarController _calendarController;
  CalendarView _calendarView = CalendarView.month;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  // Data source for appointments
  TimesheetAppointmentDataSource? _dataSource;

  // Track last tap to prevent double-tap view change
  DateTime? _lastTapTime;
  DateTime? _lastTapDate;

  // Date range configuration (1 year back, 3 months forward)
  late DateTime _minDate;
  late DateTime _maxDate;

  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCalendar();
    _loadTimesheetData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when the widget becomes visible again
    if (mounted) {
      _loadTimesheetData();
    }
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// Initialize calendar controller and date ranges
  void _initializeCalendar() {
    _calendarController = CalendarController();
    _calendarController.selectedDate = _selectedDate;
    _calendarController.displayDate = _focusedDate;

    // Configure date range: 1 year back, 3 months forward
    final now = DateTime.now();
    _minDate = DateTime(now.year - 1, now.month, now.day);
    _maxDate = DateTime(now.year, now.month + 3, now.day);
  }

  /// Load timesheet data from BLoC
  void _loadTimesheetData() {
    try {
      logger.i('Loading timesheet data for calendar');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      context.read<TimeSheetListBloc>().add(const FindTimesheetEntriesEvent());
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des données';
      });

      if (mounted) {
        CalendarErrorHandler.handleDataLoadingError(
          context,
          e,
          stackTrace,
          onRetry: _loadTimesheetData,
        );
      }
    }
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    try {
      logger.i('Refreshing calendar data via pull-to-refresh');
      _loadTimesheetData();

      // Wait for the loading to complete with timeout
      int attempts = 0;
      const maxAttempts = 50; // 5 seconds max wait time

      await Future.delayed(const Duration(milliseconds: 500));

      // If still loading, wait a bit more but with timeout
      while (_isLoading && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (attempts >= maxAttempts) {
        logger.w('Refresh timeout reached, stopping wait');
      } else {
        logger.i('Calendar refresh completed successfully');
      }
    } catch (e, stackTrace) {
      logger.e('Error during calendar refresh',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        CalendarLoadingManager.showErrorFeedback(
          context,
          message: 'Erreur lors de l\'actualisation du calendrier',
          onRetry: _loadTimesheetData,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: CalendarThemeConfig.getCalendarBackgroundDecoration(context),
      child: MultiBlocListener(
        listeners: [
          BlocListener<TimeSheetListBloc, TimeSheetListState>(
            listener: _handleTimeSheetListState,
          ),
          BlocListener<TimeSheetBloc, TimeSheetState>(
            listener: _handleTimeSheetState,
          ),
        ],
        child: Column(
          children: [
            // Custom app bar
            _buildAppBar(context),
            // Calendar widget wrapped in refresh indicator
            Expanded(
              child: CalendarLoadingManager.buildRefreshWrapper(
                context,
                onRefresh: _handleRefresh,
                child: Column(
                  children: [
                    // Calendar widget
                    Expanded(
                      child: _buildCalendar(),
                    ),
                    // Event details panel for selected date
                    if (_dataSource != null)
                      CalendarEventDetailsPanel(
                        key: ValueKey(
                            'event_details_${_selectedDate.toIso8601String()}'),
                        selectedDate: _selectedDate,
                        appointments:
                            _dataSource!.getAppointmentsForDate(_selectedDate),
                        onEventTap: _onEventTapFromPanel,
                        onAddEntry: _onAddEntryFromPanel,
                        showAddButton: true,
                        maxHeight: 250,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build custom app bar
  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
              Expanded(
                child: Text(
                  'Calendrier des pointages',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  CalendarLoadingManager.showLoadingFeedback(
                    context,
                    message: 'Actualisation du calendrier...',
                  );
                  _loadTimesheetData();
                },
                tooltip: 'Actualiser le calendrier',
              ),
              IconButton(
                icon: const Icon(Icons.today, color: Colors.white),
                onPressed: () {
                  _goToToday();
                },
                tooltip: 'Aller à aujourd\'hui',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the main Syncfusion calendar widget
  Widget _buildCalendar() {
    // Show loading indicator when loading and no data source exists
    if (_isLoading && _dataSource == null) {
      return CalendarLoadingManager.buildFullScreenLoading(
        context,
        message: 'Chargement du calendrier...',
      );
    }

    // Show error state if there's an error and no data
    if (_errorMessage != null && _dataSource == null) {
      return CalendarLoadingManager.buildErrorState(
        context,
        message: _errorMessage!,
        onRetry: _loadTimesheetData,
      );
    }

    return CalendarLoadingManager.buildLoadingOverlay(
      context,
      isLoading: _isLoading && _dataSource != null,
      child: SfCalendar(
        // Basic configuration
        view: _calendarView,
        controller: _calendarController,
        dataSource: _dataSource,
        firstDayOfWeek:
            1, // Monday as first day of week (1 = Monday, 7 = Sunday)

        // Date range configuration
        minDate: _minDate,
        maxDate: _maxDate,

        // Initial display
        initialSelectedDate: _selectedDate,
        initialDisplayDate: _focusedDate,

        // Calendar appearance with theme integration
        todayHighlightColor:
            CalendarThemeConfig.getTodayHighlightColor(context),
        selectionDecoration:
            CalendarThemeConfig.getSelectionDecoration(context),

        // Month view settings with enhanced theming
        monthViewSettings: CalendarThemeConfig.getMonthViewSettings(context),

        // Header settings with app theme
        headerStyle: CalendarThemeConfig.getHeaderStyle(context),

        // View header settings (day names) with app theme
        viewHeaderStyle: CalendarThemeConfig.getViewHeaderStyle(context),

        // Event handlers
        onTap: _onCalendarTapped,
        onSelectionChanged: _onSelectionChanged,
        onViewChanged: _onViewChanged,

        // Custom appointment builder for enhanced styling
        appointmentBuilder: CustomAppointmentBuilder.buildAppointment,

        // Custom month cell builder for weekend/holiday styling
        monthCellBuilder: CustomAppointmentBuilder.buildMonthCell,

        // Time format configuration for 24h format
        timeSlotViewSettings: const TimeSlotViewSettings(
          timeFormat: 'HH:mm',
        ),

        // Permettre la navigation de vue manuelle via le header
        allowViewNavigation: false,
        allowedViews: const [
          CalendarView.month,
          CalendarView.week,
          CalendarView.workWeek,
          CalendarView.day,
        ],

        // Enhanced calendar settings
        showNavigationArrow: true,
        showDatePickerButton: true,
        showCurrentTimeIndicator: true,

        // Today text style (moved from MonthCellStyle)
        todayTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),

        // Accessibility
        cellBorderColor: Colors.grey[300],
        backgroundColor: Colors.transparent,
      ),
    );
  }

  /// Navigate to today's date
  void _goToToday() {
    try {
      final today = DateTime.now();
      logger
          .i('Navigating to today: ${DateFormat('yyyy-MM-dd').format(today)}');

      setState(() {
        _selectedDate = today;
        _focusedDate = today;
        _calendarController.selectedDate = today;
        _calendarController.displayDate = today;
      });

      // Load data for today
      _onDateSelected(today);

      CalendarLoadingManager.showSuccessFeedback(
        context,
        message: 'Navigation vers aujourd\'hui',
      );

      logger.i('Successfully navigated to today');
    } catch (e, stackTrace) {
      logger.e('Error navigating to today', error: e, stackTrace: stackTrace);

      if (mounted) {
        CalendarLoadingManager.showErrorFeedback(
          context,
          message: 'Erreur lors de la navigation vers aujourd\'hui',
        );
      }
    }
  }

  /// Handle event tap from the event details panel
  void _onEventTapFromPanel(TimesheetEntry entry) {
    try {
      logger
          .i('Event tapped from panel: ${entry.id} for date: ${entry.dayDate}');

      // Validate entry data
      if (entry.dayDate.isEmpty) {
        throw ArgumentError('Entry dayDate is empty');
      }

      // Load the specific entry data
      final dateFormat = DateFormat('dd-MMM-yy', 'en_US');
      final formattedDate = dateFormat.format(_selectedDate);

      final timeSheetBloc = context.read<TimeSheetBloc>();
      timeSheetBloc.add(LoadTimeSheetDataEvent(formattedDate));

      logger.i('Successfully loaded timesheet data for entry: ${entry.id}');
    } catch (e, stackTrace) {
      logger.e('Error handling event tap from panel',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        CalendarLoadingManager.showErrorFeedback(
          context,
          message: 'Erreur lors du chargement des détails de l\'entrée',
        );
      }
    }
  }

  /// Handle add entry from the event details panel
  void _onAddEntryFromPanel() {
    try {
      logger.i(
          'Add entry tapped from panel for date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');

      // Validate selected date
      if (_selectedDate.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        throw ArgumentError('Cannot create entries for future dates');
      }

      // Navigate to pointage page to create a new entry
      _navigateToPointagePage(_selectedDate);

      logger.i('Successfully initiated add entry navigation');
    } catch (e, stackTrace) {
      logger.e('Error adding entry from panel',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        String errorMessage =
            'Erreur lors de la création d\'une nouvelle entrée';
        if (e is ArgumentError) {
          errorMessage = e.message;
        }

        CalendarLoadingManager.showErrorFeedback(
          context,
          message: errorMessage,
        );
      }
    }
  }

  /// Handle calendar tap events
  void _onCalendarTapped(CalendarTapDetails details) {
    try {
      logger.d(
          'Calendar tapped - target: ${details.targetElement}, date: ${details.date}');

      if (details.targetElement == CalendarElement.calendarCell) {
        // Tapped on a date cell - only update selection, no navigation
        if (details.date != null) {
          final now = DateTime.now();
          final tapDate = details.date!;

          // Detect double-tap (tap within 500ms on same date)
          final isDoubleTap = _lastTapTime != null &&
              _lastTapDate != null &&
              now.difference(_lastTapTime!).inMilliseconds < 500 &&
              _lastTapDate!.year == tapDate.year &&
              _lastTapDate!.month == tapDate.month &&
              _lastTapDate!.day == tapDate.day;

          if (isDoubleTap) {
            logger.i('Double-tap detected - preventing view change');
            // Reset tap tracking to prevent triple-tap
            _lastTapTime = null;
            _lastTapDate = null;
            return; // Ignore double-tap to prevent view change
          }

          // Track this tap
          _lastTapTime = now;
          _lastTapDate = tapDate;

          logger.i(
              'Calendar cell tapped for date: ${DateFormat('yyyy-MM-dd').format(tapDate)}');
          _onDateSelected(tapDate);
          // Navigation removed - user must use "Add" button to navigate
        } else {
          logger.w('Calendar cell tapped but date is null');
        }
      } else if (details.targetElement == CalendarElement.appointment) {
        // Tapped on an appointment - navigate to pointage details
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          final appointment = details.appointments!.first;

          if (appointment is TimesheetAppointment) {
            logger.i(
                'Appointment tapped: ${appointment.timesheetEntry.id?.toString() ?? "unknown"}');
            _onAppointmentTap(appointment);
          } else {
            logger.w(
                'Tapped appointment is not a TimesheetAppointment: ${appointment.runtimeType}');
            throw TypeError();
          }
        } else {
          logger.w('Appointment tapped but appointments list is null or empty');
        }
      } else {
        logger.d('Calendar tapped on other element: ${details.targetElement}');
      }
    } catch (e, stackTrace) {
      if (mounted) {
        CalendarErrorHandler.handleInteractionError(
          context,
          'calendar tap',
          e,
          stackTrace,
        );
      }
    }
  }

  /// Handle date selection
  void _onDateSelected(DateTime selectedDate) {
    try {
      logger
          .i('Date selected: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');

      // Only update if the date actually changed to prevent loops
      if (_selectedDate.day != selectedDate.day ||
          _selectedDate.month != selectedDate.month ||
          _selectedDate.year != selectedDate.year) {
        // Defer state changes to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedDate = selectedDate;
              _calendarController.selectedDate = selectedDate;
            });
          }
        });

        // Load data for the selected date
        final dateFormat = DateFormat('dd-MMM-yy', 'en_US');
        final formattedDate = dateFormat.format(selectedDate);

        logger.d('Formatted date for BLoC: $formattedDate');

        final timeSheetBloc = context.read<TimeSheetBloc>();
        timeSheetBloc.add(LoadTimeSheetDataEvent(formattedDate));

        logger.i('Successfully loaded data for selected date');
      }
    } catch (e, stackTrace) {
      logger.e('Error loading data for selected date',
          error: e, stackTrace: stackTrace);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Erreur lors du chargement des données pour cette date';
          });
        }
      });

      if (mounted) {
        CalendarErrorHandler.handleDataLoadingError(
          context,
          e,
          stackTrace,
          onRetry: _loadTimesheetData,
          customMessage:
              'Erreur lors du chargement des données pour la date sélectionnée',
        );
      }
    }
  }

  /// Handle selection changes
  void _onSelectionChanged(CalendarSelectionDetails details) {
    try {
      logger.d('Selection changed: ${details.date}');

      if (details.date != null) {
        _onDateSelected(details.date!);
      } else {
        logger.w('Selection changed but date is null');
      }
    } catch (e, stackTrace) {
      logger.e('Error handling selection change',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        CalendarErrorHandler.handleInteractionError(
          context,
          'date selection',
          e,
          stackTrace,
        );
      }
    }
  }

  /// Handle view changes
  void _onViewChanged(ViewChangedDetails details) {
    try {
      logger.d('View changed - visible dates: ${details.visibleDates.length}');

      if (details.visibleDates.isNotEmpty) {
        final newFocusedDate = details.visibleDates.first;
        final visibleMonth = newFocusedDate.month;
        final visibleYear = newFocusedDate.year;
        final currentMonth = _focusedDate.month;
        final currentYear = _focusedDate.year;

        logger.i(
            'View changed to: ${DateFormat('yyyy-MM').format(newFocusedDate)}');

        // Use post frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _focusedDate = newFocusedDate;
            });
          }
        });

        // Refresh data when navigating to a new month/week
        // This ensures we have the latest data for the visible period
        if (visibleMonth != currentMonth || visibleYear != currentYear) {
          logger
              .i('Loading data for new month/year: $visibleYear-$visibleMonth');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadTimesheetData();
            }
          });
        }
      } else {
        logger.w('View changed but no visible dates available');
      }
    } catch (e, stackTrace) {
      logger.e('Error handling view change', error: e, stackTrace: stackTrace);

      // Use post frame callback to avoid showing feedback during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          CalendarLoadingManager.showErrorFeedback(
            context,
            message: 'Erreur lors du changement de vue du calendrier',
          );
        }
      });
    }
  }

  /// Navigate to pointage page for a specific date
  void _navigateToPointagePage(DateTime selectedDate) {
    try {
      logger.i(
          'Navigating to pointage page for date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');

      // Validate navigation context
      if (!mounted) {
        logger.w('Widget not mounted, cancelling navigation');
        return;
      }

      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                  'Pointage du ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            backgroundColor: Colors.teal[50],
            body: PointageWidget(
              entry: null, // No specific entry, will load data for the date
              selectedDate: selectedDate,
            ),
          ),
        ),
      )
          .then((_) {
        // Refresh calendar data when returning from pointage page
        logger.i('Returned from pointage page, refreshing calendar data');
        if (mounted) {
          _loadTimesheetData();
        }
      }).catchError((error, stackTrace) {
        logger.e('Navigation error from pointage page',
            error: error, stackTrace: stackTrace);

        if (mounted) {
          CalendarErrorHandler.handleNavigationError(
            context,
            'page de pointage',
            error,
            stackTrace,
          );
        }
      });

      logger.i('Successfully initiated navigation to pointage page');
    } catch (e, stackTrace) {
      logger.e('Error navigating to pointage page',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        CalendarErrorHandler.handleNavigationError(
          context,
          'page de pointage',
          e,
          stackTrace,
        );
      }
    }
  }

  /// Handle appointment tap - navigate to pointage details for specific entry
  void _onAppointmentTap(TimesheetAppointment appointment) {
    try {
      logger.i(
          'Appointment tapped - entry ID: ${appointment.timesheetEntry.id}, date: ${appointment.timesheetEntry.dayDate}');

      // Validate appointment data
      if (appointment.timesheetEntry.dayDate.isEmpty) {
        throw ArgumentError('Appointment dayDate is empty');
      }

      final dateFormat = DateFormat('dd-MMM-yy', 'en_US');
      DateTime selectedDate;

      try {
        selectedDate = dateFormat.parse(appointment.timesheetEntry.dayDate);
        logger.d(
            'Parsed appointment date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
      } catch (parseError) {
        logger.e(
            'Failed to parse appointment date: ${appointment.timesheetEntry.dayDate}',
            error: parseError);
        throw FormatException(
            'Invalid date format: ${appointment.timesheetEntry.dayDate}');
      }

      // Validate navigation context
      if (!mounted) {
        logger.w('Widget not mounted, cancelling appointment navigation');
        return;
      }

      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                  'Détails du ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            backgroundColor: Colors.teal[50],
            body: PointageWidget(
              entry: appointment.timesheetEntry,
              selectedDate: selectedDate,
            ),
          ),
        ),
      )
          .then((_) {
        // Refresh data when returning from pointage details
        logger.i('Returned from pointage details, refreshing calendar data');
        if (mounted) {
          _loadTimesheetData();
        }
      }).catchError((error, stackTrace) {
        logger.e('Navigation error from pointage details',
            error: error, stackTrace: stackTrace);

        if (mounted) {
          CalendarErrorHandler.handleNavigationError(
            context,
            'détails du pointage',
            error,
            stackTrace,
          );
        }
      });

      logger.i('Successfully initiated navigation to pointage details');
    } catch (e, stackTrace) {
      logger.e('Error navigating to pointage details',
          error: e, stackTrace: stackTrace);

      if (mounted) {
        if (e is ArgumentError || e is FormatException) {
          CalendarErrorHandler.handleAppointmentError(
            context,
            appointment.timesheetEntry.id?.toString() ?? "unknown",
            e,
            stackTrace,
          );
        } else {
          CalendarErrorHandler.handleNavigationError(
            context,
            'détails du pointage',
            e,
            stackTrace,
          );
        }
      }
    }
  }

  /// Handle TimeSheetListBloc state changes
  void _handleTimeSheetListState(
    BuildContext context,
    TimeSheetListState state,
  ) {
    try {
      logger.d('Handling TimeSheetListBloc state: ${state.runtimeType}');

      if (state is TimeSheetListFetchedState) {
        logger.i(
            'TimeSheetList fetched successfully with ${state.entries.length} entries');

        try {
          final dataSource =
              TimesheetAppointmentDataSource.fromTimesheetEntries(
            state.entries,
          );

          // Use post frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _dataSource = dataSource;
                _isLoading = false;
                _errorMessage = null;
              });
            }
          });

          // Show success message if data was refreshed (only once)
          if (dataSource.appointments!.isNotEmpty) {
            logger.i(
                'Calendar updated with ${dataSource.appointments!.length} appointments');
          } else {
            logger.i('Calendar updated but no appointments to display');
          }
        } catch (dataSourceError, stackTrace) {
          logger.e('Error creating data source from entries',
              error: dataSourceError, stackTrace: stackTrace);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Erreur lors du traitement des données du calendrier';
              });
            }
          });

          CalendarErrorHandler.handleDataLoadingError(
            context,
            dataSourceError,
            stackTrace,
            onRetry: _loadTimesheetData,
            customMessage:
                'Erreur lors du traitement des données du calendrier',
          );
        }
      } else if (state is TimeSheetListInitial) {
        logger.d('TimeSheetList in initial state, setting loading');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          }
        });
      } else {
        // Handle any other states
        logger.w('Unhandled TimeSheetListBloc state: ${state.runtimeType}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'État inattendu du calendrier';
            });
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('Error handling TimeSheetListBloc state',
          error: e, stackTrace: stackTrace);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Erreur lors du traitement de l\'état du calendrier';
          });
        }
      });

      if (mounted) {
        CalendarErrorHandler.handleBlocStateError(
          context,
          'TimeSheetListBloc',
          'StateHandlingError',
          e,
          stackTrace,
          onRetry: _loadTimesheetData,
        );
      }
    }
  }

  /// Handle TimeSheetBloc state changes
  void _handleTimeSheetState(
    BuildContext context,
    TimeSheetState state,
  ) {
    try {
      logger.d('Handling TimeSheetBloc state: ${state.runtimeType}');

      if (state is TimeSheetDataState) {
        // Entry was created or modified, reload calendar data
        logger.i('TimeSheet data state received, reloading calendar data');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadTimesheetData();
          }
        });
      } else if (state is TimeSheetGenerationCompleted) {
        // PDF generation completed, reload calendar data
        logger.i('TimeSheet PDF generation completed');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadTimesheetData();
          }
        });
        CalendarLoadingManager.showSuccessFeedback(
          context,
          message: 'Feuille de temps générée avec succès',
        );
      } else if (state is TimeSheetAbsenceSignalee) {
        // Absence was signaled, reload calendar data
        logger.i('TimeSheet absence signaled: ${state.absenceReason}');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _loadTimesheetData();
          }
        });
        CalendarLoadingManager.showWarningFeedback(
          context,
          message: 'Absence signalée: ${state.absenceReason}',
        );
      } else if (state is TimeSheetErrorState) {
        // Handle error states
        logger.e('TimeSheet error state: ${state.message}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });
          }
        });

        CalendarErrorHandler.handleBlocStateError(
          context,
          'TimeSheetBloc',
          'TimeSheetErrorState',
          state.message,
          null,
          onRetry: _loadTimesheetData,
        );
      } else if (state is TimeSheetLoading) {
        // Handle loading states
        logger.d('TimeSheet loading state');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          }
        });
      } else {
        // Handle other states
        logger.d('Unhandled TimeSheetBloc state: ${state.runtimeType}');
      }
    } catch (e, stackTrace) {
      logger.e('Error handling TimeSheetBloc state',
          error: e, stackTrace: stackTrace);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Erreur lors du traitement de l\'état TimeSheet';
          });
        }
      });

      if (mounted) {
        CalendarErrorHandler.handleBlocStateError(
          context,
          'TimeSheetBloc',
          'StateHandlingError',
          e,
          stackTrace,
          onRetry: _loadTimesheetData,
        );
      }
    }
  }
}
