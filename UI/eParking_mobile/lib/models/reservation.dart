class Reservation {
  final int id;
  final int parkingLotId;
  final String parkingLotName;
  final String parkingSpotDisplayName;
  final String carModel;
  final String licensePlate;
  final DateTime startDate;
  final DateTime endDate;
  final double finalPrice;
  final DateTime createdAt;
  final String status;
  final String? statusNote;

  Reservation({
    required this.id,
    required this.parkingLotId,
    required this.parkingLotName,
    required this.parkingSpotDisplayName,
    required this.carModel,
    required this.licensePlate,
    required this.startDate,
    required this.endDate,
    required this.finalPrice,
    required this.createdAt,
    required this.status,
    this.statusNote,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      parkingLotId: json['parkingLotId'] as int? ?? 0,
      parkingLotName: json['parkingLotName'] as String? ?? '',
      parkingSpotDisplayName: json['parkingSpotDisplayName'] as String? ?? '',
      carModel: json['carModel'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['startDate'] as String),
      status: json['status'] as String? ?? 'Pending',
      statusNote: json['statusNote'] as String?,
    );
  }

  bool get isCancelled => status == 'Cancelled';
  bool get isCompleted => status == 'Completed' || endDate.isBefore(DateTime.now());
  bool get isPending => status == 'Pending';
  bool get isConfirmed => status == 'Confirmed';

  String get locationTitle {
    if (parkingSpotDisplayName.isNotEmpty) return parkingSpotDisplayName;
    return parkingLotName;
  }

  String get carLabel {
    final model = carModel.trim();
    final plate = licensePlate.trim();
    if (model.isNotEmpty && plate.isNotEmpty) return '$model ($plate)';
    if (model.isNotEmpty) return model;
    return plate;
  }

  bool get isActive =>
      !isCancelled && !isCompleted && endDate.isAfter(DateTime.now());
}
