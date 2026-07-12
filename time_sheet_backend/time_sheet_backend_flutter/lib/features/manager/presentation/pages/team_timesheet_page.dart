import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/employee_timesheet_entry.dart';
import '../../domain/entities/team_member_status.dart';
import '../bloc/team_timesheet/team_timesheet_bloc.dart';

class TeamTimesheetPage extends StatefulWidget {
  final TeamMemberStatus employee;

  const TeamTimesheetPage({super.key, required this.employee});

  @override
  State<TeamTimesheetPage> createState() => _TeamTimesheetPageState();
}

class _TeamTimesheetPageState extends State<TeamTimesheetPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadEntries();
  }

  void _loadEntries() {
    context.read<TeamTimesheetBloc>().add(LoadEmployeeTimesheet(
          employeeId: widget.employee.id,
          month: _selectedMonth.month,
          year: _selectedMonth.year,
        ));
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee.fullName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy', 'fr_CH').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Entries list
          Expanded(
            child: BlocBuilder<TeamTimesheetBloc, TeamTimesheetState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'Aucun pointage ce mois',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.entries.length,
                  itemBuilder: (context, index) {
                    return _buildEntryCard(state.entries[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(EmployeeTimesheetEntry entry) {
    final hasEntry = entry.startMorning.isNotEmpty;
    final hasAbsence = entry.absenceReason.isNotEmpty;
    final isWeekend = entry.isWeekendDay;

    Color cardColor;
    if (hasAbsence) {
      cardColor = Colors.orange.shade50;
    } else if (isWeekend) {
      cardColor = Colors.blue.shade50;
    } else if (hasEntry) {
      cardColor = Colors.white;
    } else {
      cardColor = Colors.grey.shade50;
    }

    return Card(
      color: cardColor,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(entry.dayDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (hasAbsence)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.absenceReason,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (isWeekend && !hasAbsence)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Weekend',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasEntry && !hasAbsence) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _TimeBlock(
                      label: 'Matin',
                      start: entry.startMorning,
                      end: entry.endMorning),
                  const SizedBox(width: 16),
                  _TimeBlock(
                      label: 'Après-midi',
                      start: entry.startAfternoon,
                      end: entry.endAfternoon),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dayDate) {
    try {
      final date = DateTime.parse(dayDate);
      return DateFormat('EEEE d MMMM', 'fr_CH').format(date);
    } catch (_) {
      return dayDate;
    }
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String start;
  final String end;

  const _TimeBlock({
    required this.label,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = start.isNotEmpty;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasData ? '$start - $end' : '--:-- - --:--',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: hasData ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
