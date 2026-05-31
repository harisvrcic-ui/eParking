class ParkingLotDetail {
  final int id;
  final String name;
  final int totalSpots;
  final int availableSpots;
  final String status;
  final double? latitude;
  final double? longitude;
  final List<ParkingZoneDetail> zones;

  ParkingLotDetail({
    required this.id,
    required this.name,
    required this.totalSpots,
    required this.availableSpots,
    required this.status,
    this.latitude,
    this.longitude,
    required this.zones,
  });

  factory ParkingLotDetail.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'] as List<dynamic>? ?? [];
    return ParkingLotDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      totalSpots: json['totalSpots'] as int? ?? 0,
      availableSpots: json['availableSpots'] as int? ?? 0,
      status: json['status'] as String? ?? 'Active',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      zones: zonesJson
          .map((z) => ParkingZoneDetail.fromJson(z as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParkingZoneDetail {
  final int id;
  final String name;
  final String? description;
  final List<ParkingSpotDetail> spots;

  ParkingZoneDetail({
    required this.id,
    required this.name,
    this.description,
    required this.spots,
  });

  factory ParkingZoneDetail.fromJson(Map<String, dynamic> json) {
    final spotsJson = json['spots'] as List<dynamic>? ?? [];
    return ParkingZoneDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      spots: spotsJson
          .map((s) => ParkingSpotDetail.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParkingSpotDetail {
  final int id;
  final String parkingNumber;
  final String? displayName;
  final String? zoneName;
  final String spotTypeName;
  final bool isAvailableNow;

  ParkingSpotDetail({
    required this.id,
    required this.parkingNumber,
    this.displayName,
    this.zoneName,
    required this.spotTypeName,
    required this.isAvailableNow,
  });

  factory ParkingSpotDetail.fromJson(Map<String, dynamic> json) {
    return ParkingSpotDetail(
      id: json['id'] as int,
      parkingNumber: json['parkingNumber'] as String? ?? '',
      displayName: json['displayName'] as String?,
      zoneName: json['zoneName'] as String?,
      spotTypeName: json['spotTypeName'] as String? ?? '',
      isAvailableNow: json['isAvailableNow'] as bool? ?? false,
    );
  }

  String get label {
    final base = displayName?.isNotEmpty == true
        ? displayName!
        : 'Mjesto $parkingNumber';
    if (zoneName != null && zoneName!.isNotEmpty) {
      return '$base · $zoneName';
    }
    return base;
  }
}
