// lib/services/sync_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/stop.dart';          // <-- Import your unified Stop model

import 'database_service.dart';
import '../utils/constants.dart';

class SyncService {
  /// Download route data from API and save to local database
  static Future<List<Stop>?> fetchRoute() async {
    try {
      final url = Uri.parse(Constants.apiBaseUrl + Constants.routeEndpoint);
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int routeId = 0;
        List<dynamic> stopsData;

        if (data is List) {
          // The response is a list of stops
          stopsData = data;
        } else if (data is Map) {
          // Possibly a JSON object with 'routeId' and 'stops'
          routeId = data['routeId'] is int
              ? data['routeId']
              : int.tryParse(data['routeId']?.toString() ?? '') ?? 0;
          stopsData = data['stops'] is List ? data['stops'] : [];
        } else {
          // Unexpected format
          stopsData = [];
        }

        final List<Stop> stops = [];
        for (var item in stopsData) {
          if (item is Map) {
            // Convert item fields to int/string
            int stopId = item['id'] is int
                ? item['id']
                : int.tryParse(item['id']?.toString() ?? '') ?? 0;
            String name = item['name']?.toString() ?? 'Stop $stopId';
            String address = item['address']?.toString() ?? '';
            int rid = routeId;
            if (rid == 0) {
              rid = (item['routeId'] is int)
                  ? item['routeId']
                  : int.tryParse(item['routeId']?.toString() ?? '') ?? 0;
            }
            // Sequence
            int seq = (item['sequence'] is int)
                ? item['sequence']
                : int.tryParse(item['sequence']?.toString() ?? '') ??
                    (stops.length + 1);

            // Build a Stop. Note that your Stop constructor might want string IDs
            // so we convert stopId/rid to strings. Adjust as needed.
            final stop = Stop(
              id: stopId.toString(),
              routeId: rid.toString(),
              sequence: seq,
              name: name,
              address: address,
            );
            stops.add(stop);
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

  /// Sync all stops that are 'completed' but not 'uploaded'
  static Future<bool> syncPendingData() async {
    try {
      // Pull all stops from local DB
      List<Stop> allStops = await DatabaseService.getStops();
      // Filter those that are completed but not yet uploaded
      List<Stop> pending =
          allStops.where((s) => s.completed && !s.uploaded).toList();

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

  /// Sync a single stop's delivery data
  static Future<void> syncStopData(Stop stop) async {
    // If not completed, skip
    if (!stop.completed) return;

    final url = Uri.parse(Constants.apiBaseUrl + Constants.syncEndpoint);
    final request = http.MultipartRequest('POST', url);

    // Text fields
    request.fields['stopId'] = stop.id;
    request.fields['routeId'] = stop.routeId;
    // If completedAt is null, send current time
    request.fields['completedAt'] =
        stop.completedAt?.toIso8601String() ?? DateTime.now().toIso8601String();

    if (stop.latitude != null && stop.longitude != null) {
      request.fields['latitude'] = stop.latitude.toString();
      request.fields['longitude'] = stop.longitude.toString();
    }

    // If your Stop has a 'barcodes' list:
    if (stop.barcodes.isNotEmpty) {
      // Just join them with commas for now
      request.fields['barcodes'] = stop.barcodes.join(',');
    }

    // If your Stop had a 'signaturePath' or 'signature object', adapt here
    // For a single photo path:
    if (stop.photoPath != null && stop.photoPath!.isNotEmpty) {
      final file = File(stop.photoPath!);
      if (file.existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('photo', file.path));
      }
    }
    // If multiple photos or a separate signature object, adapt similarly

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200 || response.statusCode == 201) {
      stop.uploaded = true;
      await DatabaseService.updateStopDelivered(stop);
    } else {
      throw Exception('Failed to sync stop ${stop.id}');
    }
  }
}
