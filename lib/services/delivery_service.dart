// lib/services/delivery_service.dart
import 'package:flutter/foundation.dart';
import '../models/stop.dart';
import 'api_client.dart';

class DeliveryService extends ChangeNotifier {
  Future<void> attachBarcode(Stop stop, String code) async {
    stop.barcodes.add(code);
    notifyListeners();
    // if you have DB, update it here
  }

  Future<void> attachPhoto(Stop stop, String photoPath) async {
    stop.photoPath = photoPath;
    notifyListeners();
  }

  Future<void> attachSignature(Stop stop, String signaturePath) async {
    stop.signaturePath = signaturePath;
    notifyListeners();
  }

  Future<void> completeStop(Stop stop) async {
    stop.completed = true;
    stop.completedAt = DateTime.now();
    try {
      await _uploadStop(stop);
      stop.uploaded = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading stop: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _uploadStop(Stop stop) async {
    final payload = stop.toJson();
    // Possibly embed base64 images if your server needs them
    await ApiClient.post('/stops/${stop.id}/complete', payload);
  }
}
