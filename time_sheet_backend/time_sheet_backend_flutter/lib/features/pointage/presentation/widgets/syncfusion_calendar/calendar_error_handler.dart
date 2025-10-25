import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../services/logger_service.dart';
import 'timesheet_appointment.dart';

/// Comprehensive error handling utility for Syncfusion calendar components
class CalendarErrorHandler {
  /// Handles data loading errors with user-friendly messages and recovery options
  static void handleDataLoadingError(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    logger.e('Calendar data loading error',
        error: error, stackTrace: stackTrace);

    String userMessage = customMessage ?? _getDataLoadingErrorMessage(error);

    _showErrorSnackBar(
      context,
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Handles date parsing errors with specific error messages
  static void handleDateParsingError(
    BuildContext context,
    String dateString,
    dynamic error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
  }) {
    logger.e('Date parsing error for date: $dateString',
        error: error, stackTrace: stackTrace);

    String userMessage = 'Format de date invalide: $dateString';
    if (error is FormatException) {
      userMessage = 'La date "$dateString" n\'est pas dans le format attendu';
    }

    _showErrorSnackBar(
      context,
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Handles navigation errors with appropriate user feedback
  static void handleNavigationError(
    BuildContext context,
    String destination,
    dynamic error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
  }) {
    logger.e('Navigation error to $destination',
        error: error, stackTrace: stackTrace);

    String userMessage = 'Erreur lors de la navigation vers $destination';
    if (error is StateError) {
      userMessage = 'Navigation non disponible';
    } else if (error is ArgumentError) {
      userMessage = 'Paramètres de navigation invalides';
    }

    _showErrorSnackBar(
      context,
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Handles appointment creation/conversion errors
  static void handleAppointmentError(
    BuildContext context,
    String entryId,
    dynamic error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
  }) {
    logger.e('Appointment error for entry $entryId',
        error: error, stackTrace: stackTrace);

    String userMessage = 'Erreur lors du traitement de l\'entrée $entryId';
    if (error is ArgumentError) {
      userMessage = 'Données d\'entrée invalides pour $entryId';
    } else if (error is FormatException) {
      userMessage = 'Format de données incorrect pour $entryId';
    }

    _showErrorSnackBar(
      context,
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Handles BLoC state errors
  static void handleBlocStateError(
    BuildContext context,
    String blocName,
    String stateName,
    dynamic error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
  }) {
    logger.e('BLoC state error in $blocName: $stateName',
        error: error, stackTrace: stackTrace);

    String userMessage = 'Erreur dans l\'état de l\'application';
    if (blocName.contains('TimeSheet')) {
      userMessage = 'Erreur lors du traitement des données de pointage';
    }

    _showErrorSnackBar(
      context,
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Handles calendar interaction errors (tap, selection, etc.)
  static void handleInteractionError(
    BuildContext context,
    String interactionType,
    dynamic error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
  }) {
    logger.e('Calendar interaction error: $interactionType',
        error: error, stackTrace: stackTrace);

    String userMessage = 'Erreur lors de l\'interaction avec le calendrier';
    if (error is TypeError) {
      userMessage = 'Type d\'élément non supporté';
    } else if (error is ArgumentError) {
      userMessage = 'Paramètres d\'interaction invalides';
    }

    _showErrorSnackBar(
      context,
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Handles validation errors for user input
  static void handleValidationError(
    BuildContext context,
    String fieldName,
    String validationMessage, {
    VoidCallback? onRetry,
  }) {
    logger.w('Validation error for $fieldName: $validationMessage');

    _showErrorSnackBar(
      context,
      message: 'Erreur de validation: $validationMessage',
      onRetry: onRetry,
      isWarning: true,
    );
  }

  /// Handles timeout errors
  static void handleTimeoutError(
    BuildContext context,
    String operation,
    Duration timeout, {
    VoidCallback? onRetry,
  }) {
    logger.w('Timeout error for $operation after ${timeout.inSeconds}s');

    _showErrorSnackBar(
      context,
      message: 'Délai d\'attente dépassé pour $operation',
      onRetry: onRetry,
      isWarning: true,
    );
  }

  /// Handles network/connectivity errors
  static void handleNetworkError(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace, {
    VoidCallback? onRetry,
  }) {
    logger.e('Network error', error: error, stackTrace: stackTrace);

    String userMessage = 'Erreur de connexion réseau';
    if (error.toString().contains('timeout')) {
      userMessage = 'Délai de connexion dépassé';
    } else if (error.toString().contains('host')) {
      userMessage = 'Serveur non accessible';
    }

    _showErrorSnackBar(
      context,
      message: userMessage,
      onRetry: onRetry,
    );
  }

  /// Shows a standardized error SnackBar with optional retry functionality
  static void _showErrorSnackBar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    bool isWarning = false,
  }) {
    if (!context.mounted) return;

    final backgroundColor = isWarning ? Colors.orange : Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: isWarning ? 3 : 5),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Gets appropriate error message for data loading errors
  static String _getDataLoadingErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'Délai d\'attente dépassé lors du chargement';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Erreur de connexion réseau';
    } else if (error is FormatException) {
      return 'Format de données incorrect';
    } else if (error is ArgumentError) {
      return 'Paramètres de chargement invalides';
    } else {
      return 'Erreur lors du chargement des données';
    }
  }

  /// Validates date string format and throws appropriate errors
  static DateTime validateAndParseDate(String dateString, String entryId) {
    if (dateString.isEmpty) {
      throw ArgumentError('Date string is empty for entry $entryId');
    }

    try {
      // Try the expected format first
      return DateFormat("dd-MMM-yy", 'en_US').parse(dateString);
    } catch (e) {
      // Try alternative formats
      final alternativeFormats = [
        "dd/MM/yyyy",
        "yyyy-MM-dd",
        "dd-MM-yyyy",
        "MM/dd/yyyy",
      ];

      for (final format in alternativeFormats) {
        try {
          return DateFormat(format).parse(dateString);
        } catch (_) {
          // Continue to next format
        }
      }

      throw FormatException(
          'Unable to parse date "$dateString" for entry $entryId');
    }
  }

  /// Validates navigation context before attempting navigation
  static bool validateNavigationContext(
      BuildContext context, String destination) {
    if (!context.mounted) {
      logger.w('Context not mounted for navigation to $destination');
      return false;
    }

    final navigator = Navigator.of(context);
    if (navigator == null) {
      logger.w('Navigator not available for navigation to $destination');
      return false;
    }

    return true;
  }

  /// Validates appointment data before processing
  static void validateAppointmentData(dynamic appointment, String context) {
    if (appointment == null) {
      throw ArgumentError('Appointment is null in $context');
    }

    if (appointment is! TimesheetAppointment) {
      throw TypeError();
    }

    final entry = appointment.timesheetEntry;
    if (entry.dayDate.isEmpty) {
      throw ArgumentError('Appointment dayDate is empty in $context');
    }
  }

  /// Logs successful operations for debugging
  static void logSuccess(String operation, {Map<String, dynamic>? details}) {
    String message = 'Successfully completed: $operation';
    if (details != null && details.isNotEmpty) {
      message += ' - Details: $details';
    }
    logger.i(message);
  }

  /// Logs warnings for non-critical issues
  static void logWarning(String operation, String warning,
      {Map<String, dynamic>? details}) {
    String message = 'Warning in $operation: $warning';
    if (details != null && details.isNotEmpty) {
      message += ' - Details: $details';
    }
    logger.w(message);
  }
}

/// Custom exception for calendar-specific errors
class CalendarException implements Exception {
  final String message;
  final String? operation;
  final dynamic originalError;

  const CalendarException(
    this.message, {
    this.operation,
    this.originalError,
  });

  @override
  String toString() {
    String result = 'CalendarException: $message';
    if (operation != null) {
      result += ' (Operation: $operation)';
    }
    if (originalError != null) {
      result += ' (Original: $originalError)';
    }
    return result;
  }
}

/// Exception for timeout operations
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() =>
      'TimeoutException: $message (timeout: ${timeout.inSeconds}s)';
}
