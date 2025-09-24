import 'package:flutter/material.dart';
import 'modern_info_card.dart';

/// Carte spécialisée pour l'affichage des informations de temps
/// Utilise ModernInfoCard comme base avec un style adapté aux données temporelles
class TimeInfoCard extends StatelessWidget {
  final String title;
  final String timeValue;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? timeColor;
  final VoidCallback? onTap;
  final bool showProgress;
  final double? progressValue;
  final Color? progressColor;
  final EdgeInsetsGeometry? margin;
  final bool isCompact;

  const TimeInfoCard({
    super.key,
    required this.title,
    required this.timeValue,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.timeColor,
    this.onTap,
    this.showProgress = false,
    this.progressValue,
    this.progressColor,
    this.margin,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (isCompact) {
      return _buildCompactCard(context, theme, textTheme);
    }

    return ModernInfoCard(
      margin: margin,
      onTap: onTap,
      isInteractive: onTap != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, textTheme),
          const SizedBox(height: 12),
          _buildTimeDisplay(theme, textTheme),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            _buildSubtitle(theme, textTheme),
          ],
          if (showProgress && progressValue != null) ...[
            const SizedBox(height: 12),
            _buildProgressBar(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactCard(
      BuildContext context, ThemeData theme, TextTheme textTheme) {
    return ModernInfoCardVariants.compact(
      margin: margin,
      onTap: onTap,
      isInteractive: onTap != null,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeValue,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: timeColor ?? theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, TextTheme textTheme) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: iconColor ?? theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay(ThemeData theme, TextTheme textTheme) {
    return Text(
      timeValue,
      style: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: timeColor ?? theme.colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme, TextTheme textTheme) {
    return Text(
      subtitle!,
      style: textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? theme.colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),
        if (progressValue != null) ...[
          const SizedBox(height: 4),
          Text(
            '${(progressValue! * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Extensions pour créer des variantes spécialisées de TimeInfoCard
extension TimeInfoCardVariants on TimeInfoCard {
  /// Variante pour le temps de travail quotidien
  static TimeInfoCard dailyWork({
    Key? key,
    required String timeValue,
    String? subtitle,
    VoidCallback? onTap,
    bool showProgress = false,
    double? progressValue,
    EdgeInsetsGeometry? margin,
    bool isCompact = false,
  }) {
    return TimeInfoCard(
      key: key,
      title: 'Temps de travail',
      timeValue: timeValue,
      subtitle: subtitle,
      icon: Icons.work_outline,
      iconColor: Colors.teal,
      onTap: onTap,
      showProgress: showProgress,
      progressValue: progressValue,
      progressColor: Colors.teal,
      margin: margin,
      isCompact: isCompact,
    );
  }

  /// Variante pour le temps de pause
  static TimeInfoCard breakTime({
    Key? key,
    required String timeValue,
    String? subtitle,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    bool isCompact = false,
  }) {
    return TimeInfoCard(
      key: key,
      title: 'Temps de pause',
      timeValue: timeValue,
      subtitle: subtitle,
      icon: Icons.pause_circle_outline,
      iconColor: const Color(0xFFE7D37F),
      timeColor: const Color(0xFF8B7000),
      onTap: onTap,
      margin: margin,
      isCompact: isCompact,
    );
  }

  /// Variante pour les heures supplémentaires
  static TimeInfoCard overtime({
    Key? key,
    required String timeValue,
    String? subtitle,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    bool isCompact = false,
  }) {
    return TimeInfoCard(
      key: key,
      title: 'Heures supplémentaires',
      timeValue: timeValue,
      subtitle: subtitle,
      icon: Icons.schedule,
      iconColor: const Color(0xFFFD9B63),
      timeColor: const Color(0xFFD67E2C),
      onTap: onTap,
      margin: margin,
      isCompact: isCompact,
    );
  }

  /// Variante pour l'heure de fin estimée
  static TimeInfoCard estimatedEnd({
    Key? key,
    required String timeValue,
    String? subtitle,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
    bool isCompact = false,
  }) {
    return TimeInfoCard(
      key: key,
      title: 'Fin de journée estimée',
      timeValue: timeValue,
      subtitle: subtitle,
      icon: Icons.access_time,
      iconColor: Colors.blue.shade600,
      timeColor: Colors.blue.shade700,
      onTap: onTap,
      margin: margin,
      isCompact: isCompact,
    );
  }
}
