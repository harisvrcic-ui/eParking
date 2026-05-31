class NewsItem {
  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.image,
    this.hasImage = false,
    this.isActive = true,
  });

  final int id;
  final String title;
  final String body;
  final String? image;
  final bool hasImage;
  final DateTime createdAt;
  final bool isActive;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      image: json['image']?.toString(),
      hasImage: json['hasImage'] as bool? ?? (json['image'] != null),
      createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
