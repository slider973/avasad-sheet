import 'package:flutter/material.dart';

import '../bloc/manager_dashboard_bloc.dart';

class EmployeeStatusCard extends StatelessWidget {
  final EmployeeStatus employee;
  final VoidCallback? onTap;

  const EmployeeStatusCard({
    super.key,
    required this.employee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      employee.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusChip(),
                  ],
                ),
              ),
              if (employee.lastClockIn != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Pointage',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      employee.lastClockIn!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = '${employee.firstName.isNotEmpty ? employee.firstName[0] : ''}${employee.lastName.isNotEmpty ? employee.lastName[0] : ''}'.toUpperCase();

    Color bgColor;
    if (employee.hasAbsence) {
      bgColor = Colors.orange.shade100;
    } else if (employee.isPresentToday) {
      bgColor = Colors.green.shade100;
    } else {
      bgColor = Colors.grey.shade200;
    }

    Color fgColor;
    if (employee.hasAbsence) {
      fgColor = Colors.orange.shade700;
    } else if (employee.isPresentToday) {
      fgColor = Colors.green.shade700;
    } else {
      fgColor = Colors.grey.shade600;
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    String label;
    Color color;
    IconData icon;

    if (employee.hasAbsence) {
      label = _absenceTypeLabel(employee.absenceType);
      color = Colors.orange;
      icon = Icons.event_busy;
    } else if (employee.isPresentToday) {
      label = 'Présent';
      color = Colors.green;
      icon = Icons.check_circle_outline;
    } else {
      label = 'Non pointé';
      color = Colors.grey;
      icon = Icons.schedule;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _absenceTypeLabel(String? type) {
    switch (type) {
      case 'vacation':
        return 'Vacances';
      case 'sick':
        return 'Maladie';
      case 'holiday':
        return 'Jour férié';
      case 'unpaid':
        return 'Congé sans solde';
      case 'training':
        return 'Formation';
      default:
        return 'Absent';
    }
  }
}
