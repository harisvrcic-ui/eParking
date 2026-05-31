class Car {
  final int id;
  final int brandId;
  final int colorId;
  final int userId;
  final String model;
  final String licensePlate;
  final String brandName;
  final String colorName;
  final bool isActive;
  final String? picture;

  Car({
    required this.id,
    required this.brandId,
    required this.colorId,
    required this.userId,
    required this.model,
    required this.licensePlate,
    required this.brandName,
    required this.colorName,
    required this.isActive,
    this.picture,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      brandId: json['brandId'] as int,
      colorId: json['colorId'] as int,
      userId: json['userId'] as int,
      model: json['model'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
      brandName: json['brandName'] as String? ?? '',
      colorName: json['colorName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      picture: json['picture'] as String?,
    );
  }

  String get label => '$brandName $model ($licensePlate)';

  String get subtitle => '$colorName · $licensePlate';
}
