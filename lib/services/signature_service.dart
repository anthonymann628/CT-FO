import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/signature.dart';
import 'storage_service.dart';
import '../widgets/signature_pad.dart';

class SignatureService {
  // Open a full-screen signature pad and return the captured signature
  static Future<Signature?> captureSignature(BuildContext context) async {
    final bytes = await Navigator.of(context).push(UiSignaturePadRoute());
    if (bytes == null) return null;
    // Save signature image bytes to file
    final file = await StorageService.saveBytes(bytes, StorageFolder.signature);
    return Signature(filePath: file.path);
  }
}

// Custom page route for signature pad screen
class UiSignaturePadRoute extends PageRoute<void> {
  @override
  Color get barrierColor => Colors.black54;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => 'SignaturePad';
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Signature')),
      body: SignaturePad(onDone: (ui.Image image) async {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Navigator.of(context).pop(byteData?.buffer.asUint8List());
      }),
    );
  }
}
