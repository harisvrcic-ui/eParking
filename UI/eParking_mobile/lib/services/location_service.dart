import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../utils/search_text.dart';

class LocationService {
  /// Uključuje hardkodirane demo udaljenosti samo za prezentacije (`--dart-define=USE_DEMO_DISTANCES=true`).
  static const bool useDemoDistances = bool.fromEnvironment(
    'USE_DEMO_DISTANCES',
    defaultValue: false,
  );

  /// Demo udaljenosti za parkinze u Sarajevu (samo kad je [useDemoDistances] uključen).
  static double? demoDistanceKmForParkir(String lotName) {
    if (!useDemoDistances) return null;

    final n = lotName.toLowerCase();
    if (n.contains('aria')) return 5.0;
    if (n.contains('vije') || n.contains('vijecnica')) return 8.0;
    if (n.contains('baš') || n.contains('basc')) return 7.0;
    return null;
  }

  /// GPS udaljenost; demo vrijednosti samo iza [useDemoDistances].
  static double? resolveDistanceKm({
    required String lotName,
    double? gpsKm,
  }) {
    return gpsKm ?? demoDistanceKmForParkir(lotName);
  }

  static double? distanceKmFromPosition({
    required Position? userPosition,
    required double? lotLatitude,
    required double? lotLongitude,
  }) {
    if (userPosition == null || lotLatitude == null || lotLongitude == null) {
      return null;
    }

    return distanceKm(
      userPosition.latitude,
      userPosition.longitude,
      lotLatitude,
      lotLongitude,
    );
  }

  /// Parkinzi nemaju grad u nazivu — mapiranje za filter pretrage.
  /// Zona 1 (centar) ili Zona 2 (periferija) za parkir.
  static String cityZoneForParkir(String lotName) {
    if (lotName.toLowerCase().contains('aria')) return 'Zona 2';
    return 'Zona 1';
  }

  static bool parkirMatchesCity(String lotName, String cityName) {
    final city = SearchText.normalize(cityName);
    final lot = SearchText.normalize(lotName);
    if (city.contains('sarajevo')) {
      return lot.contains('aria') ||
          lot.contains('vije') ||
          lot.contains('vijecnica') ||
          lot.contains('baš') ||
          lot.contains('basc') ||
          lot.contains('sarajevo');
    }
    if (city.contains('mostar')) {
      return lot.contains('mostar');
    }
    return lot.contains(city);
  }

  Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
    } catch (_) {}

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      // Emulator default coords (e.g. US) are useless for Sarajevo lots.
      if (position.latitude.abs() < 0.01 && position.longitude.abs() < 0.01) {
        return null;
      }
      return position;
    } catch (_) {
      return null;
    }
  }

  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static String formatDistanceKm(double? km) {
    if (km == null) return '—';
    if (km < 0.1) return '< 0.1 km';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
