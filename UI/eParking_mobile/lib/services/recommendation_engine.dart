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
      overviews: overviews,
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

    final displays = overviews.map((overview) {
      final lot = overview.toParkingLot();
      final lotSpots = spotsByLot[lot.id] ?? [];
      final features = _LotFeatures.fromSpots(lot.name, lotSpots);

      final distanceKm = _effectiveDistanceKm(
        overview: overview,
        userPosition: userPosition,
        frequentLot: frequentLot,
      );

      final score = _scoreLot(
        features: features,
        availableSpots: overview.availableSpots,
        preferences: preferences,
        profile: profile,
        distanceKm: distanceKm,
        reservationCount: profile.reservationCountByLotId[lot.id] ?? 0,
        viewCount: viewCountByLotId[lot.id] ?? 0,
      );

      return _LotAnalysis(
        lot: lot,
        features: features,
        availableSpots: overview.availableSpots,
        distanceKm: distanceKm,
        score: score,
      );
    }).toList();

    if (preferences.preferNearby) {
      displays.sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        if (da != db) return da.compareTo(db);
        return b.score.compareTo(a.score);
      });
    } else {
      displays.sort((a, b) => b.score.compareTo(a.score));
    }

    var usedEv = false;
    var usedAffordable = false;
    var usedCovered = false;
    final strings = AppStrings.current;

    return displays.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      var badge = RecommendationBadge.none;
      String? hint;

      if (index == 0 && item.score > 0) {
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
        distanceLabel: item.distanceKm != null
            ? LocationService.formatDistanceKm(item.distanceKm)
            : '—',
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

  static double? _effectiveDistanceKm({
    required ParkingLotOverview overview,
    required Position? userPosition,
    required ParkingLotOverview? frequentLot,
  }) {
    final demo = LocationService.demoDistanceKmForParkir(overview.name);
    if (demo != null) return demo;

    final distances = <double>[];

    if (userPosition != null &&
        overview.latitude != null &&
        overview.longitude != null) {
      distances.add(
        LocationService.distanceKm(
          userPosition.latitude,
          userPosition.longitude,
          overview.latitude!,
          overview.longitude!,
        ),
      );
    }

    if (frequentLot != null &&
        frequentLot.id != overview.id &&
        frequentLot.latitude != null &&
        frequentLot.longitude != null &&
        overview.latitude != null &&
        overview.longitude != null) {
      distances.add(
        LocationService.distanceKm(
          frequentLot.latitude!,
          frequentLot.longitude!,
          overview.latitude!,
          overview.longitude!,
        ),
      );
    }

    if (distances.isEmpty) return null;
    return distances.reduce((a, b) => a < b ? a : b);
  }

  static int _scoreLot({
    required _LotFeatures features,
    required int availableSpots,
    required UserPreferences preferences,
    required _UserContentProfile profile,
    required double? distanceKm,
    required int reservationCount,
    required int viewCount,
  }) {
    var score = availableSpots;

    // Karakteristike lokacije (content-based)
    if (preferences.preferEvCharging && features.hasEv) score += 12;
    if (preferences.preferBudget && features.priceTier == PriceTier.low) score += 10;
    if (preferences.preferCovered && features.hasCovered) score += 10;

    switch (preferences.zonePreference) {
      case GeographicZonePreference.zona1Centar:
        if (features.cityZone == 'Zona 1') score += 15;
        break;
      case GeographicZonePreference.zona2Periferija:
        if (features.cityZone == 'Zona 2') score += 15;
        break;
      case GeographicZonePreference.any:
        break;
    }

    // Slične lokacije iz historije (ista zona / cjenovni rang)
    if (profile.preferredZone != null && profile.preferredZone == features.cityZone) {
      score += 12;
    }
    if (profile.preferredPriceTier != null &&
        profile.preferredPriceTier == features.priceTier) {
      score += 8;
    }

    // Historija rezervacija i pregleda
    score += reservationCount * 6;
    score += viewCount * 3;

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
        ? spots.first.zoneName
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
    required List<ParkingLotOverview> overviews,
  }) {
    final byLotName = <String, int>{};
    final priceSamples = <double>[];

    for (final r in reservations) {
      final name = r.parkingLotName;
      if (name.isEmpty) continue;
      byLotName[name] = (byLotName[name] ?? 0) + 1;
      priceSamples.add(r.finalPrice);
    }

    int? frequentLotId;
    var maxCount = 0;
    for (final o in overviews) {
      final c = byLotName[o.name] ?? 0;
      if (c > maxCount) {
        maxCount = c;
        frequentLotId = o.id;
      }
    }

    final reservationCountByLotId = <int, int>{};
    for (final o in overviews) {
      final c = byLotName[o.name] ?? 0;
      if (c > 0) reservationCountByLotId[o.id] = c;
    }

    String? preferredZone;
    if (byLotName.isNotEmpty) {
      final zoneVotes = <String, int>{};
      for (final entry in byLotName.entries) {
        final z = LocationService.cityZoneForParkir(entry.key);
        zoneVotes[z] = (zoneVotes[z] ?? 0) + entry.value;
      }
      preferredZone = zoneVotes.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    PriceTier? preferredPriceTier;
    if (priceSamples.isNotEmpty) {
      final avg = priceSamples.reduce((a, b) => a + b) / priceSamples.length;
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
  final double? distanceKm;
  final int score;

  _LotAnalysis({
    required this.lot,
    required this.features,
    required this.availableSpots,
    this.distanceKm,
    required this.score,
  });
}
