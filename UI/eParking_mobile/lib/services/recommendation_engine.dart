import 'package:decimal/decimal.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/app_strings.dart';
import '../models/login_response.dart';
import '../models/parking_lot.dart';
import '../models/parking_lot_display.dart';
import '../models/parking_lot_overview.dart';
import '../models/reservation.dart';
import '../models/user_preferences.dart';
import 'location_service.dart';

/// Content-based preporuka: atributi lokacije + preferencije + historija
/// rezervacija/pregleda + prostorna analiza (bez collaborative filtering).
class RecommendationEngine {
  static const _priceMultiplierByType = {
    'disabled': 0.5,
    'compact': 0.9,
    'regular': 1.0,
    'large': 1.2,
    'electric': 1.3,
  };

  List<ParkingLotDisplay> buildDisplayList({
    required List<ParkingLotOverview> overviews,
    required List<ParkingSpotSummary> spots,
    required LoginResponse user,
    required UserPreferences preferences,
    required List<Reservation> reservations,
    required Map<int, int> viewCountByLotId,
    Position? userPosition,
  }) {
    final spotsByLot = <int, List<ParkingSpotSummary>>{};
    for (final spot in spots) {
      spotsByLot.putIfAbsent(spot.parkingLotId, () => []).add(spot);
    }

    final profile = _UserContentProfile.fromHistory(
      reservations: reservations,
      viewCountByLotId: viewCountByLotId,
      spots: spots,
    );

    ParkingLotOverview? frequentLot;
    if (profile.mostFrequentLotId != null) {
      for (final o in overviews) {
        if (o.id == profile.mostFrequentLotId) {
          frequentLot = o;
          break;
        }
      }
    }

    final maxAvailableSpots = overviews
        .map((o) => o.availableSpots)
        .fold(0, (max, n) => n > max ? n : max);

    final displays = overviews.map((overview) {
      final lot = overview.toParkingLot();
      final lotSpots = spotsByLot[lot.id] ?? [];
      final features = _LotFeatures.fromSpots(lot.name, lotSpots);

      final displayDistance = LocationService.resolveDistanceResult(
        lotName: overview.name,
        gpsKm: LocationService.distanceKmToLot(
          lotName: overview.name,
          userPosition: userPosition,
          lotLatitude: overview.latitude,
          lotLongitude: overview.longitude,
        ),
        lotLatitude: overview.latitude,
        lotLongitude: overview.longitude,
      );
      final scoringDistanceKm = _scoringDistanceKm(
        overview: overview,
        userPosition: userPosition,
        frequentLot: frequentLot,
      );

      final score = _scoreLot(
        features: features,
        availableSpots: overview.availableSpots,
        maxAvailableSpots: maxAvailableSpots,
        preferences: preferences,
        profile: profile,
        distanceKm: scoringDistanceKm,
        reservationCount: profile.reservationCountByLotId[lot.id] ?? 0,
        viewCount: viewCountByLotId[lot.id] ?? 0,
      );

      return _LotAnalysis(
        lot: lot,
        features: features,
        availableSpots: overview.availableSpots,
        distance: displayDistance,
        score: score,
      );
    }).toList();

    displays.sort((a, b) {
      if (preferences.preferNearby) {
        final da = a.distance.km ?? double.infinity;
        final db = b.distance.km ?? double.infinity;
        final byDistance = da.compareTo(db);
        if (byDistance != 0) return byDistance;
      }
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.lot.name.compareTo(b.lot.name);
    });

    final topPickLotId = displays
        .where((d) => d.score > 0)
        .map((d) => d.lot.id)
        .firstOrNull;

    var usedEv = false;
    var usedAffordable = false;
    var usedCovered = false;
    final strings = AppStrings.current;

    return displays.map((item) {
      var badge = RecommendationBadge.none;
      String? hint;

      if (item.lot.id == topPickLotId) {
        badge = RecommendationBadge.topPick;
        hint = _topPickHint(strings, item.features, profile, preferences);
      } else if (preferences.preferEvCharging && item.features.hasEv && !usedEv) {
        badge = RecommendationBadge.ev;
        hint = strings.hintEv;
        usedEv = true;
      } else if (preferences.preferBudget &&
          item.features.priceTier == PriceTier.low &&
          !usedAffordable) {
        badge = RecommendationBadge.affordable;
        hint = strings.hintAffordable;
        usedAffordable = true;
      } else if (preferences.preferCovered && item.features.hasCovered && !usedCovered) {
        badge = RecommendationBadge.covered;
        hint = strings.hintCovered;
        usedCovered = true;
      }

      return ParkingLotDisplay(
        lot: item.lot,
        availableSpots: item.availableSpots,
        locationLabel: '${item.lot.name} · ${item.features.cityZone}',
        distanceLabel: LocationService.formatDistanceLabel(
          item.distance,
          gpsSuffix: strings.distanceFromGps,
          centerSuffix: strings.distanceFromCenter,
        ),
        distanceFromGps: item.distance.fromGps,
        badge: badge,
        badgeHint: hint,
        isPreferredName: badge == RecommendationBadge.topPick,
      );
    }).toList();
  }

