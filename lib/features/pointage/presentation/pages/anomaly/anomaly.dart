import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../bottom_nav_tab/presentation/pages/bloc/bottom_navigation_bar_bloc.dart';
import '../../../data/models/anomalies/anomalies.dart';
import '../../widgets/pointage_widget/pointage_widget.dart';
import '../pdf/bloc/anomaly/anomaly_bloc.dart';
import '../time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class AnomalyView extends StatefulWidget {
  @override
  State<AnomalyView> createState() => _AnomalyViewState();
}

class _AnomalyViewState extends State<AnomalyView> {
  @override
  void initState() {
    super.initState();
    // Envoyer l'événement pour charger les anomalies
    context.read<AnomalyBloc>().add(const DetectAnomalies());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomalies'),
        backgroundColor: Colors.teal,
      ),
      body: BlocBuilder<AnomalyBloc, AnomalyState>(
        builder: (context, state) {
          if (state is AnomalyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnomalyLoaded) {
            return state.anomalies.isEmpty
                ? _buildEmptyState()
                : _buildAnomaliesList(context, state.anomalies);
          }

          if (state is AnomalyError) {
            return Center(
              child: Text(state.message),
            );
          }

          return const Center(
              child: Text('Aucune donnée à afficher pour le moment.'));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text('Aucune anomalie détectée',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAnomaliesList(BuildContext context, List<AnomalyModel> anomalies) {
    return ListView.builder(
      itemCount: anomalies.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildAnomalyCard(context, anomalies[index]),
    );
  }

  Widget _buildAnomalyCard(BuildContext context, AnomalyModel anomaly) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToCorrection(context, anomaly),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _getAnomalyColor(anomaly.type),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    anomaly.type.label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _buildStatusChip(anomaly.isResolved),
                ],
              ),
              const SizedBox(height: 8),
              Text(anomaly.description),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(anomaly.detectedDate),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isResolved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isResolved ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isResolved ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Text(
        isResolved ? 'Résolu' : 'À corriger',
        style: TextStyle(
          color: isResolved ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 12,
        ),
      ),
    );
  }

  void _navigateToCorrection(BuildContext context, AnomalyModel anomaly) {
    final dateFormat = DateFormat('dd-MMM-yy', 'en_US');
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
              entry: null, // You might need to fetch the actual entry
              selectedDate: anomaly.detectedDate,
            ),
          ),
        ),
      ),
    )
        .then(
          (value) {
        // Optionally reload anomalies or perform any other action
        context.read<AnomalyBloc>().add(const DetectAnomalies());
      },
    );
  }

  Color _getAnomalyColor(AnomalyType type) {
    switch (type) {
      case AnomalyType.insufficientHours:
        return Colors.orange;
      case AnomalyType.missingEntry:
        return Colors.red;
      case AnomalyType.invalidTimes:
        return Colors.purple;
    }
  }
}
