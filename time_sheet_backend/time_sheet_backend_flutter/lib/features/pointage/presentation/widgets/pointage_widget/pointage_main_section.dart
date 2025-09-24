import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'pointage_design_system.dart';
import 'pointage_time_info.dart';
import 'pointage_timer.dart';

/// Section principale du pointage organisant le chronomètre et les informations de temps
/// Implémente les exigences 3.1, 3.2, 3.3, 6.1, 6.3 pour la mise en page responsive
class PointageMainSection extends StatelessWidget {
  final String etatActuel;
  final DateTime? dernierPointage;
  final double progression;
  final List<Map<String, dynamic>> pointages;
  final Duration totalDayHours;
  final Duration totalBreakTime;
  final ExtendedTimerState? extendedTimerState;
  final WorkTimeInfo? workTimeInfo;
  final VoidCallback? onTotalDayTap;
  final VoidCallback? onBreakTimeTap;

  const PointageMainSection({
    super.key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.progression,
    required this.pointages,
    required this.totalDayHours,
    required this.totalBreakTime,
    this.extendedTimerState,
    this.workTimeInfo,
    this.onTotalDayTap,
    this.onBreakTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive design: adapter selon la largeur disponible
        final isCompact = constraints.maxWidth < 400;
        final isVeryCompact = constraints.maxWidth < 320;

        if (isVeryCompact) {
          return _buildVerticalLayout(context);
        } else if (isCompact) {
          return _buildCompactLayout(context);
        } else {
          return _buildStandardLayout(context);
        }
      },
    );
  }

  /// Mise en page standard pour écrans normaux et grands
  Widget _buildStandardLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Informations de temps à gauche (exigence 3.1, 3.2)
          Expanded(
            flex: 2,
            child: PointageTimeInfo(
              totalDayHours: totalDayHours,
              totalBreakTime: totalBreakTime,
              onTotalDayTap: onTotalDayTap,
              onBreakTimeTap: onBreakTimeTap,
            ),
          ),
          const SizedBox(width: PointageSpacing.lg),
          // Chronomètre à droite (exigence 2.1)
          Expanded(
            flex: 3,
            child: Center(
              child: PointageTimer(
                etatActuel: etatActuel,
                dernierPointage: dernierPointage,
                progression: progression,
                pointages: pointages,
                extendedTimerState: extendedTimerState,
                workTimeInfo: workTimeInfo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mise en page compacte pour écrans moyens
  Widget _buildCompactLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Column(
        children: [
          // Informations de temps en haut, format compact
          CompactPointageTimeInfo(
            totalDayHours: totalDayHours,
            totalBreakTime: totalBreakTime,
          ),
          const SizedBox(height: PointageSpacing.lg),
          // Chronomètre centré
          PointageTimer(
            etatActuel: etatActuel,
            dernierPointage: dernierPointage,
            progression: progression,
            pointages: pointages,
            extendedTimerState: extendedTimerState,
            workTimeInfo: workTimeInfo,
          ),
        ],
      ),
    );
  }

  /// Mise en page verticale pour très petits écrans
  Widget _buildVerticalLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.sm),
      child: Column(
        children: [
          // Informations de temps en format très compact
          _buildVeryCompactTimeInfo(context),
          const SizedBox(height: PointageSpacing.md),
          // Chronomètre réduit
          SizedBox(
            width: 200,
            height: 200,
            child: PointageTimer(
              etatActuel: etatActuel,
              dernierPointage: dernierPointage,
              progression: progression,
              pointages: pointages,
              extendedTimerState: extendedTimerState,
              workTimeInfo: workTimeInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVeryCompactTimeInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: PointageColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVeryCompactTimeItem(
            'Total',
            _formatDuration(totalDayHours),
            Icons.work_outline,
            PointageColors.entreeColor,
          ),
          Container(
            width: 1,
            height: 20,
            color: PointageColors.divider,
          ),
          _buildVeryCompactTimeItem(
            'Pause',
            _formatDuration(totalBreakTime),
            Icons.pause_circle_outline,
            PointageColors.pauseColor,
          ),
        ],
      ),
    );
  }

  Widget _buildVeryCompactTimeItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: PointageTextStyles.cardLabel.copyWith(fontSize: 10),
        ),
        Text(
          value,
          style: PointageTextStyles.cardValue.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }
}

/// Extension pour obtenir des informations sur la mise en page
extension PointageMainSectionLayout on PointageMainSection {
  /// Détermine si la mise en page doit être compacte
  static bool shouldUseCompactLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width < 400;
  }

  /// Détermine si la mise en page doit être verticale
  static bool shouldUseVerticalLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width < 320;
  }

  /// Obtient la taille optimale du chronomètre selon l'écran
  static double getOptimalTimerSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    if (screenWidth < 320) {
      return 200; // Très petit écran
    } else if (screenWidth < 400) {
      return 220; // Écran compact
    } else {
      return 250; // Écran standard
    }
  }
}
