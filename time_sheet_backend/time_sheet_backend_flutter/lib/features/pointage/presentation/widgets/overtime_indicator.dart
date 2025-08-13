import 'package:flutter/material.dart';

class OvertimeIndicator extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const OvertimeIndicator({
    Key? key,
    required this.isActive,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_filled,
          color: isActive ? Colors.orange : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          'HS',
          style: TextStyle(
            color: isActive ? Colors.orange : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Switch(
          value: isActive,
          onChanged: (_) => onToggle(),
          activeColor: Colors.orange,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}