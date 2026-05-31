import 'parking_lot_detail.dart';
import '../utils/search_text.dart';

/// Parkinzi (Vijećnica, Baščaršija, Aria Mall) — svaki je zaseban ParkingLot u API-ju.
class ParkingLocationSummary {
  final String name;
  final List<ParkingSpotDetail> spots;

  ParkingLocationSummary({required this.name, required this.spots});

  int get totalCount => spots.length;
  int get availableCount => spots.where((s) => s.isAvailableNow).length;

  static String displayTitle(String key) {
    final n = SearchText.normalize(key);
    if (n.contains('vijecnica')) return 'Vijećnica';
    if (n.contains('bascarsija')) return 'Baščaršija';
    if (n.contains('aria')) return 'Aria Mall';
    return key;
  }

  /// Detalj jednog parkirnog mjesta već sadrži samo njegova mjesta (API filtrira po lotu).
  static List<ParkingLocationSummary> fromLotDetail(ParkingLotDetail detail) {
    final allSpots = detail.zones.expand((z) => z.spots).toList();
    if (allSpots.isEmpty) return [];

    return [
      ParkingLocationSummary(
        name: displayTitle(detail.name),
        spots: allSpots,
      ),
    ];
  }
}
