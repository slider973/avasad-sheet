
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:time_sheet/features/time_sheet/presentation/pages/pdf/bloc/pdf_bloc.dart';


import '../widgets/adaptive_boutton.dart';



class PdfDocument extends StatelessWidget {
  const PdfDocument({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Generator"),
      ),
      body: Center(
        child: AdaptiveButton(
          onPressed: () {
            // generatePdf(); // Générer le PDF
            context.read<PdfBloc>().add(GeneratePdfEvent(DateTime.now().month));
          },
          text: 'Générer PDF', // Texte du bouton
        ),
      )
    );
  }
}
