import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:powersync/powersync.dart' hide Column;

import '../../../../core/database/powersync_database.dart';
import '../bloc/manager_dashboard_bloc.dart';

class TeamTimesheetPage extends StatefulWidget {
  final EmployeeStatus employee;

  const TeamTimesheetPage({super.key, required this.employee});

  @override
  State<TeamTimesheetPage> createState() => _TeamTimesheetPageState();
}

class _TeamTimesheetPageState extends State<TeamTimesheetPage> {
  late DateTime _selectedMonth;
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    try {
      final db = PowerSyncDatabaseManager.database;
      final startDate = DateFormat('yyyy-MM-dd').format(_selectedMonth);
      final endDate = DateFormat('yyyy-MM-dd').format(
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0),
      );

      final rows = await db.getAll(
        '''SELECT * FROM timesheet_entries
           WHERE user_id = ? AND day_date >= ? AND day_date <= ?
           ORDER BY day_date ASC''',
        [widget.employee.id, startDate, endDate],
      );

      setState(() {
        _entries = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'Aucun pointage ce mois',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          return _buildEntryCard(_entries[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final dayDate = entry['day_date'] as String? ?? '';
    final startMorning = entry['start_morning'] as String? ?? '';
    final endMorning = entry['end_morning'] as String? ?? '';
    final startAfternoon = entry['start_afternoon'] as String? ?? '';
    final endAfternoon = entry['end_afternoon'] as String? ?? '';
    final absenceReason = entry['absence_reason'] as String? ?? '';
    final isWeekend = (entry['is_weekend_day'] as int?) == 1;

    final hasEntry = startMorning.isNotEmpty;
    final hasAbsence = absenceReason.isNotEmpty;

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
                  _formatDate(dayDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (hasAbsence)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      absenceReason,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (isWeekend && !hasAbsence)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  _TimeBlock(label: 'Matin', start: startMorning, end: endMorning),
                  const SizedBox(width: 16),
                  _TimeBlock(label: 'Après-midi', start: startAfternoon, end: endAfternoon),
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
