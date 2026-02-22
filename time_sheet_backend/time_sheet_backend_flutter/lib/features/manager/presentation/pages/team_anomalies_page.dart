import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/powersync_database.dart';
import '../../../../core/services/supabase/supabase_service.dart';

class TeamAnomaliesPage extends StatefulWidget {
  const TeamAnomaliesPage({super.key});

  @override
  State<TeamAnomaliesPage> createState() => _TeamAnomaliesPageState();
}

class _TeamAnomaliesPageState extends State<TeamAnomaliesPage> {
  List<Map<String, dynamic>> _anomalies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnomalies();
  }

  Future<void> _loadAnomalies() async {
    setState(() => _isLoading = true);

    try {
      final db = PowerSyncDatabaseManager.database;
      final managerId = SupabaseService.instance.currentUserId ?? '';

      final rows = await db.getAll(
        '''SELECT a.*, p.first_name, p.last_name
           FROM anomalies a
           JOIN manager_employees me ON me.employee_id = a.user_id
           JOIN profiles p ON p.id = a.user_id
           WHERE me.manager_id = ? AND a.is_resolved = 0
           ORDER BY a.detected_date DESC''',
        [managerId],
      );

      setState(() {
        _anomalies = rows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveAnomaly(String anomalyId) async {
    try {
      final db = PowerSyncDatabaseManager.database;
      await db.execute(
        'UPDATE anomalies SET is_resolved = 1 WHERE id = ?',
        [anomalyId],
      );
      _loadAnomalies();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anomalies de l'équipe"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _anomalies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune anomalie non résolue',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadAnomalies(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _anomalies.length,
                    itemBuilder: (context, index) {
                      return _buildAnomalyCard(_anomalies[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildAnomalyCard(Map<String, dynamic> anomaly) {
    final firstName = anomaly['first_name'] as String? ?? '';
    final lastName = anomaly['last_name'] as String? ?? '';
    final type = anomaly['type'] as String? ?? '';
    final description = anomaly['description'] as String? ?? '';
    final detectedDate = anomaly['detected_date'] as String? ?? '';
    final anomalyId = anomaly['id'] as String;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _getAnomalyColor(type).withValues(alpha: 0.2),
                  child: Icon(
                    _getAnomalyIcon(type),
                    size: 16,
                    color: _getAnomalyColor(type),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _anomalyTypeLabel(type),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getAnomalyColor(type),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(detectedDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _resolveAnomaly(anomalyId),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Résoudre'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAnomalyColor(String type) {
    switch (type) {
      case 'insufficient_hours':
        return Colors.orange;
      case 'missing_entry':
        return Colors.red;
      case 'invalid_times':
        return Colors.red.shade700;
      case 'excessive_hours':
        return Colors.purple;
      case 'missing_break':
        return Colors.amber.shade700;
      case 'schedule_inconsistency':
        return Colors.blue;
      case 'weekly_compensation':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getAnomalyIcon(String type) {
    switch (type) {
      case 'insufficient_hours':
        return Icons.hourglass_empty;
      case 'missing_entry':
        return Icons.event_busy;
      case 'invalid_times':
        return Icons.error_outline;
      case 'excessive_hours':
        return Icons.timer_off;
      case 'missing_break':
        return Icons.free_breakfast;
      case 'schedule_inconsistency':
        return Icons.swap_horiz;
      case 'weekly_compensation':
        return Icons.balance;
      default:
        return Icons.warning;
    }
  }

  String _anomalyTypeLabel(String type) {
    switch (type) {
      case 'insufficient_hours':
        return 'Heures insuffisantes';
      case 'missing_entry':
        return 'Pointage manquant';
      case 'invalid_times':
        return 'Horaires invalides';
      case 'excessive_hours':
        return 'Heures excessives';
      case 'missing_break':
        return 'Pause manquante';
      case 'schedule_inconsistency':
        return 'Incohérence horaire';
      case 'weekly_compensation':
        return 'Compensation hebdomadaire';
      default:
        return type;
    }
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }
}
