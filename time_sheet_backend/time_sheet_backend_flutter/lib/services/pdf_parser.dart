import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfDocumentParser extends PdfDocumentParserBase {
  PdfDocumentParser(super.bytes);

  Uint8List? _signatureImage;
  late pw.Document _document;

  Future<void> parseDocument(Uint8List documentBytes) async {
    print('Parsing document...');
    _document = pw.Document.load(this);
  }

  @override
  void mergeDocument(PdfDocument pdfDocument) {
    if (_signatureImage != null) {
      final signatureWidget = pw.MemoryImage(_signatureImage!);

      // Créer une nouvelle page avec le contenu existant et la signature
      final newPage = pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Contenu existant de la dernière page

              // Ajouter la signature
              pw.Positioned(
                bottom: 50,
                right: 50,
                child: pw.Image(signatureWidget, width: 100, height: 50),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  int get size => bytes.length;

  @override
  int get xrefOffset {
    // Implémentation simple pour trouver l'offset de la table xref
    final startxref = 'startxref'.codeUnits;
    for (int i = bytes.length - 1; i >= 0; i--) {
      if (bytes[i] == startxref[0]) {
        if (listEquals(bytes.sublist(i, i + startxref.length), startxref)) {
          int j = i + startxref.length;
          while (j < bytes.length && bytes[j] != 0x0A && bytes[j] != 0x0D) {
            j++;
          }
          return int.parse(String.fromCharCodes(bytes.sublist(i + startxref.length, j)));
        }
      }
    }
    throw Exception('xref offset not found');
  }

  void setSignatureImage(Uint8List signatureImage) {
    _signatureImage = signatureImage;
  }

  Future<Uint8List> save() async {
    return await _document.save();
  }
}
