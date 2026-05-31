class Review {
  final int id;
  final int userId;
  final String userFullName;
  final int parkingLotId;
  final String parkingLotName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.parkingLotId,
    required this.parkingLotName,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userFullName: json['userFullName'] as String? ?? '',
      parkingLotId: json['parkingLotId'] as int,
      parkingLotName: json['parkingLotName'] as String? ?? '',
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
