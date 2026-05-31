import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';

/// Perzistencija korisničkih postavki za sistem preporuke.
class PreferencesService {
  static const _keyEv = 'pref_ev';
  static const _keyBudget = 'pref_budget';
  static const _keyNearby = 'pref_nearby';
  static const _keyCovered = 'pref_covered';
  static const _keyZone = 'pref_zone';

  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final zoneRaw = prefs.getString(_keyZone) ?? 'any';
    return UserPreferences(
      preferEvCharging: prefs.getBool(_keyEv) ?? true,
      preferBudget: prefs.getBool(_keyBudget) ?? false,
      preferNearby: prefs.getBool(_keyNearby) ?? true,
      preferCovered: prefs.getBool(_keyCovered) ?? false,
      zonePreference: _zoneFromString(zoneRaw),
    );
  }

  static Future<void> save(UserPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEv, preferences.preferEvCharging);
    await prefs.setBool(_keyBudget, preferences.preferBudget);
    await prefs.setBool(_keyNearby, preferences.preferNearby);
    await prefs.setBool(_keyCovered, preferences.preferCovered);
    await prefs.setString(_keyZone, _zoneToString(preferences.zonePreference));
  }

  static GeographicZonePreference _zoneFromString(String value) {
    return switch (value) {
      'zona1' => GeographicZonePreference.zona1Centar,
      'zona2' => GeographicZonePreference.zona2Periferija,
      _ => GeographicZonePreference.any,
    };
  }

  static String _zoneToString(GeographicZonePreference zone) {
    return switch (zone) {
      GeographicZonePreference.zona1Centar => 'zona1',
      GeographicZonePreference.zona2Periferija => 'zona2',
      GeographicZonePreference.any => 'any',
    };
  }
}
