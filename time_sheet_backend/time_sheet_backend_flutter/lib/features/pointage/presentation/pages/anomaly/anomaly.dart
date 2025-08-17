// Dans /features/pointage/presentation/pages/anomaly/anomaly.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/anomalies/anomalies.dart';
import '../../../domain/entities/anomaly.dart';
import '../../widgets/pointage_widget/pointage_widget.dart';
import '../pdf/bloc/anomaly/anomaly_bloc.dart';
import '../../../../bottom_nav_tab/presentation/pages/app_drawer.dart';

class AnomalyView extends StatefulWidget {
  const AnomalyView({super.key});

  @override
  State<AnomalyView> createState() => _AnomalyViewState();
}

class _AnomalyViewState extends State<AnomalyView> {
  String _searchQuery = '';
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    // Forcer le chargement avec le nouveau système de compensation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnomalyBloc>().add(const DetectAnomalies(forceRegenerate: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Anomalies'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAnomalies,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: Colors.teal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Barre de recherche
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une anomalie...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filtre actives uniquement
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _showOnlyActive = !_showOnlyActive),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _showOnlyActive ? Colors.white : Colors.teal.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showOnlyActive ? Icons.warning : Icons.all_inclusive,
                                size: 18,
                                color: _showOnlyActive ? Colors.orange : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showOnlyActive ? 'Actives uniquement' : 'Toutes les anomalies',
                                style: TextStyle(
                                  color: _showOnlyActive ? Colors.black87 : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Corps principal
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAnomalies,
              child: BlocBuilder<AnomalyBloc, AnomalyState>(
                builder: (context, state) {
                  if (state is AnomalyLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Gérer le nouvel état avec compensation
                  if (state is AnomaliesWithCompensationLoaded) {
                    return _buildModernCompensatedView(state);
                  }

                  // Ancien système (fallback)
                  if (state is AnomalyLoaded) {
                    final unresolvedAnomalies = state.anomalies.where((a) => !a.isResolved).toList();

                    if (unresolvedAnomalies.isEmpty) {
                      return _buildEmptyState(false);
                    }

                    return _buildAnomaliesList(context, unresolvedAnomalies);
                  }

                  if (state is AnomalyError) {
                    return Center(child: Text(state.message));
                  }

                  return const Center(child: Text('Aucune donnée à afficher pour le moment.'));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool resolved) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune anomalie détectée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tirez vers le bas pour rafraîchir',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesList(BuildContext context, List<AnomalyModel> anomalies) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: anomalies.length,
      itemBuilder: (context, index) {
        final anomaly = anomalies[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: () => _navigateToCorrection(context, anomaly),
            leading: _getAnomalyIcon(anomaly.type),
            title: Text(
              anomaly.type.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anomaly.description),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(anomaly.detectedDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshAnomalies() async {
    context.read<AnomalyBloc>().add(const DetectAnomalies(forceRegenerate: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Widget _getAnomalyIcon(AnomalyType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case AnomalyType.insufficientHours:
        iconData = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case AnomalyType.missingEntry:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      case AnomalyType.invalidTimes:
        iconData = Icons.error_outline;
        iconColor = Colors.purple;
        break;
    }

    return Icon(iconData, color: iconColor);
  }

  void _navigateToCorrection(BuildContext context, AnomalyModel anomaly) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Détails du pointage'),
            backgroundColor: Colors.teal,
          ),
          body: SingleChildScrollView(
            child: PointageWidget(
              entry: null, // Vous voudrez peut-être passer l'entrée si disponible
              selectedDate: anomaly.detectedDate,
            ),
          ),
        ),
      ),
    )
        .then(
      (value) {
        // Recharger les anomalies au retour de la page de correction
        if (mounted) {
          context.read<AnomalyBloc>().add(const DetectAnomalies());
        }
      },
    );
  }

  Widget _buildModernCompensatedView(AnomaliesWithCompensationLoaded state) {
    var activeAnomalies = state.activeAnomalies;
    var compensatedAnomalies = state.compensatedAnomalies;
    final weeklyStats = state.weeklyStats;

    // Appliquer les filtres
    if (_searchQuery.isNotEmpty) {
      activeAnomalies = activeAnomalies
          .where((a) =>
              a.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              DateFormat('dd/MM/yyyy').format(a.date).contains(_searchQuery))
          .toList();

      compensatedAnomalies = compensatedAnomalies
          .where((a) =>
              a.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              DateFormat('dd/MM/yyyy').format(a.date).contains(_searchQuery))
          .toList();
    }

    if (_showOnlyActive) {
      compensatedAnomalies = [];
    }

    // Grouper les anomalies par semaine
    final groupedAnomalies = _groupAnomaliesByWeek(activeAnomalies, compensatedAnomalies);

    if (groupedAnomalies.isEmpty && _searchQuery.isEmpty) {
      return _buildEmptyState(false);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Carte de résumé avec un design moderne
        if (weeklyStats.isNotEmpty && _searchQuery.isEmpty) _buildModernSummaryCard(weeklyStats),

        // Afficher les anomalies groupées par semaine
        ...groupedAnomalies.entries.map((entry) => _buildWeekSection(entry.key, entry.value)),

        if (groupedAnomalies.isEmpty && _searchQuery.isNotEmpty) _buildNoResultsFound(),
      ],
    );
  }

  Widget _buildModernSummaryCard(Map<String, dynamic> stats) {
    final totalWeeks = stats['totalWeeks'] ?? 0;
    final compensatedWeeks = stats['compensatedWeeks'] ?? 0;
    final activeWeeks = stats['activeWeeks'] ?? 0;
    final activeCount = (stats['activeCount'] ?? 0) as int;
    final compensatedCount = (stats['compensatedCount'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade400,
            Colors.teal.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModernStatItem(
                  icon: Icons.warning_amber_rounded,
                  value: activeCount.toString(),
                  label: 'À corriger',
                  color: Colors.orange,
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildModernStatItem(
                  icon: Icons.check_circle_outline,
                  value: compensatedCount.toString(),
                  label: 'Compensées',
                  color: Colors.lightGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildModernAnomalyCard(Anomaly anomaly, bool isCompensated) {
    final dayName = DateFormat('EEEE', 'fr_FR').format(anomaly.date);
    final formattedDate = DateFormat('dd MMMM', 'fr_FR').format(anomaly.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDateCorrection(context, anomaly.date),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône et indicateur de statut
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCompensated ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompensated ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: isCompensated ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dayName.substring(0, 1).toUpperCase() + dayName.substring(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        anomaly.message,
                        style: TextStyle(
                          color: isCompensated ? Colors.grey : Colors.black87,
                          fontSize: 14,
                          decoration: isCompensated ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (isCompensated && anomaly.compensationReason != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                anomaly.compensationReason!,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Flèche
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDateCorrection(BuildContext context, DateTime date) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Détails du pointage'),
            backgroundColor: Colors.teal,
          ),
          body: SingleChildScrollView(
            child: PointageWidget(
              entry: null,
              selectedDate: date,
            ),
          ),
        ),
      ),
    )
        .then(
      (value) {
        if (mounted) {
          context.read<AnomalyBloc>().add(const DetectAnomalies());
        }
      },
    );
  }

  Map<String, List<Anomaly>> _groupAnomaliesByWeek(
    List<Anomaly> activeAnomalies,
    List<Anomaly> compensatedAnomalies,
  ) {
    final grouped = <String, List<Anomaly>>{};

    // Grouper toutes les anomalies
    final allAnomalies = [...activeAnomalies, ...compensatedAnomalies];

    for (var anomaly in allAnomalies) {
      final weekKey = anomaly.weekReference ?? _getWeekKey(anomaly.date);
      grouped.putIfAbsent(weekKey, () => []);
      grouped[weekKey]!.add(anomaly);
    }

    // Trier les semaines par date décroissante
    final sortedEntries = grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return Map.fromEntries(sortedEntries);
  }

  String _getWeekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final weekNumber = _getWeekNumber(monday);
    return '${monday.year}-${weekNumber.toString().padLeft(2, '0')}';
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }

  Widget _buildWeekSection(String weekKey, List<Anomaly> anomalies) {
    // Parser la semaine pour obtenir la date
    final parts = weekKey.split('-');
    final year = int.parse(parts[0]);
    final week = int.parse(parts[1]);

    // Calculer les dates de début et fin de semaine
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysToFirstMonday = (8 - firstDayOfYear.weekday) % 7;
    final firstMonday = firstDayOfYear.add(Duration(days: daysToFirstMonday));
    final weekStart = firstMonday.add(Duration(days: (week - 1) * 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final formattedPeriod =
        '${DateFormat('dd MMM', 'fr_FR').format(weekStart)} - ${DateFormat('dd MMM', 'fr_FR').format(weekEnd)}';

    // Séparer les anomalies actives et compensées
    final activeCount = anomalies.where((a) => !a.isCompensated).length;
    final compensatedCount = anomalies.where((a) => a.isCompensated).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de la semaine
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Semaine $week',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formattedPeriod,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (activeCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '$activeCount',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (compensatedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '$compensatedCount',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Liste des anomalies de la semaine
        ...anomalies.map((anomaly) => _buildModernAnomalyCard(anomaly, anomaly.isCompensated)),
      ],
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune anomalie trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres termes de recherche',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
