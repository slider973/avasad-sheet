import 'package:flutter/material.dart';

/// Widget to visually indicate when overtime has started
///
/// This widget provides visual feedback when the employee has entered
/// overtime hours, using color changes and animations to draw attention
/// to the overtime status. It supports different visual states for
/// weekday overtime and weekend work.
class OvertimeIndicator extends StatefulWidget {
  final bool isOvertimeStarted;
  final Duration overtimeHours;
  final bool isWeekend;
  final bool isAnimated;

  const OvertimeIndicator({
    super.key,
    required this.isOvertimeStarted,
    required this.overtimeHours,
    required this.isWeekend,
    this.isAnimated = true,
  });

  @override
  State<OvertimeIndicator> createState() => _OvertimeIndicatorState();
}

class _OvertimeIndicatorState extends State<OvertimeIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _colorController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _opacityAnimation;

  // Color schemes for different states
  static const Map<String, List<Color>> _colorSchemes = {
    'weekday_overtime': [
      Color(0xFFFF6B35), // Orange-red
      Color(0xFFFF8E53), // Light orange
      Color(0xFFFF4500), // Deep orange
    ],
    'weekend_overtime': [
      Color(0xFF8E44AD), // Purple
      Color(0xFFAB7AC7), // Light purple
      Color(0xFF6A1B9A), // Deep purple
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    if (widget.isOvertimeStarted && widget.isAnimated) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    // Pulse animation for attention-grabbing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation for smooth entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Color animation for dynamic color changes
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    final colors = _getColorScheme();
    _colorAnimation = ColorTween(
      begin: colors[0],
      end: colors[1],
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
  }

  List<Color> _getColorScheme() {
    if (widget.isWeekend) {
      return _colorSchemes['weekend_overtime']!;
    } else {
      return _colorSchemes['weekday_overtime']!;
    }
  }

  void _startAnimations() {
    _slideController.forward();
    if (widget.isAnimated) {
      _pulseController.repeat(reverse: true);
      _colorController.repeat(reverse: true);
    }
  }

  void _stopAnimations() {
    _pulseController.stop();
    _colorController.stop();
    _slideController.reverse();
  }

  @override
  void didUpdateWidget(OvertimeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle overtime state changes
    if (widget.isOvertimeStarted != oldWidget.isOvertimeStarted) {
      if (widget.isOvertimeStarted) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }

    // Handle weekend state changes
    if (widget.isWeekend != oldWidget.isWeekend) {
      _updateColorAnimation();
    }

    // Handle animation preference changes
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated && widget.isOvertimeStarted) {
        _pulseController.repeat(reverse: true);
        _colorController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _colorController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '${hours}h${minutes}m';
  }

  IconData _getIcon() {
    if (widget.isWeekend) {
      return Icons.weekend;
    } else {
      return Icons.schedule;
    }
  }

  String _getText() {
    if (widget.isWeekend) {
      return 'Weekend: ${_formatDuration(widget.overtimeHours)}';
    } else {
      return 'Heures sup: ${_formatDuration(widget.overtimeHours)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOvertimeStarted) {
      return AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return SizeTransition(
            sizeFactor: ReverseAnimation(_slideAnimation),
            child: const SizedBox.shrink(),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _slideAnimation,
        _colorAnimation,
        _opacityAnimation,
      ]),
      builder: (context, child) {
        final colors = _getColorScheme();
        final currentColor = _colorAnimation.value ?? colors[0];
        final accentColor = colors[2];

        return Transform.scale(
          scale: _slideAnimation.value *
              (widget.isAnimated ? _pulseAnimation.value : 1.0),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    currentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: currentColor,
                  width: 2.0,
                ),
                boxShadow: widget.isAnimated
                    ? [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _getIcon(),
                      key: ValueKey(widget.isWeekend),
                      color: currentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: currentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    child: Text(_getText()),
                  ),
                  if (widget.overtimeHours > const Duration(hours: 2)) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.warning_rounded,
                      color: accentColor,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
