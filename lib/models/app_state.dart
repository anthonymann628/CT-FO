import 'package:flutter/foundation.dart';
import 'barcode_scan.dart';
import 'photo.dart';
import 'signature.dart';

class Stop {
  int id;
  int routeId;
  int sequence;
  String name;
  String address;
  bool delivered;
  bool synced;
  DateTime? deliveredAt;
  double? latitude;
  double? longitude;
  List<BarcodeScan> scans;
  List<Photo> photos;
  Signature? signature;

  Stop({
    required this.id,
    required this.routeId,
    required this.sequence,
    required this.name,
    required this.address,
    this.delivered = false,
    this.synced = false,
    this.deliveredAt,
    this.latitude,
    this.longitude,
    List<BarcodeScan>? scans,
    List<Photo>? photos,
    this.signature,
  })  : scans = scans ?? [],
        photos = photos ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'sequence': sequence,
      'name': name,
      'address': address,
      'delivered': delivered ? 1 : 0,
      'synced': synced ? 1 : 0,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      id: map['id'] as int,
      routeId: map['routeId'] as int,
      sequence: map['sequence'] as int,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      delivered: (map['delivered'] ?? 0) == 1,
      synced: (map['synced'] ?? 0) == 1,
      deliveredAt: map['deliveredAt'] != null ? DateTime.tryParse(map['deliveredAt']) : null,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    );
  }
}

class AppState extends ChangeNotifier {
  List<Stop> stops = [];
  bool routeLoaded = false;

  void setStops(List<Stop> newStops) {
    stops = newStops;
    routeLoaded = newStops.isNotEmpty;
    notifyListeners();
  }

  void markStopDelivered(int stopId, {DateTime? deliveredAt, double? lat, double? lng}) {
    try {
      Stop stop = stops.firstWhere((s) => s.id == stopId);
      stop.delivered = true;
      stop.deliveredAt = deliveredAt ?? DateTime.now();
      stop.latitude = lat;
      stop.longitude = lng;
      notifyListeners();
    } catch (_) {
      // Stop not found
    }
  }

  void addBarcodeScan(int stopId, BarcodeScan scan) {
    try {
      Stop stop = stops.firstWhere((s) => s.id == stopId);
      stop.scans.add(scan);
      notifyListeners();
    } catch (_) {
      // Stop not found
    }
  }

  void addPhoto(int stopId, Photo photo) {
    try {
      Stop stop = stops.firstWhere((s) => s.id == stopId);
      stop.photos.add(photo);
      notifyListeners();
    } catch (_) {
      // Stop not found
    }
  }

  void setSignature(int stopId, Signature signature) {
    try {
      Stop stop = stops.firstWhere((s) => s.id == stopId);
      stop.signature = signature;
      notifyListeners();
    } catch (_) {
      // Stop not found
    }
  }
}
