import 'package:flutter/material.dart';
import 'calendar_theme_config.dart';

/// Manages loading states and refresh functionality for the calendar
class CalendarLoadingManager {
  /// Shows a loading overlay on top of the calendar
  static Widget buildLoadingOverlay(
    BuildContext context, {
    required bool isLoading,
    required Widget child,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading) CalendarThemeConfig.getLoadingOverlay(context),
      ],
    );
  }

  /// Shows a full-screen loading indicator for initial load
  static Widget buildFullScreenLoading(
    BuildContext context, {
    String? message,
  }) {
    return Center(
      child: CalendarThemeConfig.getLoadingIndicator(
        context,
        message: message ?? 'Chargement du calendrier...',
      ),
    );
  }

  /// Shows an error state with retry option
  static Widget buildErrorState(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    return CalendarThemeConfig.getErrorWidget(
      context,
      message: message,
      onRetry: onRetry,
    );
  }

  /// Wraps the calendar with refresh indicator
  static Widget buildRefreshWrapper(
    BuildContext context, {
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return CalendarThemeConfig.getRefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }

  /// Shows a snackbar for loading feedback
  static void showLoadingFeedback(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.blue[600],
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccessFeedback(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows an error snackbar
  static void showErrorFeedback(
    BuildContext context, {
    required String message,
    Duration? duration,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows a warning snackbar
  static void showWarningFeedback(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Creates a shimmer loading effect for calendar cells
  static Widget buildShimmerLoading(BuildContext context) {
    return Container(
      decoration: CalendarThemeConfig.getCalendarBackgroundDecoration(context),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 42, // 6 weeks * 7 days
        itemBuilder: (context, index) {
          return _buildShimmerCell();
        },
      ),
    );
  }

  /// Builds a single shimmer cell
  static Widget _buildShimmerCell() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  /// Creates a pull-to-refresh gesture detector
  static Widget buildPullToRefresh({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 40,
      strokeWidth: 3,
      child: child,
    );
  }

  /// Shows a loading dialog for long operations
  static void showLoadingDialog(
    BuildContext context, {
    required String message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Hides the loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