  static String _topPickHint(
    AppStrings strings,
    _LotFeatures features,
    _UserContentProfile profile,
    UserPreferences preferences,
  ) {
    if (profile.hasReservationHistory || profile.hasViewHistory) {
      var hint = strings.hintTopPickWithHistory;
      if (preferences.zonePreference != GeographicZonePreference.any) {
        hint = '$hint (${features.cityZone})';
      }
      return hint;
    }
    if (preferences.zonePreference != GeographicZonePreference.any) {
      return '${strings.hintTopPickDefault} (${features.cityZone})';
    }
    return strings.hintTopPickDefault;
  }

  /// Za bodovanje: minimum dostupnih udaljenosti (demo, GPS, čest parking, centar).
  static double? _scoringDistanceKm({
    required ParkingLotOverview overview,
    required Position? userPosition,
    required ParkingLotOverview? frequentLot,
  }) {
    final candidates = <double>[];

    if (LocationService.useDemoDistances) {
      final demo = LocationService.demoDistanceKmForParkir(overview.name);
      if (demo != null) candidates.add(demo);
    }

    final gpsKm = LocationService.distanceKmToLot(
      lotName: overview.name,
      userPosition: userPosition,
      lotLatitude: overview.latitude,
      lotLongitude: overview.longitude,
    );
    if (gpsKm != null) candidates.add(gpsKm);

    final lotCoords = LocationService.resolveLotCoordinates(
      lotName: overview.name,
      latitude: overview.latitude,
      longitude: overview.longitude,
    );
    if (frequentLot != null &&
        frequentLot.id != overview.id &&
        lotCoords != null) {
      final frequentCoords = LocationService.resolveLotCoordinates(
        lotName: frequentLot.name,
        latitude: frequentLot.latitude,
        longitude: frequentLot.longitude,
      );
      if (frequentCoords != null) {
        candidates.add(
          LocationService.distanceKm(
            frequentCoords.lat,
            frequentCoords.lng,
            lotCoords.lat,
            lotCoords.lng,
          ),
        );
      }
    }

    final centerKm = LocationService.resolveDistanceKm(
      lotName: overview.name,
      lotLatitude: overview.latitude,
      lotLongitude: overview.longitude,
    );
    if (centerKm != null) candidates.add(centerKm);

    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a < b ? a : b);
  }

  static String? _explicitZone(GeographicZonePreference preference) {
    return switch (preference) {
      GeographicZonePreference.zona1Centar => 'Zona 1',
      GeographicZonePreference.zona2Periferija => 'Zona 2',
      GeographicZonePreference.any => null,
    };
  }

  static int _scoreLot({
    required _LotFeatures features,
    required int availableSpots,
    required int maxAvailableSpots,
    required UserPreferences preferences,
    required _UserContentProfile profile,
    required double? distanceKm,
    required int reservationCount,
    required int viewCount,
  }) {
    // Normalizirano 0–20: veliki parking ne dominira sam brojem mjesta.
    var score = maxAvailableSpots <= 0
        ? 0
        : ((availableSpots / maxAvailableSpots) * 20).round();

    // Karakteristike lokacije (content-based)
    if (preferences.preferEvCharging && features.hasEv) score += 12;
    if (preferences.preferBudget && features.priceTier == PriceTier.low) score += 10;
    if (preferences.preferCovered && features.hasCovered) score += 10;

    switch (preferences.zonePreference) {
      case GeographicZonePreference.zona1Centar:
        if (features.cityZone == 'Zona 1') {
          score += 25;
        } else {
          score -= 15;
        }
        break;
      case GeographicZonePreference.zona2Periferija:
        if (features.cityZone == 'Zona 2') {
          score += 25;
        } else {
          score -= 15;
        }
        break;
      case GeographicZonePreference.any:
        break;
    }

    final wantedZone = _explicitZone(preferences.zonePreference);

    // Implicitna zona iz historije samo kad korisnik nije eksplicitno birao zonu.
    if (wantedZone == null &&
        profile.preferredZone != null &&
        profile.preferredZone == features.cityZone) {
      score += 12;
    }
    if (profile.preferredPriceTier != null &&
        profile.preferredPriceTier == features.priceTier) {
      score += 8;
    }

    // Historija ne smije nadjačati eksplicitnu zonu (npr. Zona 2 → Aria, ne Baščaršija).
    var historyReservations = reservationCount;
    var historyViews = viewCount;
    if (wantedZone != null && features.cityZone != wantedZone) {
      historyReservations = 0;
      historyViews = 0;
    }
    score += historyReservations * 6;
    score += historyViews * 3;

    // Prostorna analiza
    if (preferences.preferNearby && distanceKm != null) {
      score += (20 - distanceKm.clamp(0, 20)).round();
    }

    return score;
  }
}

enum PriceTier { low, mid, high }

class _LotFeatures {
  final String cityZone;
  final PriceTier priceTier;
  final bool hasEv;
  final bool hasCovered;

