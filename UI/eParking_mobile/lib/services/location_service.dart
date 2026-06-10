import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/search_text.dart';

class DistanceResult {
  final double? km;
  final bool fromGps;

  const DistanceResult({this.km, this.fromGps = false});

  static const empty = DistanceResult();
}

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

  /// Sarajevo metro — emulator default (npr. SAD) odbacujemo za udaljenosti.
  static const double sarajevoCenterLat = 43.8564;
  static const double sarajevoCenterLng = 18.4131;

  static DistanceResult resolveDistanceResult({
    required String lotName,
    double? gpsKm,
    double? lotLatitude,
    double? lotLongitude,
  }) {
    if (gpsKm != null) return DistanceResult(km: gpsKm, fromGps: true);

    if (useDemoDistances) {
      final demo = demoDistanceKmForParkir(lotName);
      if (demo != null) return DistanceResult(km: demo);
    }

    final coords = resolveLotCoordinates(
      lotName: lotName,
      latitude: lotLatitude,
      longitude: lotLongitude,
    );
    if (coords == null) return DistanceResult.empty;

    return DistanceResult(
      km: distanceKm(
        sarajevoCenterLat,
        sarajevoCenterLng,
        coords.lat,
        coords.lng,
      ),
    );
  }

  /// GPS udaljenost; bez GPS-a udaljenost od centra Sarajeva (app je lokalna).
  static double? resolveDistanceKm({
    required String lotName,
    double? gpsKm,
    double? lotLatitude,
    double? lotLongitude,
  }) {
    return resolveDistanceResult(
      lotName: lotName,
      gpsKm: gpsKm,
      lotLatitude: lotLatitude,
      lotLongitude: lotLongitude,
    ).km;
  }

  static bool hasGpsPosition(Position? position) {
    if (position == null) return false;
    return isPlausibleUserPosition(position.latitude, position.longitude);
  }

  static String formatDistanceLabel(
    DistanceResult result, {
    required String gpsSuffix,
    required String centerSuffix,
  }) {
    if (result.km == null) return '—';
    final base = formatDistanceKm(result.km);
    if (result.fromGps) return '$base · $gpsSuffix';
    return '$base · $centerSuffix';
  }

  static const double _sarajevoLat = sarajevoCenterLat;
  static const double _sarajevoLng = sarajevoCenterLng;
  static const double _maxPlausibleUserDistanceKm = 80;

  static bool isPlausibleUserPosition(double latitude, double longitude) {
    if (latitude.abs() < 0.01 && longitude.abs() < 0.01) return false;
    return distanceKm(latitude, longitude, _sarajevoLat, _sarajevoLng) <=
        _maxPlausibleUserDistanceKm;
  }

  /// Udaljenost od korisnika do parkinga (samo valjan GPS u okolini Sarajeva).
  static double? userDistanceKmToLot({
    required Position? userPosition,
    required double? lotLatitude,
    required double? lotLongitude,
  }) {
    if (userPosition == null || lotLatitude == null || lotLongitude == null) {
      return null;
    }
    if (!isPlausibleUserPosition(
      userPosition.latitude,
      userPosition.longitude,
    )) {
      return null;
    }

    return distanceKm(
      userPosition.latitude,
      userPosition.longitude,
      lotLatitude,
      lotLongitude,
    );
  }

  static double? distanceKmFromPosition({
    required Position? userPosition,
    required double? lotLatitude,
    required double? lotLongitude,
    String lotName = '',
  }) {
    return distanceKmToLot(
      lotName: lotName,
      userPosition: userPosition,
      lotLatitude: lotLatitude,
      lotLongitude: lotLongitude,
    );
  }

  /// Koordinate parkinga iz API-ja ili poznati defaults (isti kao backend).
  static ({double lat, double lng})? resolveLotCoordinates({
    required String lotName,
    double? latitude,
    double? longitude,
  }) {
    if (latitude != null && longitude != null) {
      return (lat: latitude, lng: longitude);
    }

    final n = lotName.toLowerCase();
    if (n.contains('aria')) return (lat: 43.8425, lng: 18.3360);
    if (n.contains('vije') || n.contains('vijecnica')) {
      return (lat: 43.8590, lng: 18.4335);
    }
    if (n.contains('baš') || n.contains('basc')) {
      return (lat: 43.8594, lng: 18.4312);
    }
    return null;
  }

  static double? distanceKmToLot({
    required String lotName,
    required Position? userPosition,
    double? lotLatitude,
    double? lotLongitude,
  }) {
    final coords = resolveLotCoordinates(
      lotName: lotName,
      latitude: lotLatitude,
      longitude: lotLongitude,
    );
    if (coords == null) return null;

    return userDistanceKmToLot(
      userPosition: userPosition,
      lotLatitude: coords.lat,
      lotLongitude: coords.lng,
    );
  }

  /// Parkinzi nemaju grad u nazivu — mapiranje za filter pretrage.
  /// Zona 1 (centar) ili Zona 2 (periferija) za parkir.
  static String cityZoneForParkir(String lotName) {
    if (lotName.toLowerCase().contains('aria')) return 'Zona 2';
    return 'Zona 1';
  }

  /// API zone name is sometimes a lot label (legacy seed); normalize for scoring.
  static String resolveCityZone({
    required String lotName,
    required String spotZoneName,
  }) {
    final zone = spotZoneName.trim();
    if (zone == 'Zona 1' || zone == 'Zona 2') return zone;
    return cityZoneForParkir(lotName);
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

  Future<LocationPermission> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  Position? _plausiblePosition(Position? position) {
    if (position == null) return null;
    if (!isPlausibleUserPosition(position.latitude, position.longitude)) {
      return null;
    }
    return position;
  }

  static bool _permissionGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Position sarajevoDebugPosition() {
    return Position(
      latitude: sarajevoCenterLat,
      longitude: sarajevoCenterLng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Brzo čitanje GPS-a; u debug modu vraća Sarajevo kad emulator ne pošalje fix.
  Future<Position?> getCurrentPosition() async {
    final permission = await requestLocationPermission();

    if (_permissionGranted(permission)) {
      final devicePosition = await _tryReadDevicePosition();
      if (devicePosition != null) {
        return devicePosition;
      }
    }

    // flutter run = debug; emulator često ne pošalje fix Geolocatoru.
    if (kDebugMode || useDemoDistances) {
      return sarajevoDebugPosition();
    }

    return null;
  }

  Future<Position?> _tryReadDevicePosition() async {
    try {
      return await _readDevicePosition().timeout(const Duration(seconds: 4));
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _readDevicePosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      final cached = _plausiblePosition(last);
      if (cached != null) return cached;
    } catch (_) {}

    final attempts = <LocationSettings>[
      if (Platform.isAndroid)
        AndroidSettings(
          accuracy: LocationAccuracy.medium,
          forceLocationManager: false,
          timeLimit: const Duration(seconds: 3),
        ),
      if (Platform.isAndroid)
        AndroidSettings(
          accuracy: LocationAccuracy.low,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 3),
        ),
    ];

    for (final settings in attempts) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: settings,
        );
        final plausible = _plausiblePosition(position);
        if (plausible != null) return plausible;
      } catch (_) {}
    }

    return null;
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
