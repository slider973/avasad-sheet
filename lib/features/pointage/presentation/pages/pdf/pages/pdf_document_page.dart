import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
    return BlocBuilder<PdfBloc, PdfState>(
      builder: (context, state) {
        print(state);
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
        } else if (state is PdfLoadError) {
          return Center(child: Text('Erreur de chargement: ${state.error}'));
        } else if (state is PdfOpened) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => PdfViewerPage(filePath: state.filePath),
              ),
            );
          });
          return const Center(child: Text("Ouverture du PDF"));
        } else if (state is PdfDeleteError) {
          return Center(child: Text('Erreur de suppression: ${state.error}'));
        } else if (state is PdfOpening) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is PdfOpenError) {
          return Center(child: Text('Erreur d\'ouverture: ${state.error}'));
        }
        return const Center(child: Text('Aucun PDF généré'));
      },
    );
  }
}