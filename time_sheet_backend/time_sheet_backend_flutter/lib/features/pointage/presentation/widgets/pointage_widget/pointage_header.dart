import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_painter.dart';

class PointageHeader extends StatelessWidget {
  final DateTime selectedDate;

  const PointageHeader({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final formattedDate = dateFormat.format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Heure de pointage',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          formattedDate,
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}