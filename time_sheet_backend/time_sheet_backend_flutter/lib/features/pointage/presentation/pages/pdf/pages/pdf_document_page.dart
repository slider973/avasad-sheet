import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/bloc/pdf/pdf_bloc.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/bloc/anomaly/anomaly_bloc.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/pdf_document_layout.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/pdf_viewer.dart';
import '../../../../../bottom_nav_tab/presentation/pages/bloc/bottom_navigation_bar_bloc.dart';

import '../../../widgets/pdf_document/show_month_picker.dart';

class PdfDocumentPage extends StatefulWidget {
  const PdfDocumentPage({super.key});

  @override
  _PdfDocumentPageState createState() => _PdfDocumentPageState();
}

class _PdfDocumentPageState extends State<PdfDocumentPage> {
  StreamSubscription<PdfState>? _pdfBlocSubscription;
  Timer? _fileCheckTimer;

  @override
  void initState() {
    super.initState();
    _pdfBlocSubscription = context.read<PdfBloc>().stream.listen((state) {
      if (state is PdfGenerated && mounted) {
        // Forcer une reconstruction de l'interface
        setState(() {});
      }
    });
    context.read<PdfBloc>().add(LoadGeneratedPdfsEvent());
    _detectAnomalies();
  }

  @override
  void dispose() {
    _pdfBlocSubscription?.cancel();
    _fileCheckTimer?.cancel();
    super.dispose();
  }

