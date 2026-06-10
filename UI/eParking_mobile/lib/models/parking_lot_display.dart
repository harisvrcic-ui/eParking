import '../l10n/app_strings.dart';
import 'parking_lot.dart';

enum RecommendationBadge {
  none,
  topPick,
  ev,
  affordable,
  covered,
}

class ParkingLotDisplay {
  final ParkingLot lot;
  final int availableSpots;
  final String locationLabel;
  final String distanceLabel;
  final bool distanceFromGps;
  final RecommendationBadge badge;
  final String? badgeHint;
  final bool isPreferredName;

  ParkingLotDisplay({
    required this.lot,
    required this.availableSpots,
    required this.locationLabel,
    required this.distanceLabel,
    this.distanceFromGps = false,
    this.badge = RecommendationBadge.none,
    this.badgeHint,
    this.isPreferredName = false,
  });

  String get badgeTitle {
    final s = AppStrings.current;
    switch (badge) {
      case RecommendationBadge.topPick:
        return s.badgeTopPick;
      case RecommendationBadge.ev:
        return s.badgeEv;
      case RecommendationBadge.affordable:
        return s.badgeAffordable;
      case RecommendationBadge.covered:
        return s.badgeCovered;
      case RecommendationBadge.none:
        return '';
    }
  }

  String get displayTitle {
    if (isPreferredName) return '${lot.name}${AppStrings.current.preferredNameSuffix}';
    return lot.name;
  }
}
