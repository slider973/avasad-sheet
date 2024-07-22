import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_file/open_file.dart';

import '../bloc/pdf_bloc.dart';

class PdfViewerPage extends StatelessWidget {
  final String filePath;

  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Vérifier si nous sommes sur Windows
    if (!kIsWeb && Platform.isWindows) {
      // Sur Windows, ouvrir le PDF avec l'application par défaut
      OpenFile.open(filePath);
      // Fermer cette page immédiatement
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
      return const Scaffold(
        body: Center(child: Text('Ouverture du PDF avec l\'application par défaut...')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if(didPop) return;
        context.read<PdfBloc>().add(ClosePdfEvent());
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Visualiseur PDF'),
        ),
        body: PDFView(
          filePath: filePath,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: false,
          onRender: (_pages) {
            // Vous pouvez ajouter une logique ici si nécessaire
          },
          onError: (error) {
            print(error.toString());
          },
          onPageError: (page, error) {
            print('$page: ${error.toString()}');
          },
          onViewCreated: (PDFViewController pdfViewController) {
            // Vous pouvez stocker le contrôleur si nécessaire
          },
        ),
      ),
    );
  }
}
