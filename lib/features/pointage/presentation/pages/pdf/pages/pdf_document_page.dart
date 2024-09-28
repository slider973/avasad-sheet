import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/bloc/pdf_bloc.dart';
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
    context.read<PdfBloc>().add(LoadGeneratedPdfsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PdfBloc, PdfState>(
      listener: (context, state) {
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
          return PdfDocumentLayout(
            pdfs: state.pdfs,
            onGenerateCurrentMonth: () => context
                .read<PdfBloc>()
                .add(GeneratePdfEvent(DateTime.now().month)),
            onChooseMonth: () => showMonthPicker(context),
            onOpenPdf: (filePath) =>
                context.read<PdfBloc>().add(OpenPdfEvent(filePath)),
            onDeletePdf: (id) =>
                context.read<PdfBloc>().add(DeletePdfEvent(id)),
          );
        } else if (state is PdfGenerationError || state is PdfOpenError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Erreur: ${(state as dynamic).error}'),
                ElevatedButton(
                  onPressed: () => context.read<PdfBloc>().add(LoadGeneratedPdfsEvent()),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else if (state is PdfOpening) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(child: Text('Aucun PDF généré'));
      },
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage, {required bool isPdfGeneration}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPdfGeneration ? 'Erreur de génération du PDF' : 'Erreur d\'ouverture du PDF'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (isPdfGeneration)
              TextButton(
                child: const Text('Réessayer'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<PdfBloc>().add(GeneratePdfEvent(DateTime.now().month));
                },
              ),
          ],
        );
      },
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
      // Si une exception est levée, cela signifie que le fichier est probablement ouvert par une autre application
      return true;
    }
  }

}
