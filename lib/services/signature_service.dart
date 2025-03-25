// lib/services/signature_service.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/signature.dart';
import 'storage_service.dart';
import 'package:path/path.dart' as p;
import '../widgets/signature_pad.dart';

class SignatureService {
  /// Open a full-screen signature pad and return the captured signature
  static Future<Signature?> captureSignature(BuildContext context) async {
    // Push a standard MaterialPageRoute that returns Uint8List? of PNG bytes
    final Uint8List? bytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (ctx) => const SignaturePadPage(),
      ),
    );

    if (bytes == null) {
      // User canceled or no signature
      return null;
    }
    // Save signature image bytes to file
    final file = await StorageService.saveBytes(bytes, StorageFolder.signature);
    return Signature(filePath: file.path);
  }
}

/// A standard Widget screen that shows an AppBar + your [SignaturePad].
class SignaturePadPage extends StatelessWidget {
  const SignaturePadPage({Key? key}) : super(key: key);

  // Called when user taps 'Done' on your signature pad
  Future<void> _onSignatureDone(BuildContext context, ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Signature'),
      ),
      body: SignaturePad(
        onDone: (ui.Image image) => _onSignatureDone(context, image),
      ),
    );
  }
}
