import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/bloc/pdf/pdf_bloc_simple.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_params.dart';
import 'package:get_it/get_it.dart';

/// Page de génération de PDF qui peut retourner les données
class PdfGenerationPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final bool returnPdfData;
  
  const PdfGenerationPage({
    super.key,
    required this.startDate,
    required this.endDate,
    this.returnPdfData = false,
  });
  
  @override
  State<PdfGenerationPage> createState() => _PdfGenerationPageState();
}

class _PdfGenerationPageState extends State<PdfGenerationPage> {
  late final PdfBlocSimple _pdfBloc;
  
  @override
  void initState() {
    super.initState();
    _pdfBloc = PdfBlocSimple(
      generatePdfUseCase: GetIt.instance<GeneratePdfUseCase>(),
    );
    
    // Générer le PDF immédiatement
    _generatePdf();
  }
  
  @override
  void dispose() {
    _pdfBloc.close();
    super.dispose();
  }
  
  void _generatePdf() {
    final params = GeneratePdfParams(
      monthNumber: widget.startDate.month,
      year: widget.startDate.year,
    );
    
    _pdfBloc.add(GeneratePdfEventSimple(params));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Génération du PDF'),
      ),
      body: BlocConsumer<PdfBlocSimple, PdfStateSimple>(
        bloc: _pdfBloc,
        listener: (context, state) {
          if (state is PdfGeneratedSimple && widget.returnPdfData) {
            // Retourner les données PDF
            final fileName = 'timesheet_${DateFormat('yyyy_MM').format(widget.startDate)}.pdf';
            Navigator.pop(context, {
              'pdfBytes': state.pdfBytes,
              'fileName': fileName,
            });
          } else if (state is PdfGenerationErrorSimple) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is PdfGeneratingSimple) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    'Génération du PDF en cours...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Période : ${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          if (state is PdfGeneratedSimple && !widget.returnPdfData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDF généré avec succès',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            );
          }
          
          return const Center(
            child: Text('Initialisation...'),
          );
        },
      ),
    );
  }
}