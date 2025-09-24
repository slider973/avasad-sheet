# Design Document

## Overview

This design outlines the migration from `table_calendar` to `syncfusion_flutter_calendar` for the timesheet calendar component. The migration will leverage Syncfusion's advanced calendar features while maintaining backward compatibility with existing functionality. The design focuses on creating a seamless transition that improves user experience without disrupting current workflows.

The new implementation will use Syncfusion's `SfCalendar` widget with custom appointment data sources to represent timesheet entries, absences, and work periods. The design maintains the existing BLoC integration pattern and preserves all current user interactions.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│  SyncfusionTimesheetCalendarWidget                         │
│  ├── SfCalendar (Syncfusion)                              │
│  ├── TimesheetAppointmentDataSource                       │
│  ├── CalendarEventDetailsPanel                            │
│  └── CalendarCustomizations                               │
├─────────────────────────────────────────────────────────────┤
│                    BLoC Layer                              │
│  ├── TimeSheetListBloc (existing)                         │
│  └── TimeSheetBloc (existing)                             │
├─────────────────────────────────────────────────────────────┤
│                    Domain Layer                            │
│  ├── TimesheetEntry (existing)                            │
│  └── TimesheetAppointment (new)                           │
└─────────────────────────────────────────────────────────────┘
```

### Component Relationships

- **SyncfusionTimesheetCalendarWidget**: Main calendar widget replacing `TimesheetCalendarWidget`
- **TimesheetAppointmentDataSource**: Custom data source extending `CalendarDataSource`
- **TimesheetAppointment**: Wrapper class extending `Appointment` for timesheet-specific data
- **CalendarEventDetailsPanel**: Replacement for the current event list display
- **CalendarCustomizations**: Theme and styling configurations

## Components and Interfaces

### 1. SyncfusionTimesheetCalendarWidget

**Purpose**: Main calendar widget using Syncfusion's SfCalendar

**Key Properties**:
```dart
class SyncfusionTimesheetCalendarWidget extends StatefulWidget {
  const SyncfusionTimesheetCalendarWidget({super.key});
}

class _SyncfusionTimesheetCalendarWidgetState extends State<SyncfusionTimesheetCalendarWidget> {
  CalendarView _calendarView = CalendarView.month;
  DateTime _selectedDate = DateTime.now();
  TimesheetAppointmentDataSource? _dataSource;
  CalendarController _calendarController = CalendarController();
}
```

**Key Methods**:
- `_loadTimesheetData()`: Load timesheet entries from BLoC
- `_onCalendarTapped(CalendarTapDetails details)`: Handle calendar interactions
- `_onViewChanged(ViewChangedDetails details)`: Handle view changes
- `_buildAppointmentDataSource(List<TimesheetEntry> entries)`: Convert entries to appointments

### 2. TimesheetAppointmentDataSource

**Purpose**: Custom data source for Syncfusion calendar to handle timesheet entries

```dart
class TimesheetAppointmentDataSource extends CalendarDataSource {
  TimesheetAppointmentDataSource(List<TimesheetAppointment> appointments) {
    this.appointments = appointments;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].from;
  
  @override
  DateTime getEndTime(int index) => appointments![index].to;
  
  @override
  String getSubject(int index) => appointments![index].subject;
  
  @override
  Color getColor(int index) => appointments![index].color;
}
```

### 3. TimesheetAppointment

**Purpose**: Wrapper class extending Syncfusion's Appointment for timesheet-specific data

```dart
class TimesheetAppointment extends Appointment {
  final TimesheetEntry timesheetEntry;
  final bool isAbsence;
  final AbsencePeriod? absencePeriod;
  
  TimesheetAppointment({
    required this.timesheetEntry,
    required DateTime startTime,
    required DateTime endTime,
    required String subject,
    required Color color,
    this.isAbsence = false,
    this.absencePeriod,
  }) : super(
    startTime: startTime,
    endTime: endTime,
    subject: subject,
    color: color,
  );
}
```

### 4. CalendarEventDetailsPanel

**Purpose**: Display selected date's events below the calendar

```dart
class CalendarEventDetailsPanel extends StatelessWidget {
  final DateTime selectedDate;
  final List<TimesheetAppointment> appointments;
  final Function(TimesheetEntry) onEventTap;
  
  const CalendarEventDetailsPanel({
    required this.selectedDate,
    required this.appointments,
    required this.onEventTap,
    super.key,
  });
}
```

## Data Models

### TimesheetEntry to Appointment Mapping

The existing `TimesheetEntry` will be converted to `TimesheetAppointment` objects:

```dart
TimesheetAppointment _createWorkAppointment(TimesheetEntry entry, DateTime date) {
  return TimesheetAppointment(
    timesheetEntry: entry,
    startTime: date,
    endTime: date.add(Duration(hours: 1)), // Visual representation
    subject: _buildWorkSubject(entry),
    color: _getWorkColor(entry),
    isAbsence: false,
  );
}

