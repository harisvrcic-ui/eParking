import '../core/api_client.dart';
import '../models/news_item.dart';

class NewsService {
  final ApiClient _api = ApiClient();

  Future<List<NewsItem>> getActiveNews() async {
    final data = await _api.getList('/News');
    return data
        .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
        .where((n) => n.isActive)
        .toList();
  }

  Future<NewsItem> getById(int id) async {
    final data = await _api.get('/News/$id');
    return NewsItem.fromJson(data as Map<String, dynamic>);
  }

  /// Lista je lagana (bez base64); slike se učitavaju s detalj endpointa (RS2 8.2).
  Future<List<NewsItem>> getActiveNewsWithImages() async {
    final items = await getActiveNews();
    if (items.isEmpty) return items;

    return Future.wait(
      items.map((item) async {
        if (!item.hasImage) return item;
        try {
          final detail = await getById(item.id);
          return NewsItem(
            id: item.id,
            title: item.title,
            body: item.body,
            createdAt: item.createdAt,
            image: detail.image,
            hasImage: detail.hasImage,
            isActive: item.isActive,
          );
        } catch (_) {
          return item;
        }
      }),
    );
  }
}
