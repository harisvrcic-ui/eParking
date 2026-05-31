import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';

/// Historija pregleda parkirališta (content-based signal).
///
/// RS2: signal se lokalno persistira i upisuje u bazu preko API-ja.
class ViewHistoryService {
  static const _prefsKey = 'viewCountByLotId';
  static final Map<int, int> _viewCountByLotId = {};
  static bool _initialized = false;
  static final _api = ApiClient();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final entry in decoded.entries) {
          final id = int.tryParse(entry.key.toString());
          final count = entry.value is int ? entry.value as int : int.tryParse(entry.value.toString());
          if (id != null && count != null && count > 0) {
            _viewCountByLotId[id] = count;
          }
        }
      }
    } catch (_) {
      // Ignore corrupt cache; start fresh.
    }
  }

  static Future<void> recordLotView(int lotId, {int? userId}) async {
    _viewCountByLotId[lotId] = (_viewCountByLotId[lotId] ?? 0) + 1;
    await _persist();

    if (userId != null && ApiClient.authToken != null && ApiClient.authToken!.isNotEmpty) {
      try {
        await _api.post('/ParkingLotViewHistories/record', {'parkingLotId': lotId});
      } catch (_) {
        // Offline or API unavailable — local cache still updated for recommender.
      }
    }
  }

  static Map<int, int> viewCountByLotId() => Map.unmodifiable(_viewCountByLotId);

  static Future<void> clear() async {
    _viewCountByLotId.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final asStringMap = <String, int>{};
    for (final e in _viewCountByLotId.entries) {
      asStringMap[e.key.toString()] = e.value;
    }
    await prefs.setString(_prefsKey, jsonEncode(asStringMap));
  }
}