TimesheetAppointment _createAbsenceAppointment(TimesheetEntry entry, DateTime date) {
  return TimesheetAppointment(
    timesheetEntry: entry,
    startTime: date,
    endTime: date.add(Duration(hours: 1)),
    subject: _buildAbsenceSubject(entry),
    color: _getAbsenceColor(entry.period),
    isAbsence: true,
    absencePeriod: AbsencePeriod.values.firstWhere(
      (p) => p.value == entry.period,
      orElse: () => AbsencePeriod.fullDay,
    ),
  );
}
```

### Color Scheme

```dart
class CalendarColorScheme {
  static const Color workDayColor = Colors.green;
  static const Color fullDayAbsenceColor = Colors.red;
  static const Color halfDayAbsenceColor = Colors.orange;
  static const Color partialWorkColor = Colors.blue;
  static const Color weekendColor = Colors.grey;
}
```

## Error Handling

### Error Scenarios and Handling

1. **Data Loading Errors**:
   ```dart
   try {
     _loadTimesheetData();
   } catch (e) {
     _showErrorSnackBar('Erreur lors du chargement des données: $e');
     _dataSource = TimesheetAppointmentDataSource([]);
   }
   ```

2. **Date Parsing Errors**:
   ```dart
   DateTime? _parseEntryDate(String dateString) {
     try {
       return DateFormat("dd-MMM-yy").parse(dateString);
     } catch (e) {
       logger.warning('Failed to parse date: $dateString');
       return null;
     }
   }
   ```

3. **Navigation Errors**:
   ```dart
   void _navigateToPointage(DateTime date, TimesheetEntry? entry) {
     try {
       Navigator.of(context).push(/* navigation logic */);
     } catch (e) {
       _showErrorSnackBar('Erreur de navigation: $e');
     }
   }
   ```

## Testing Strategy

### Unit Tests

1. **TimesheetAppointmentDataSource Tests**:
   - Test appointment creation from timesheet entries
   - Test data source methods (getStartTime, getEndTime, etc.)
   - Test edge cases with empty or invalid data

2. **TimesheetAppointment Tests**:
   - Test appointment creation with different entry types
   - Test color assignment logic
   - Test absence period handling

3. **Date Conversion Tests**:
   - Test date parsing from various formats
   - Test date range calculations
   - Test timezone handling

### Widget Tests

1. **Calendar Widget Tests**:
   - Test calendar rendering with different data sets
   - Test user interactions (tap, swipe, navigation)
   - Test view changes (month, week, day)

2. **Event Panel Tests**:
   - Test event list display
   - Test event tap handling
   - Test empty state display

### Integration Tests

1. **BLoC Integration Tests**:
   - Test calendar updates when BLoC state changes
   - Test data loading and error handling
   - Test navigation integration

2. **End-to-End Tests**:
   - Test complete user workflows
   - Test calendar-to-pointage navigation
   - Test data persistence across navigation

### Performance Tests

1. **Rendering Performance**:
   - Test calendar rendering with large datasets
   - Test smooth scrolling and animations
   - Test memory usage optimization

2. **Data Loading Performance**:
   - Test appointment creation performance
   - Test data source update performance
   - Test calendar refresh performance

## Migration Strategy

### Phase 1: Core Implementation
- Create new Syncfusion-based calendar widget
- Implement TimesheetAppointmentDataSource
- Create TimesheetAppointment wrapper class

### Phase 2: Feature Parity
- Implement all existing calendar interactions
- Add event details panel
- Integrate with existing BLoC architecture

### Phase 3: Testing and Validation
- Comprehensive testing suite
- Performance validation
- User acceptance testing

### Phase 4: Cleanup and Optimization
- Remove table_calendar dependency
- Clean up unused code
- Performance optimizations

## Accessibility Considerations

1. **Screen Reader Support**:
   - Proper semantic labels for calendar elements
   - Descriptive appointment announcements
   - Navigation instructions

2. **Keyboard Navigation**:
   - Full keyboard accessibility
   - Focus management
   - Shortcut keys for common actions

3. **Visual Accessibility**:
   - High contrast color schemes
   - Scalable text and UI elements
   - Clear visual indicators

## Performance Considerations

1. **Memory Management**:
   - Efficient appointment object creation
   - Proper disposal of resources
   - Lazy loading of calendar data

2. **Rendering Optimization**:
   - Minimize widget rebuilds
   - Efficient data source updates
   - Smooth animations and transitions

3. **Data Loading**:
   - Asynchronous data loading
   - Caching strategies
   - Progressive data loading for large datasets