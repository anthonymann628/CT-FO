import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/photo_service.dart';
import '../services/scan_service.dart';
import '../services/signature_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/sync_service.dart';
import '../widgets/stop_list_item.dart';

class RouteDetailsScreen extends StatefulWidget {
  const RouteDetailsScreen({Key? key}) : super(key: key);
  @override
  _RouteDetailsScreenState createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  bool _processing = false;

  Future<void> _completeStop(Stop stop) async {
    if (_processing || stop.delivered) return;
    setState(() {
      _processing = true;
    });
    try {
      // Scan barcode
      BarcodeScan? scanResult = await ScanService.scanBarcode();
      if (scanResult == null) return;
      // Take photo
      Photo? photo = await PhotoService.takePhoto();
      if (photo == null) return;
      // Capture signature
      Signature? signature = await SignatureService.captureSignature(context);
      if (signature == null) return;
      // Assign stopId and routeId to captured data
      scanResult.stopId = stop.id;
      scanResult.routeId = stop.routeId;
      photo.stopId = stop.id;
      photo.routeId = stop.routeId;
      signature.stopId = stop.id;
      signature.routeId = stop.routeId;
      // Save data to database
      await DatabaseService.insertBarcodeScan(scanResult);
      await DatabaseService.insertPhoto(photo);
      await DatabaseService.insertSignature(signature);
      // Mark stop as delivered with current time and location
      DateTime now = DateTime.now();
      double? lat;
      double? lng;
      try {
        final pos = await LocationService.getCurrentLocation();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}
      stop.delivered = true;
      stop.deliveredAt = now;
      stop.latitude = lat;
      stop.longitude = lng;
      await DatabaseService.updateStopDelivered(stop);
      // Update app state
      Provider.of<AppState>(context, listen: false).addBarcodeScan(stop.id, scanResult);
      Provider.of<AppState>(context, listen: false).addPhoto(stop.id, photo);
      Provider.of<AppState>(context, listen: false).setSignature(stop.id, signature);
      Provider.of<AppState>(context, listen: false).markStopDelivered(stop.id, deliveredAt: now, lat: lat, lng: lng);
      // Attempt to sync this stop immediately (non-blocking for UI)
      try {
        await SyncService.syncStopData(stop);
      } catch (_) {
        // If sync fails, it will remain unsynced for later retry
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stop "${stop.name}" completed.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to complete stop.')));
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = Provider.of<AppState>(context).stops;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Details'),
      ),
      body: ListView.builder(
        itemCount: stops.length,
        itemBuilder: (context, index) {
          final stop = stops[index];
          return StopListItem(
            stop: stop,
            onTap: () => _completeStop(stop),
            onNavigate: () {
              if (stop.address.isNotEmpty) {
                LocationService.openMap(stop.address);
              }
            },
          );
        },
      ),
    );
  }
}
