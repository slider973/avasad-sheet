import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../pages/pdf/bloc/pdf/pdf_bloc.dart';
import '../../pages/pdf/bloc/anomaly/anomaly_bloc.dart';
import '../../../../bottom_nav_tab/presentation/pages/bloc/bottom_navigation_bar_bloc.dart';

void showMonthPicker(BuildContext context) {
  final currentDate = DateTime.now();
  int selectedYear = currentDate.year;
  int? selectedMonth;

  showDialog(
    context: context,
    barrierDismissible: false, // Empêche la fermeture en cliquant à l'extérieur
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Sélectionner un mois pour $selectedYear'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            selectedYear--;
                            selectedMonth = null;
                          });
                        },
                      ),
                      Text('$selectedYear', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          setState(() {
                            selectedYear++;
                            selectedMonth = null;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(12, (index) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedMonth == index + 1 ? Colors.teal : null,
                        ),
                        child: Text(DateFormat('MMM').format(DateTime(selectedYear, index + 1))),
                        onPressed: () {
                          setState(() {
                            selectedMonth = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  if (selectedMonth != null) {
                    Navigator.of(context).pop();
                    _showAnomalyCheckDialog(context, selectedMonth!, selectedYear);
                  } else {
                    // Afficher un message d'erreur si aucun mois n'est sélectionné
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un mois')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}

void _showAnomalyCheckDialog(BuildContext context, int month, int year) {
  // Déclencher la vérification des anomalies
  context.read<AnomalyBloc>().add(CheckAnomaliesForPdfGeneration(month, year));
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BlocBuilder<AnomalyBloc, AnomalyState>(
        builder: (context, state) {
          if (state is AnomalyLoading) {
            return const AlertDialog(
              title: Text('Vérification en cours...'),
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Vérification des anomalies...'),
                ],
              ),
            );
          }
          
          if (state is PdfAnomalyCheckCompleted) {
            if (state.hasAnyAnomalies) {
              return _buildAnomalyConfirmationDialog(context, state);
            } else {
              // Aucune anomalie, fermer le dialog et générer le PDF
              Navigator.of(context).pop();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<PdfBloc>().add(GeneratePdfEvent(month, year));
              });
              return const SizedBox.shrink();
            }
          }
          
          if (state is AnomalyError) {
            return AlertDialog(
              title: const Text('Erreur'),
              content: Text('Erreur lors de la vérification des anomalies: ${state.message}'),
              actions: [
                TextButton(
                  child: const Text('Fermer'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Générer quand même'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<PdfBloc>().add(GeneratePdfEvent(month, year));
                  },
                ),
              ],
            );
          }
          
          // État initial ou inattendu
          return const AlertDialog(
            title: Text('Vérification...'),
            content: Text('Préparation de la vérification...'),
          );
        },
      );
    },
  );
}

Widget _buildAnomalyConfirmationDialog(BuildContext context, PdfAnomalyCheckCompleted state) {
  return AlertDialog(
    title: Row(
      children: [
        Icon(
          state.hasCriticalAnomalies ? Icons.error : Icons.warning,
          color: state.hasCriticalAnomalies ? Colors.red : Colors.orange,
        ),
        const SizedBox(width: 8),
        Text(state.hasCriticalAnomalies ? 'Anomalies critiques détectées' : 'Anomalies détectées'),
      ],
    ),
    content: SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.hasCriticalAnomalies) ...[
            const Text(
              '🚨 Anomalies critiques:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            ...state.criticalAnomaliesMessages.map((message) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $message', style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (state.hasMinorAnomalies) ...[
            const Text(
              'ℹ️ Anomalies mineures:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            ...state.minorAnomaliesMessages.take(3).map((message) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $message', style: const TextStyle(fontSize: 12)),
              ),
            ),
            if (state.minorAnomaliesMessages.length > 3)
              Text('• ... et ${state.minorAnomaliesMessages.length - 3} autres'),
            const SizedBox(height: 16),
          ],
          Text(
            state.hasCriticalAnomalies 
              ? 'Il est recommandé de corriger les anomalies critiques avant de générer le PDF.'
              : 'Vous pouvez générer le PDF ou corriger les anomalies d\'abord.',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        child: const Text('Annuler'),
        onPressed: () => Navigator.of(context).pop(),
      ),
      if (!state.hasCriticalAnomalies || true) // Toujours permettre de générer (choix utilisateur)
        TextButton(
          child: Text(
            state.hasCriticalAnomalies ? 'Générer quand même' : 'Générer le PDF',
            style: TextStyle(
              color: state.hasCriticalAnomalies ? Colors.red : Colors.blue,
              fontWeight: state.hasCriticalAnomalies ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            context.read<PdfBloc>().add(GeneratePdfEvent(state.month, state.year));
          },
        ),
      TextButton(
        child: const Text('Voir les anomalies'),
        onPressed: () {
          Navigator.of(context).pop();
          // Naviguer vers l'onglet des anomalies (index 3)
          BlocProvider.of<BottomNavigationBarBloc>(context)
              .add(BottomNavigationBarEvent.tab4);
        },
      ),
    ],
  );
}