  _LotFeatures({
    required this.cityZone,
    required this.priceTier,
    required this.hasEv,
    required this.hasCovered,
  });

  factory _LotFeatures.fromSpots(String lotName, List<ParkingSpotSummary> spots) {
    final zone = spots.isNotEmpty && spots.first.zoneName.isNotEmpty
        ? LocationService.resolveCityZone(
            lotName: lotName,
            spotZoneName: spots.first.zoneName,
          )
        : LocationService.cityZoneForParkir(lotName);

    if (spots.isEmpty) {
      return _LotFeatures(
        cityZone: zone,
        priceTier: PriceTier.mid,
        hasEv: false,
        hasCovered: false,
      );
    }

    var multiplierSum = 0.0;
    var hasEv = false;
    var hasCovered = false;

    for (final s in spots) {
      final t = s.spotTypeName.toLowerCase();
      multiplierSum += RecommendationEngine._priceMultiplierByType[t] ?? 1.0;
      if (t.contains('electric')) hasEv = true;
      if (t.contains('electric') ||
          t.contains('large') ||
          t.contains('cover') ||
          t.contains('indoor') ||
          t.contains('garage')) {
        hasCovered = true;
      }
    }

    final avg = multiplierSum / spots.length;
    final tier = avg < 0.95
        ? PriceTier.low
        : avg > 1.15
            ? PriceTier.high
            : PriceTier.mid;

    return _LotFeatures(
      cityZone: zone,
      priceTier: tier,
      hasEv: hasEv,
      hasCovered: hasCovered,
    );
  }
}

class _UserContentProfile {
  final Map<int, int> reservationCountByLotId;
  final int? mostFrequentLotId;
  final String? preferredZone;
  final PriceTier? preferredPriceTier;
  final bool hasReservationHistory;
  final bool hasViewHistory;

  _UserContentProfile({
    required this.reservationCountByLotId,
    required this.mostFrequentLotId,
    required this.preferredZone,
    required this.preferredPriceTier,
    required this.hasReservationHistory,
    required this.hasViewHistory,
  });

  factory _UserContentProfile.fromHistory({
    required List<Reservation> reservations,
    required Map<int, int> viewCountByLotId,
    required List<ParkingSpotSummary> spots,
  }) {
    final reservationCountByLotId = <int, int>{};
    final priceSamples = <Decimal>[];

    for (final reservation in reservations) {
      if (reservation.parkingLotId <= 0) continue;
      reservationCountByLotId[reservation.parkingLotId] =
          (reservationCountByLotId[reservation.parkingLotId] ?? 0) + 1;
      priceSamples.add(reservation.finalPrice);
    }

    final interestCountByLotId = Map<int, int>.from(reservationCountByLotId);
    for (final entry in viewCountByLotId.entries) {
      if (entry.key <= 0 || entry.value <= 0) continue;
      interestCountByLotId[entry.key] =
          (interestCountByLotId[entry.key] ?? 0) + entry.value;
    }

    int? frequentLotId;
    var maxCount = 0;
    for (final entry in interestCountByLotId.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        frequentLotId = entry.key;
      }
    }

    final zoneByLotId = <int, String>{};
    for (final spot in spots) {
      final lotName = spot.parkingLotName.isNotEmpty
          ? spot.parkingLotName
          : spot.displayName ?? '';
      zoneByLotId.putIfAbsent(
        spot.parkingLotId,
        () => LocationService.resolveCityZone(
          lotName: lotName,
          spotZoneName: spot.zoneName,
        ),
      );
    }

    String? preferredZone;
    if (interestCountByLotId.isNotEmpty) {
      final zoneVotes = <String, int>{};
      for (final entry in interestCountByLotId.entries) {
        final zone = zoneByLotId[entry.key];
        if (zone == null || zone.isEmpty) continue;
        zoneVotes[zone] = (zoneVotes[zone] ?? 0) + entry.value;
      }
      if (zoneVotes.isNotEmpty) {
        preferredZone = zoneVotes.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;
      }
    }

    PriceTier? preferredPriceTier;
    if (priceSamples.isNotEmpty) {
      final sum = priceSamples.fold(Decimal.zero, (a, b) => a + b);
      final avg = sum.toDouble() / priceSamples.length;
      preferredPriceTier =
          avg < 8 ? PriceTier.low : (avg > 15 ? PriceTier.high : PriceTier.mid);
    }

    return _UserContentProfile(
      reservationCountByLotId: reservationCountByLotId,
      mostFrequentLotId: frequentLotId,
      preferredZone: preferredZone,
      preferredPriceTier: preferredPriceTier,
      hasReservationHistory: reservations.isNotEmpty,
      hasViewHistory: viewCountByLotId.values.any((c) => c > 0),
    );
  }
}

class _LotAnalysis {
  final ParkingLot lot;
  final _LotFeatures features;
  final int availableSpots;
  final DistanceResult distance;
  final int score;

  _LotAnalysis({
    required this.lot,
    required this.features,
    required this.availableSpots,
    required this.distance,
    required this.score,
  });
}
