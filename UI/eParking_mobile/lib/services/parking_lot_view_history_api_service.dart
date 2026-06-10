import '../core/api_client.dart';
import '../models/parking_lot_view_history.dart';

class ParkingLotViewHistoryApiService {
  final ApiClient _api = ApiClient();

  Future<List<ParkingLotViewHistoryEntry>> getMy() async {
    final data = await _api.getList('/ParkingLotViewHistories/my');
    return data
        .map((e) => ParkingLotViewHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Map<int, int> toViewCountByLotId(
    List<ParkingLotViewHistoryEntry> entries,
  ) {
    return {
      for (final entry in entries) entry.parkingLotId: entry.viewCount,
    };
  }
}
