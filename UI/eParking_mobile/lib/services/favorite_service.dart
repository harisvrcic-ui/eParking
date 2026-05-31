import '../core/api_client.dart';
import '../models/favorite_parking_lot.dart';

class FavoriteService {
  final ApiClient _api = ApiClient();

  Future<List<FavoriteParkingLot>> getMy() async {
    final data = await _api.getList('/FavoriteParkingLots/my');
    return data
        .map((e) => FavoriteParkingLot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FavoriteParkingLot?> findForLot(int parkingLotId) async {
    final data = await _api.getList(
      '/FavoriteParkingLots/my',
      query: {'parkingLotId': '$parkingLotId', 'pageSize': '1'},
    );
    if (data.isEmpty) return null;
    return FavoriteParkingLot.fromJson(data.first as Map<String, dynamic>);
  }

  Future<FavoriteParkingLot> add(int parkingLotId) async {
    final result = await _api.post('/FavoriteParkingLots/my', {
      'parkingLotId': parkingLotId,
    });
    return FavoriteParkingLot.fromJson(result as Map<String, dynamic>);
  }

  Future<void> remove(int favoriteId) async {
    await _api.delete('/FavoriteParkingLots/my/$favoriteId');
  }
}
