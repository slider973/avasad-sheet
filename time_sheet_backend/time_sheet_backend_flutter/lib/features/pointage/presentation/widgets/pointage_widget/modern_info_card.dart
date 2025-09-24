import 'package:flutter/material.dart';

/// Composant de base modernisé pour toutes les cartes d'information
/// Fournit un style cohérent avec ombres, bordures arrondies et animations
class ModernInfoCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool isInteractive;
  final Duration animationDuration;

  const ModernInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.backgroundColor,
    this.elevation = 2,
    this.borderRadius,
    this.onTap,
    this.isInteractive = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<ModernInfoCard> createState() => _ModernInfoCardState();
}

class _ModernInfoCardState extends State<ModernInfoCard>
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
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2,
      end: (widget.elevation ?? 2) + 2,
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
    if (widget.isInteractive || widget.onTap != null) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isInteractive || widget.onTap != null) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isInteractive || widget.onTap != null) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.cardColor;
    final defaultBorderRadius = BorderRadius.circular(16);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: widget.borderRadius ?? defaultBorderRadius,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? defaultBackgroundColor,
                    borderRadius: widget.borderRadius ?? defaultBorderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: _elevationAnimation.value * 2,
                        offset: Offset(0, _elevationAnimation.value),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: _elevationAnimation.value,
                        offset: Offset(0, _elevationAnimation.value / 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: widget.padding ?? EdgeInsets.zero,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Extension pour créer des variantes spécialisées de ModernInfoCard
extension ModernInfoCardVariants on ModernInfoCard {
  /// Variante avec style d'accent (bordure colorée)
  static ModernInfoCard accent({
    Key? key,
    required Widget child,
    required Color accentColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    bool isInteractive = false,
  }) {
    return ModernInfoCard(
      key: key,
      padding: padding,
      margin: margin,
      onTap: onTap,
      isInteractive: isInteractive,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: accentColor,
              width: 4,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  /// Variante avec style d'alerte
  static ModernInfoCard alert({
    Key? key,
    required Widget child,
    required Color alertColor,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    bool isInteractive = false,
  }) {
    return ModernInfoCard(
      key: key,
      padding: padding,
      margin: margin,
      onTap: onTap,
      isInteractive: isInteractive,
      backgroundColor: alertColor.withValues(alpha: 0.1),
      child: child,
    );
  }

  /// Variante compacte
  static ModernInfoCard compact({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    bool isInteractive = false,
  }) {
    return ModernInfoCard(
      key: key,
      padding: const EdgeInsets.all(12.0),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      onTap: onTap,
      isInteractive: isInteractive,
      child: child,
    );
  }
}
