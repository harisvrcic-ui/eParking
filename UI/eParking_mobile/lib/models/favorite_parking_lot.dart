class FavoriteParkingLot {
  final int id;
  final int userId;
  final int parkingLotId;
  final String parkingLotName;
  final DateTime createdAt;

  FavoriteParkingLot({
    required this.id,
    required this.userId,
    required this.parkingLotId,
    required this.parkingLotName,
    required this.createdAt,
  });

  factory FavoriteParkingLot.fromJson(Map<String, dynamic> json) {
    return FavoriteParkingLot(
      id: json['id'] as int,
      userId: json['userId'] as int,
      parkingLotId: json['parkingLotId'] as int,
      parkingLotName: json['parkingLotName']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}
