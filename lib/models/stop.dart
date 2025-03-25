// lib/models/stop.dart
class Stop {
  final String id;
  final String address;
  double? latitude;
  double? longitude;
  int sequence;
  bool completed;
  bool uploaded;

  // Proof data
  List<String> barcodes;
  String? photoPath;
  String? signaturePath;
  DateTime? completedAt;

  Stop({
    required this.id,
    required this.address,
    this.latitude,
    this.longitude,
    this.sequence = 0,
    this.completed = false,
    this.uploaded = false,
    List<String>? barcodes,
    this.photoPath,
    this.signaturePath,
    this.completedAt,
  }) : barcodes = barcodes ?? [];

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'].toString(),
      address: json['address'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      sequence: json['sequence'] ?? 0,
      completed: json['completed'] ?? false,
      uploaded: json['uploaded'] ?? false,
      barcodes: (json['barcodes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      photoPath: json['photoPath'],
      signaturePath: json['signaturePath'],
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
      'completed': completed,
      'uploaded': uploaded,
      'barcodes': barcodes,
      'photoPath': photoPath,
      'signaturePath': signaturePath,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  bool get isFullyComplete {
    // Example logic if barcodes, photo, signature are all required
    return completed &&
        barcodes.isNotEmpty &&
        photoPath != null &&
        signaturePath != null;
  }
}
