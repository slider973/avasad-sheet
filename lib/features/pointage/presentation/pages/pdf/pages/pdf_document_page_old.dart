import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/bloc/pdf_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/pdf_viewer.dart';

import '../../../../../../services/logger_service.dart';

class PdfDocumentPage extends StatefulWidget {
  @override
  _PdfDocumentPageState createState() => _PdfDocumentPageState();
}

class _PdfDocumentPageState extends State<PdfDocumentPage> {
  @override
  void initState() {
    super.initState();
    // Charger la liste des PDFs générés au chargement de la page
    context.read<PdfBloc>().add(LoadGeneratedPdfsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les PDFs'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<PdfBloc>()
                        .add(GeneratePdfEvent(DateTime.now().month));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Mois actuel',
                      textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: () => _showMonthPicker(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Choisir un mois'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<PdfBloc, PdfState>(
              builder: (context, state) {
                if (state is PdfLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PdfListLoaded) {
                  return ListView.builder(
                    itemCount: state.pdfs.length,
                    itemBuilder: (context, index) {
                      final pdf = state.pdfs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          title: Text(pdf.fileName,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(pdf.generatedDate),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              context
                                  .read<PdfBloc>()
                                  .add(DeletePdfEvent(pdf.id));
                            },
                          ),
                          onTap: () {
                            logger.i('Ouverture du PDF ${pdf.filePath}');
                            context
                                .read<PdfBloc>()
                                .add(OpenPdfEvent(pdf.filePath));
                          },
                        ),
                      );
                    },
                  );
                } else if (state is PdfLoadError) {
                  return Center(
                      child: Text('Erreur de chargement: ${state.error}'));
                } else if (state is PdfOpened) {
                  // Au lieu d'ouvrir le fichier directement, nous naviguons vers PdfViewerPage
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PdfViewerPage(filePath: state.filePath),
                      ),
                    );
                  });
                  return Center(child: Text("Ouverture du PDF"));
                } else if (state is PdfDeleteError) {
                  return Center(
                      child: Text('Erreur de suppression: ${state.error}'));
                } else if (state is PdfOpening) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PdfOpenError) {
                  return Center(
                      child: Text('Erreur d\'ouverture: ${state.error}'));
                }
                return const Center(child: Text('Aucun PDF généré'));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: YearPicker(
            selectedDate: DateTime.now(),
            firstDate: DateTime(DateTime.now().year - 1),
            lastDate: DateTime(DateTime.now().year + 1),
            onChanged: (DateTime dateTime) {
              Navigator.pop(context);
              context.read<PdfBloc>().add(GeneratePdfEvent(dateTime.month));
            },
          ),
        );
      },
    );
  }
}
