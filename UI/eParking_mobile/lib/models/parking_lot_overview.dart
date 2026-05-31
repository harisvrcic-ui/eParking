import 'parking_lot.dart';

class ParkingLotOverview {
  final int id;
  final String name;
  final int totalSpots;
  final int availableSpots;
  final int zoneCount;
  final String status;
  final bool isActive;
  final double? latitude;
  final double? longitude;

  ParkingLotOverview({
    required this.id,
    required this.name,
    required this.totalSpots,
    required this.availableSpots,
    required this.zoneCount,
    required this.status,
    required this.isActive,
    this.latitude,
    this.longitude,
  });

  factory ParkingLotOverview.fromJson(Map<String, dynamic> json) {
    return ParkingLotOverview(
      id: json['id'] as int,
      name: json['name'] as String,
      totalSpots: json['totalSpots'] as int? ?? 0,
      availableSpots: json['availableSpots'] as int? ?? 0,
      zoneCount: json['zoneCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'Active',
      isActive: json['isActive'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  ParkingLot toParkingLot() => ParkingLot(
        id: id,
        name: name,
        numberOfSpots: totalSpots,
        status: status,
        isActive: isActive,
        zoneCount: zoneCount,
      );
}
