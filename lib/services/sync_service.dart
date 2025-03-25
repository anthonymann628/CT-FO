import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_state.dart';
import '../models/barcode_scan.dart';
import '../models/photo.dart';
import '../models/signature.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class SyncService {
  // Download route data from API and save to local database
  static Future<List<Stop>?> fetchRoute() async {
    try {
      final url = Uri.parse(Constants.apiBaseUrl + Constants.routeEndpoint);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> stopsData;
        int routeId = 0;
        if (data is List) {
          stopsData = data;
        } else if (data is Map) {
          routeId = data['routeId'] is int ? data['routeId'] : int.tryParse(data['routeId']?.toString() ?? '') ?? 0;
          stopsData = data['stops'] is List ? data['stops'] : [];
        } else {
          stopsData = [];
        }
        List<Stop> stops = [];
        for (var item in stopsData) {
          if (item is Map) {
            int stopId = item['id'] is int ? item['id'] : int.tryParse(item['id']?.toString() ?? '') ?? 0;
            String name = item['name']?.toString() ?? 'Stop $stopId';
            String address = item['address']?.toString() ?? '';
            int rid = routeId;
            if (rid == 0) {
              rid = item['routeId'] is int ? item['routeId'] : int.tryParse(item['routeId']?.toString() ?? '') ?? 0;
            }
            int seq = item['sequence'] is int ? item['sequence'] : int.tryParse(item['sequence']?.toString() ?? '') ?? (stops.length + 1);
            stops.add(Stop(id: stopId, routeId: rid, sequence: seq, name: name, address: address));
          }
        }
        if (stops.isNotEmpty) {
          await DatabaseService.clearAllData();
          await DatabaseService.insertStops(stops);
        }
        return stops;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sync all delivered stops that have not been synced yet
  static Future<bool> syncPendingData() async {
    try {
      List<Stop> allStops = await DatabaseService.getStops();
      List<Stop> pending = allStops.where((s) => s.delivered && !s.synced).toList();
      bool allSuccessful = true;
      for (Stop stop in pending) {
        try {
          await syncStopData(stop);
        } catch (_) {
          allSuccessful = false;
        }
      }
      return allSuccessful;
    } catch (e) {
      return false;
    }
  }

  // Sync a single stop's delivery data
  static Future<void> syncStopData(Stop stop) async {
    if (!stop.delivered) return;
    final url = Uri.parse(Constants.apiBaseUrl + Constants.syncEndpoint);
    final request = http.MultipartRequest('POST', url);
    // Text fields
    request.fields['stopId'] = stop.id.toString();
    request.fields['routeId'] = stop.routeId.toString();
    request.fields['deliveredAt'] = stop.deliveredAt?.toIso8601String() ?? DateTime.now().toIso8601String();
    if (stop.latitude != null && stop.longitude != null) {
      request.fields['latitude'] = stop.latitude.toString();
      request.fields['longitude'] = stop.longitude.toString();
    }
    if (stop.scans.isNotEmpty) {
      request.fields['barcodes'] = stop.scans.map((e) => e.code).join(',');
    }
    if (stop.signature != null) {
      request.fields['signerName'] = stop.signature!.signerName ?? '';
    }
    // File attachments
    for (int i = 0; i < stop.photos.length; i++) {
      final photoPath = stop.photos[i].filePath;
      if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('photo${i+1}', photoPath));
      }
    }
    if (stop.signature != null && File(stop.signature!.filePath).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath('signature', stop.signature!.filePath));
    }
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200 || response.statusCode == 201) {
      stop.synced = true;
      await DatabaseService.updateStopDelivered(stop);
    } else {
      throw Exception('Failed to sync stop ${stop.id}');
    }
  }
}
