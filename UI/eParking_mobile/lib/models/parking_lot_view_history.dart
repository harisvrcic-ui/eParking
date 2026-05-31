class ParkingLotViewHistoryEntry {
  final int id;
  final int parkingLotId;
  final String parkingLotName;
  final int viewCount;
  final DateTime lastViewedAt;

  ParkingLotViewHistoryEntry({
    required this.id,
    required this.parkingLotId,
    required this.parkingLotName,
    required this.viewCount,
    required this.lastViewedAt,
  });

  factory ParkingLotViewHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ParkingLotViewHistoryEntry(
      id: json['id'] as int,
      parkingLotId: json['parkingLotId'] as int,
      parkingLotName: json['parkingLotName']?.toString() ?? '',
      viewCount: json['viewCount'] as int? ?? 0,
      lastViewedAt: DateTime.parse(json['lastViewedAt'].toString()),
    );
  }
}
