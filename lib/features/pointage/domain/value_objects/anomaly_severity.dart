import 'package:flutter/material.dart';

enum AnomalySeverity {
  low('low', 'Faible', Colors.yellow, 1),
  medium('medium', 'Moyenne', Colors.orange, 2),
  high('high', 'Élevée', Colors.red, 3),
  critical('critical', 'Critique', Colors.deepPurple, 4);

  const AnomalySeverity(this.id, this.displayName, this.color, this.priority);

  final String id;
  final String displayName;
  final Color color;
  final int priority;

  static AnomalySeverity? fromId(String id) {
    for (final severity in AnomalySeverity.values) {
      if (severity.id == id) return severity;
    }
    return null;
  }

  bool isHigherThan(AnomalySeverity other) => priority > other.priority;
  bool isLowerThan(AnomalySeverity other) => priority < other.priority;

  @override
  String toString() => displayName;
}