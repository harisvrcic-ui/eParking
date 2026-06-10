import '../core/api_client.dart';
import '../core/parking_data_refresh.dart';

/// Upis historije pregleda parkirališta na backend (izvor istine za recommender).
class ViewHistoryService {
  static final _api = ApiClient();

  static Future<void> recordLotView(int lotId, {int? userId}) async {
    if (userId == null ||
        ApiClient.authToken == null ||
        ApiClient.authToken!.isEmpty) {
      return;
    }

    try {
      await _api.post('/ParkingLotViewHistories/record', {
        'parkingLotId': lotId,
      });
      ParkingDataRefresh.notify();
    } catch (_) {
      // Offline — scoring koristi zadnji uspješni fetch s API-ja.
    }
  }
}
