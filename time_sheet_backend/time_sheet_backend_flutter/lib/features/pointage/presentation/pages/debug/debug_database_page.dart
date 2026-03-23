import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../../data/data_sources/local_powersync.dart';
import '../../../data/data_sources/timesheet_data_source.dart';
import '../../../../../core/database/powersync_database.dart';

class DebugDatabasePage extends StatefulWidget {
  const DebugDatabasePage({super.key});

  @override
  State<DebugDatabasePage> createState() => _DebugDatabasePageState();
}

class _DebugDatabasePageState extends State<DebugDatabasePage> {
  List<Map<String, dynamic>> _absences = [];
  List<Map<String, dynamic>> _recentEntries = [];
  final List<String> _logs = [];
  bool _loading = false;

  dynamic get _db => PowerSyncDatabaseManager.database;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final absences = await _db.getAll(
        'SELECT a.id, a.start_date, a.end_date, a.type, a.motif, a.timesheet_entry_id, '
        'te.day_date as entry_date, te.start_morning, te.absence_reason '
        'FROM absences a '
        'LEFT JOIN timesheet_entries te ON te.id = a.timesheet_entry_id '
        'ORDER BY a.start_date DESC '
        'LIMIT 50',
      );

      final entries = await _db.getAll(
        'SELECT id, day_date, start_morning, end_morning, start_afternoon, end_afternoon, '
        'absence_reason, period '
        'FROM timesheet_entries '
        'ORDER BY day_date DESC '
        'LIMIT 30',
      );

      setState(() {
        _absences = absences.map((r) => Map<String, dynamic>.from(r)).toList();
        _recentEntries = entries.map((r) => Map<String, dynamic>.from(r)).toList();
      });
    } catch (e) {
      _addLog('Erreur chargement: $e');
    }
    setState(() => _loading = false);
  }

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, '[${DateFormat.Hms().format(DateTime.now())}] $msg');
    });
  }

  Future<void> _runRepair() async {
    setState(() => _loading = true);
    _addLog('Lancement du nettoyage...');

    try {
      final dataSource = GetIt.instance<LocalDataSource>();
      if (dataSource is LocalDatasourcePowerSyncImpl) {
        await dataSource.repairCorruptedAbsences();
        _addLog('Nettoyage terminé');
      } else {
        _addLog('DataSource non PowerSync, nettoyage impossible');
      }
    } catch (e) {
      _addLog('Erreur: $e');
    }

    await _loadData();
    setState(() => _loading = false);
  }

  Future<void> _deleteAbsence(String id, String date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette absence ?'),
        content: Text('Absence du $date'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.execute('DELETE FROM absences WHERE id = ?', [id]);
      _addLog('Absence $date supprimée');
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug Base de Données'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Absences'),
              Tab(text: 'Entrées'),
              Tab(text: 'Logs'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _loadData,
            ),
            IconButton(
              icon: const Icon(Icons.build),
              tooltip: 'Réparer les absences',
              onPressed: _loading ? null : _runRepair,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAbsencesTab(),
                  _buildEntriesTab(),
                  _buildLogsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildAbsencesTab() {
    if (_absences.isEmpty) {
      return const Center(child: Text('Aucune absence en base'));
    }
    return ListView.builder(
      itemCount: _absences.length,
      itemBuilder: (context, index) {
        final a = _absences[index];
        final entryId = a['timesheet_entry_id'] as String? ?? '';
        final isInvalid = entryId.isNotEmpty && entryId.length < 36;
        final entryDate = a['entry_date'] as String?;
        final entryMorning = a['start_morning'] as String? ?? '';
        final absenceReason = a['absence_reason'] as String? ?? '';
        final isGhost = entryId.length >= 36 && absenceReason.isEmpty && entryMorning.isNotEmpty;

        Color? tileColor;
        String status = 'OK';
        if (isInvalid) {
          tileColor = Colors.red.shade50;
          status = 'ID INVALIDE: "$entryId"';
        } else if (isGhost) {
          tileColor = Colors.orange.shade50;
          status = 'FANTOME (jour travaillé sans absence_reason)';
        } else if (entryId.isEmpty) {
          tileColor = Colors.yellow.shade50;
          status = 'Sans lien (migration Isar)';
        }

        return Card(
          color: tileColor,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              '${a['start_date']} - ${a['type']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((a['motif'] as String? ?? '').isNotEmpty)
                  Text('Motif: ${a['motif']}', style: const TextStyle(fontSize: 12)),
                Text(
                  'entry_id: ${entryId.isEmpty ? "(null)" : (entryId.length > 20 ? "${entryId.substring(0, 20)}..." : entryId)}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                if (entryDate != null)
                  Text('Entrée liée: $entryDate ${entryMorning.isNotEmpty ? "(matin: $entryMorning)" : "(vide)"}',
                      style: const TextStyle(fontSize: 11)),
                Text(status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isInvalid ? Colors.red : (isGhost ? Colors.orange : Colors.green),
                    )),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _deleteAbsence(
                a['id'] as String,
                a['start_date'] as String,
              ),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildEntriesTab() {
    if (_recentEntries.isEmpty) {
      return const Center(child: Text('Aucune entrée'));
    }
    return ListView.builder(
      itemCount: _recentEntries.length,
      itemBuilder: (context, index) {
        final e = _recentEntries[index];
        final absReason = e['absence_reason'] as String? ?? '';
        final period = e['period'] as String? ?? '';
        final morning = '${e['start_morning'] ?? ''}-${e['end_morning'] ?? ''}';
        final afternoon = '${e['start_afternoon'] ?? ''}-${e['end_afternoon'] ?? ''}';
        final hasAbsence = absReason.isNotEmpty;

        return Card(
          color: hasAbsence ? Colors.blue.shade50 : null,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              '${e['day_date']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasAbsence)
                  Text('Matin: $morning | Après-midi: $afternoon', style: const TextStyle(fontSize: 12)),
                if (hasAbsence)
                  Text('ABSENCE: $absReason ($period)',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                Text(
                  'id: ${(e['id'] as String).substring(0, 20)}...',
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    if (_logs.isEmpty) {
      return const Center(child: Text('Aucun log.\nUtilisez le bouton repair (clé) pour lancer un nettoyage.', textAlign: TextAlign.center));
    }
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Text(_logs[index], style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        );
      },
    );
  }
}
