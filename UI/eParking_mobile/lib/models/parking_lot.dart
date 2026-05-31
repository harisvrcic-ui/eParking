class ParkingLot {
  final int id;
  final String name;
  final int numberOfSpots;
  final String status;
  final bool isActive;
  final int zoneCount;

  ParkingLot({
    required this.id,
    required this.name,
    required this.numberOfSpots,
    required this.status,
    required this.isActive,
    required this.zoneCount,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    return ParkingLot(
      id: json['id'] as int,
      name: json['name'] as String,
      numberOfSpots: json['numberOfSpots'] as int,
      status: json['status'] as String? ?? 'Active',
      isActive: json['isActive'] as bool? ?? true,
      zoneCount: json['zoneCount'] as int? ?? 0,
    );
  }
}

class ParkingSpotSummary {
  final int parkingLotId;
  final String parkingLotName;
  final String spotTypeName;
  final String zoneName;
  final String? displayName;

  ParkingSpotSummary({
    required this.parkingLotId,
    required this.parkingLotName,
    required this.spotTypeName,
    required this.zoneName,
    this.displayName,
  });

  factory ParkingSpotSummary.fromJson(Map<String, dynamic> json) {
    return ParkingSpotSummary(
      parkingLotId: json['parkingLotId'] as int,
      parkingLotName: json['parkingLotName'] as String? ?? '',
      spotTypeName: json['parkingSpotTypeName'] as String? ?? '',
      zoneName: json['zoneName'] as String? ?? '',
      displayName: json['displayName'] as String?,
    );
  }
}