  void _detectAnomalies() {
    context.read<AnomalyBloc>().add(const DetectAnomalies());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: BlocConsumer<PdfBloc, PdfState>(
            listener: (context, state) {
              print('PDF STATE: $state');
              if (state is PdfGenerationError) {
                _showErrorDialog(context, state.error, isPdfGeneration: true);
              } else if (state is PdfOpenError) {
                _showErrorDialog(context, state.error, isPdfGeneration: false);
              } else if (state is PdfOpened) {
                _handlePdfOpened(context, state.filePath);
              }
            },
            builder: (context, state) {
              if (state is PdfLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is PdfListLoaded) {
                return _buildMainContent(context, state);
              } else if (state is PdfGenerationError || state is PdfOpenError) {
                return _buildErrorView(context, (state as dynamic).error);
              }

              // Gestion de l'animation avec FutureBuilder
              return FutureBuilder(
                future: Future.delayed(const Duration(seconds: 10)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Center(
                      child: Lottie.asset(
                        'assets/animation/pdfGeneration.json',
                        width: 300,
                        height: 300,
                      ),
                    );
                  }
                  // Afficher un indicateur de chargement avant l'animation
                  return Center(
                    child: Lottie.asset(
                      'assets/animation/pdfGeneration.json',
                      width: 300,
                      height: 300,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, PdfListLoaded state) {
    return PdfDocumentLayout(
      pdfs: state.pdfs,
      onGenerateCurrentMonth: () => _showConfirmationDialog(context),
      onChooseMonth: () => showMonthPicker(context),
      onGenerateCurrentMonthExcel: () => _showConfirmationDialogExcel(context),
      onChooseMonthExcel: () => _showMonthPickerExcel(context),
      onOpenPdf: (filePath) => context.read<PdfBloc>().add(OpenPdfEvent(filePath)),
      onDeletePdf: (id) => context.read<PdfBloc>().add(DeletePdfEvent(id)),
    );
  }

  Widget _buildAnomaliesSection() {
    return BlocBuilder<AnomalyBloc, AnomalyState>(
      builder: (context, state) {
        return Container(
          height: 200,
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          color: Colors.grey[200],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Anomalies détectées:', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: _buildAnomaliesList(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnomaliesList(AnomalyState state) {
    if (state is AnomalyLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is AnomalyDetected) {
      return state.anomalies.isEmpty
          ? const Center(child: Text('Aucune anomalie détectée.'))
          : ListView.builder(
              shrinkWrap: true,
              itemCount: state.anomalies.length,
              itemBuilder: (context, index) {
                return Text('• ${state.anomalies[index]}');
              },
            );
    } else if (state is AnomalyError) {
      return Text('Erreur : ${state.message}');
    }
    return const Text('Erreur inconnue');
  }

  void _showConfirmationDialog(BuildContext context) {
    // Déterminer le mois et l'année à vérifier
    final month = DateTime.now().day > 21 ? DateTime.now().month + 1 : DateTime.now().month;
    final year = DateTime.now().year;

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
              ...state.criticalAnomaliesMessages.map(
                (message) => Padding(
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
              ...state.minorAnomaliesMessages.take(3).map(
                    (message) => Padding(
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
            BlocProvider.of<BottomNavigationBarBloc>(context).add(BottomNavigationBarEvent.tab4);
          },
        ),
      ],
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage, {required bool isPdfGeneration}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPdfGeneration ? 'Erreur de génération du PDF' : 'Erreur d\'ouverture du PDF'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (isPdfGeneration)
              TextButton(
                child: const Text('Réessayer'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<PdfBloc>().add(GeneratePdfEvent(DateTime.now().month, DateTime.now().year));
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Erreur: $error'),
          ElevatedButton(
            onPressed: () => context.read<PdfBloc>().add(LoadGeneratedPdfsEvent()),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _handlePdfOpened(BuildContext context, String filePath) {
    // Vérifier si c'est un fichier Excel
    if (filePath.endsWith('.xlsx') || filePath.endsWith('.xls')) {
      // Stocker la référence au bloc avant l'appel asynchrone
      final pdfBloc = context.read<PdfBloc>();
      // Ouvrir directement avec l'application par défaut du système
      OpenFile.open(filePath).then((_) {
        // Fermer l'état après avoir ouvert le fichier Excel
        if (mounted) {
          pdfBloc.add(ClosePdfEvent());
        }
      });
      return;
    }

    // Pour les fichiers PDF
    if (!kIsWeb && Platform.isWindows) {
      OpenFile.open(filePath).then((_) {
        _fileCheckTimer?.cancel(); // Annuler tout timer existant
        _fileCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          if (!_isFileOpen(filePath)) {
            timer.cancel();
            context.read<PdfBloc>().add(ClosePdfEvent());
          }
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerPage(filePath: filePath),
          ),
        );
      });
    }
  }

  bool _isFileOpen(String filePath) {
    try {
      final file = File(filePath);
      final randomAccessFile = file.openSync(mode: FileMode.read);
      randomAccessFile.closeSync();
      return false;
    } on FileSystemException {
      return true;
    }
  }

  void _showConfirmationDialogExcel(BuildContext context) {
    // Déterminer le mois et l'année à vérifier
    final month = DateTime.now().day > 21 ? DateTime.now().month + 1 : DateTime.now().month;
    final year = DateTime.now().year;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Générer Excel'),
          content: Text('Voulez-vous générer le fichier Excel pour le mois actuel ?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Générer'),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<PdfBloc>().add(GenerateExcelEvent(month, year));
              },
            ),
          ],
        );
      },
    );
  }

  void _showMonthPickerExcel(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedMonth = DateTime.now().month;
        int selectedYear = DateTime.now().year;

        return AlertDialog(
          title: const Text('Choisir le mois (Excel)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: selectedMonth,
                items: List.generate(12, (index) {
                  final monthNames = [
                    'Janvier',
                    'Février',
                    'Mars',
                    'Avril',
                    'Mai',
                    'Juin',
                    'Juillet',
                    'Août',
                    'Septembre',
                    'Octobre',
                    'Novembre',
                    'Décembre'
                  ];
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(monthNames[index]),
                  );
                }),
                onChanged: (value) {
                  selectedMonth = value!;
                },
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  selectedYear = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Générer'),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<PdfBloc>().add(GenerateExcelEvent(selectedMonth, selectedYear));
              },
            ),
          ],
        );
      },
    );
  }
}
