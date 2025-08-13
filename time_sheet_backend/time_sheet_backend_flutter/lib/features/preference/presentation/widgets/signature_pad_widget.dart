import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(Uint8List) onSignatureComplete;

  const SignaturePadWidget({
    super.key,
    required this.onSignatureComplete,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Signature(
            controller: _controller,
            backgroundColor: Colors.white,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  _controller.clear();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_controller.isNotEmpty) {
                    final Uint8List? data = await _controller.toPngBytes();
                    if (data != null) {
                      widget.onSignatureComplete(data);
                    }
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}