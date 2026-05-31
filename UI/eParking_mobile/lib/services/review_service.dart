import '../core/api_client.dart';
import '../models/review.dart';

class ReviewService {
  final ApiClient _api = ApiClient();

  Future<List<Review>> getForParkingLot(int parkingLotId) async {
    final data = await _api.getList(
      '/Reviews',
      query: {'parkingLotId': '$parkingLotId'},
    );
    return data
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Review> create({
    required int parkingLotId,
    required int rating,
    String? comment,
  }) async {
    final result = await _api.post('/Reviews/my', {
      'parkingLotId': parkingLotId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
    return Review.fromJson(result as Map<String, dynamic>);
  }

  Future<Review> update({
    required int id,
    required int parkingLotId,
    required int rating,
    String? comment,
  }) async {
    final result = await _api.put('/Reviews/my/$id', {
      'parkingLotId': parkingLotId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
    return Review.fromJson(result as Map<String, dynamic>);
  }
}
