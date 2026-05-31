class UserNotification {
  UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.reservationId,
  });

  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final int? reservationId;

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      reservationId: json['reservationId'] as int?,
    );
  }
}
