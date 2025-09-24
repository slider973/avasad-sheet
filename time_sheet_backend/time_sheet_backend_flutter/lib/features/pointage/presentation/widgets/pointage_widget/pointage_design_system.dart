import 'package:flutter/material.dart';

/// Couleurs spécifiques au pointage avec préservation des couleurs du chronomètre
class PointageColors {
  // Couleurs du chronomètre préservées (exigence 2.2, 2.3, 2.4)
  static const Color entreeColor = Colors.teal;
  static const Color pauseColor = Color(0xFFE7D37F); // Jaune
  static const Color repriseColor = Color(0xFFFD9B63); // Orange

  // Nouvelles couleurs du design system
  static const Color primary = Color(0xFF2D3E50);
  static const Color secondary = Color(0xFF34495E);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color textPrimary = Color(0xFF2D3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color divider = Color(0xFFECF0F1);
}

/// Styles de texte harmonisés pour le pointage
class PointageTextStyles {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: PointageColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle primaryTime = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: PointageColors.primary,
    letterSpacing: -0.3,
  );

  static const TextStyle secondaryTime = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: PointageColors.textSecondary,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle timerState = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: PointageColors.primary,
  );

  static const TextStyle timerTime = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: PointageColors.primary,
    letterSpacing: -1.0,
  );

  static const TextStyle timerDuration = TextStyle(
    fontSize: 16,
    color: PointageColors.textSecondary,
  );

  static const TextStyle cardLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: PointageColors.textSecondary,
  );

  static const TextStyle cardValue = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: PointageColors.primary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

/// Espacements standardisés pour le pointage
class PointageSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets sectionPadding = EdgeInsets.all(16.0);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets compactPadding = EdgeInsets.all(12.0);
}

/// Extension de thème pour le pointage
class PointageThemeExtension extends ThemeExtension<PointageThemeExtension> {
  final PointageColors colors;
  final PointageTextStyles textStyles;
  final PointageSpacing spacing;

  const PointageThemeExtension({
    required this.colors,
    required this.textStyles,
    required this.spacing,
  });

  @override
  PointageThemeExtension copyWith({
    PointageColors? colors,
    PointageTextStyles? textStyles,
    PointageSpacing? spacing,
  }) {
    return PointageThemeExtension(
      colors: colors ?? this.colors,
      textStyles: textStyles ?? this.textStyles,
      spacing: spacing ?? this.spacing,
    );
  }

  @override
  PointageThemeExtension lerp(
      ThemeExtension<PointageThemeExtension>? other, double t) {
    if (other is! PointageThemeExtension) {
      return this;
    }
    return PointageThemeExtension(
      colors: colors,
      textStyles: textStyles,
      spacing: spacing,
    );
  }
}

/// Widget de thème pour le pointage
class PointageTheme extends StatelessWidget {
  final Widget child;

  const PointageTheme({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [
          PointageThemeExtension(
            colors: PointageColors(),
            textStyles: PointageTextStyles(),
            spacing: PointageSpacing(),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Extension pour accéder facilement au thème pointage
extension PointageThemeContext on BuildContext {
  PointageThemeExtension? get pointageTheme =>
      Theme.of(this).extension<PointageThemeExtension>();
}
