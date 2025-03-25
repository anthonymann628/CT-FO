import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/barcode_scan.dart';
import '../widgets/barcode_scanner_viewfinder.dart';
import 'navigation_service.dart';
import '../utils/permissions.dart';

class ScanService {
  static Future<BarcodeScan?> scanBarcode() async {
    bool granted = await Permissions.ensureCameraPermission();
    if (!granted) return null;
    // Open scanner page and wait for result
    return await NavigationService.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => _BarcodeScannerPage()),
    );
  }
}

class _BarcodeScannerPage extends StatefulWidget {
  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _flashOn = false;
  bool _scanned = false;

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
      _controller.toggleTorch();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          )
        ],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            onDetect: (barcode, args) {
              if (_scanned) return;
              final String? value = barcode.rawValue;
              if (value != null) {
                _scanned = true;
                final type = barcode.format.toString();
                final result = BarcodeScan(code: value, type: type);
                Navigator.of(context).pop(result);
              }
            },
          ),
          Center(child: BarcodeScannerViewfinder()),
        ],
      ),
    );
  }
}
