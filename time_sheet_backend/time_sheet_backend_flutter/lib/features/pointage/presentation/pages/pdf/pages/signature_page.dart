import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignatureScreen extends StatefulWidget {
  final Function(Uint8List) onSigned;

  const SignatureScreen({super.key, required this.onSigned});

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signer le document')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Signature(
              controller: _controller,
              width: double.infinity,
              height: 300,
              backgroundColor: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                child: Text('Effacer'),
                onPressed: () {
                  _controller.clear();
                },
              ),
              ElevatedButton(
                child: Text('Sauvegarder'),
                onPressed: () async {
                  if (_controller.isNotEmpty) {
                    final Uint8List? data = await _controller.toPngBytes();
                    if (data != null) {
                      widget.onSigned(data);
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
