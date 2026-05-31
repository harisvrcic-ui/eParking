import '../core/api_client.dart';
import '../models/parking_lot.dart';
import '../models/parking_lot_detail.dart';
import '../models/parking_lot_overview.dart';

class ParkingService {
  final ApiClient _api = ApiClient();

  Future<List<ParkingLotOverview>> getParkingLotsOverview() async {
    final data = await _api.getList('/ParkingLots/overview');
    return data
        .map((e) => ParkingLotOverview.fromJson(e as Map<String, dynamic>))
        .where((l) => l.isActive)
        .toList();
  }

  Future<ParkingLotDetail> getParkingLotDetail(int id) async {
    final data = await _api.get('/ParkingLots/$id/detail');
    return ParkingLotDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ParkingLot>> getParkingLots() async {
    final data = await _api.getList('/ParkingLots');
    return data
        .map((e) => ParkingLot.fromJson(e as Map<String, dynamic>))
        .where((l) => l.isActive)
        .toList();
  }

  Future<List<ParkingSpotSummary>> getParkingSpots() async {
    final data = await _api.getList('/ParkingSpots');
    return data
        .map((e) => ParkingSpotSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
