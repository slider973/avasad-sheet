import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/bloc/pdf/pdf_bloc.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/bloc/anomaly/anomaly_bloc.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/pdf_document_layout.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/pdf_viewer.dart';

import '../../../widgets/pdf_document/show_month_picker.dart';

class PdfDocumentPage extends StatefulWidget {
  @override
  _PdfDocumentPageState createState() => _PdfDocumentPageState();
}

class _PdfDocumentPageState extends State<PdfDocumentPage> {
  @override
  void initState() {
    super.initState();
    context.read<PdfBloc>().stream.listen((state) {
      if (state is PdfGenerated) {
        // Forcer une reconstruction de l'interface
        setState(() {});
      }
    });
    context.read<PdfBloc>().add(LoadGeneratedPdfsEvent());
    _detectAnomalies();
  }

  void _detectAnomalies() {
    final now = DateTime.now();
    context.read<AnomalyBloc>().add(DetectAnomalies(now.month, now.year));
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
              return const Center(child: Text('Aucun PDF généré'));
            },
          ),
        ),
        _buildAnomaliesSection(),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, PdfListLoaded state) {
    return PdfDocumentLayout(
      pdfs: state.pdfs,
      onGenerateCurrentMonth: () => _showConfirmationDialog(context),
      onChooseMonth: () => showMonthPicker(context),
      onOpenPdf: (filePath) =>
          context.read<PdfBloc>().add(OpenPdfEvent(filePath)),
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
              const Text('Anomalies détectées:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<AnomalyBloc, AnomalyState>(
          builder: (context, state) {
            if (state is AnomalyDetected && state.anomalies.isNotEmpty) {
              return AlertDialog(
                title: const Text('Confirmation'),
                content: const Text(
                    'Des anomalies ont été détectées. Voulez-vous quand même générer le PDF ?'),
                actions: [
                  TextButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text('Générer'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context
                          .read<PdfBloc>()
                          .add(GeneratePdfEvent(DateTime.now().month));
                    },
                  ),
                ],
              );
            } else {
              // Fermer le dialog avant de générer le PDF
              Navigator.of(context).pop();
              // Déclencher la génération du PDF après la fermeture du dialog
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context
                    .read<PdfBloc>()
                    .add(GeneratePdfEvent(DateTime.now().month));
              });
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage,
      {required bool isPdfGeneration}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPdfGeneration
              ? 'Erreur de génération du PDF'
              : 'Erreur d\'ouverture du PDF'),
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
                  context
                      .read<PdfBloc>()
                      .add(GeneratePdfEvent(DateTime.now().month));
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
            onPressed: () =>
                context.read<PdfBloc>().add(LoadGeneratedPdfsEvent()),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _handlePdfOpened(BuildContext context, String filePath) {
    if (!kIsWeb && Platform.isWindows) {
      OpenFile.open(filePath).then((_) {
        Timer.periodic(const Duration(seconds: 2), (timer) {
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
}
