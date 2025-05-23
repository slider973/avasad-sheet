import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/share_pdf.dart';

class PdfDocumentLayout extends StatelessWidget {
  final List<dynamic> pdfs;
  final VoidCallback onGenerateCurrentMonth;
  final VoidCallback onChooseMonth;
  final Function(String) onOpenPdf;
  final Function(int) onDeletePdf;

  const PdfDocumentLayout({
    Key? key,
    required this.pdfs,
    required this.onGenerateCurrentMonth,
    required this.onChooseMonth,
    required this.onOpenPdf,
    required this.onDeletePdf,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text('Gérer les PDFs'),
        backgroundColor: Theme.of(context).primaryColor,
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
                  onPressed: onGenerateCurrentMonth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text('Mois actuel', textAlign: TextAlign.center),
                ),
                ElevatedButton(
                  onPressed: onChooseMonth,
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
            child: ListView.builder(
              itemCount: pdfs.length,
              itemBuilder: (context, index) {
                final pdf = pdfs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    title: Text(pdf.fileName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(pdf.generatedDate)),
                    trailing: Container(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.blue),
                            onPressed: () => sharePdf(pdf.filePath),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => onDeletePdf(pdf.id),
                          ),
                        ],
                      ),
                    ),
                    onTap: () => onOpenPdf(pdf.filePath),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}