import 'package:flutter/material.dart';

/// Bouton modernisé pour les actions de pointage avec styles harmonisés
/// Inclut animations, effets visuels et gestion des différents états
class ModernPointageButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final PointageButtonStyle style;
  final PointageButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final Duration animationDuration;

  const ModernPointageButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = PointageButtonStyle.primary,
    this.size = PointageButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Constructeur pour le bouton d'entrée
  const ModernPointageButton.entry({
    super.key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  })  : text = 'Commencer',
        style = PointageButtonStyle.entry,
        size = PointageButtonSize.large,
        icon = Icons.play_arrow,
        animationDuration = const Duration(milliseconds: 200),
        onPressed = onPressed,
        isLoading = isLoading;

  /// Constructeur pour le bouton de pause
  const ModernPointageButton.pause({
    super.key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  })  : text = 'Pause',
        style = PointageButtonStyle.pause,
        size = PointageButtonSize.large,
        icon = Icons.pause,
        animationDuration = const Duration(milliseconds: 200),
        onPressed = onPressed,
        isLoading = isLoading;

  /// Constructeur pour le bouton de reprise
  const ModernPointageButton.resume({
    super.key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  })  : text = 'Reprise',
        style = PointageButtonStyle.resume,
        size = PointageButtonSize.large,
        icon = Icons.play_arrow,
        animationDuration = const Duration(milliseconds: 200),
        onPressed = onPressed,
        isLoading = isLoading;

  /// Constructeur pour le bouton de sortie
  const ModernPointageButton.exit({
    super.key,
    required VoidCallback? onPressed,
    bool isLoading = false,
  })  : text = 'Terminer',
        style = PointageButtonStyle.exit,
        size = PointageButtonSize.large,
        icon = Icons.stop,
        animationDuration = const Duration(milliseconds: 200),
        onPressed = onPressed,
        isLoading = isLoading;

  /// Constructeur pour les boutons secondaires
  const ModernPointageButton.secondary({
    super.key,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    PointageButtonSize size = PointageButtonSize.large,
  })  : style = PointageButtonStyle.secondary,
        size = size,
        animationDuration = const Duration(milliseconds: 200),
        text = text,
        onPressed = onPressed,
        icon = icon,
        isLoading = isLoading;

  /// Constructeur pour les boutons destructifs
  const ModernPointageButton.destructive({
    super.key,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    PointageButtonSize size = PointageButtonSize.large,
  })  : style = PointageButtonStyle.destructive,
        size = size,
        animationDuration = const Duration(milliseconds: 200),
        text = text,
        onPressed = onPressed,
        icon = icon,
        isLoading = isLoading;

  @override
  State<ModernPointageButton> createState() => _ModernPointageButtonState();
}

class _ModernPointageButtonState extends State<ModernPointageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 6.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonConfig = _getButtonConfiguration(theme);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: buttonConfig.width,
            height: buttonConfig.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(buttonConfig.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: buttonConfig.backgroundColor.withValues(alpha: 0.3),
                  blurRadius: _elevationAnimation.value,
                  offset: Offset(0, _elevationAnimation.value / 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onPressed,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(buttonConfig.borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.onPressed == null
                        ? buttonConfig.backgroundColor.withValues(alpha: 0.5)
                        : buttonConfig.backgroundColor,
                    borderRadius:
                        BorderRadius.circular(buttonConfig.borderRadius),
                    border: buttonConfig.borderColor != null
                        ? Border.all(
                            color: buttonConfig.borderColor!, width: 1.5)
                        : null,
                  ),
                  child: _buildButtonContent(buttonConfig),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(_ButtonConfiguration config) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: config.iconSize,
          height: config.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: config.textColor,
            size: config.iconSize,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: config.fontSize,
                fontWeight: config.fontWeight,
                color: config.textColor,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: config.fontSize,
          fontWeight: config.fontWeight,
          color: config.textColor,
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  _ButtonConfiguration _getButtonConfiguration(ThemeData theme) {
    switch (widget.style) {
      case PointageButtonStyle.entry:
        return _ButtonConfiguration(
          backgroundColor: Colors.teal,
          textColor: Colors.white,
          width: widget.size.width,
          height: widget.size.height,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.w600,
          borderRadius: 16,
          iconSize: widget.size.iconSize,
        );

      case PointageButtonStyle.pause:
        return _ButtonConfiguration(
          backgroundColor: const Color(0xFF365E32),
          textColor: Colors.white,
          width: widget.size.width,
          height: widget.size.height,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.w600,
          borderRadius: 16,
          iconSize: widget.size.iconSize,
        );

      case PointageButtonStyle.resume:
        return _ButtonConfiguration(
          backgroundColor: const Color(0xFF81A263),
          textColor: Colors.white,
          width: widget.size.width,
          height: widget.size.height,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.w600,
          borderRadius: 16,
          iconSize: widget.size.iconSize,
        );

      case PointageButtonStyle.exit:
        return _ButtonConfiguration(
          backgroundColor: const Color(0xFFFD9B63),
          textColor: Colors.white,
          width: widget.size.width,
          height: widget.size.height,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.w600,
          borderRadius: 16,
          iconSize: widget.size.iconSize,
        );

      case PointageButtonStyle.secondary:
        return _ButtonConfiguration(
          backgroundColor: Colors.transparent,
          textColor: theme.colorScheme.primary,
          borderColor: theme.colorScheme.primary,
          width: widget.size.width,
          height: widget.size.height,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.w500,
          borderRadius: 12,
          iconSize: widget.size.iconSize,
        );

      case PointageButtonStyle.destructive:
        return _ButtonConfiguration(
          backgroundColor: Colors.transparent,
          textColor: theme.colorScheme.error,
          borderColor: theme.colorScheme.error,
          width: widget.size.width,
          height: widget.size.height,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.w500,
          borderRadius: 12,
          iconSize: widget.size.iconSize,
        );

      case PointageButtonStyle.primary:
      default:
        return _ButtonConfiguration(
          backgroundColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onPrimary,
          width: widget.size.width,
          height: widget.size.height,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.w600,
          borderRadius: 16,
          iconSize: widget.size.iconSize,
        );
    }
  }
}

/// Styles disponibles pour les boutons de pointage
enum PointageButtonStyle {
  primary,
  secondary,
  destructive,
  entry,
  pause,
  resume,
  exit,
}

/// Tailles disponibles pour les boutons
enum PointageButtonSize {
  small(width: 120, height: 36, fontSize: 14, iconSize: 18),
  medium(width: 200, height: 44, fontSize: 16, iconSize: 20),
  large(width: 320, height: 52, fontSize: 18, iconSize: 24);

  const PointageButtonSize({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.iconSize,
  });

  final double width;
  final double height;
  final double fontSize;
  final double iconSize;
}

/// Configuration interne pour le style des boutons
class _ButtonConfiguration {
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double width;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;
  final double borderRadius;
  final double iconSize;

  const _ButtonConfiguration({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.fontWeight,
    required this.borderRadius,
    required this.iconSize,
  });
}
