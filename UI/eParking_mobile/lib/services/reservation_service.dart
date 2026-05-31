import '../core/api_client.dart';
import '../models/lookup_item.dart';
import '../models/reservation.dart';

class ReservationService {
  final ApiClient _api = ApiClient();

  Future<List<Reservation>> getMyReservations() async {
    final data = await _api.getList('/Reservations');
    return data
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelReservation(int id, {String? reason}) async {
    await _api.post('/Reservations/$id/cancel', {
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }

  Future<List<LookupItem>> getReservationTypes() async {
    final data = await _api.getList('/Lookups/reservation-types');
    return data
        .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createReservation({
    required int carId,
    required int parkingSpotId,
    required int reservationTypeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _api.post('/Reservations', {
      'carId': carId,
      'parkingSpotId': parkingSpotId,
      'reservationTypeId': reservationTypeId,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    });
    return result as Map<String, dynamic>;
  }
}
