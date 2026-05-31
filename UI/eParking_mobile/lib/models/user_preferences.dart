/// Gradska parking zona (Zona 1 centar / Zona 2 periferija).
enum GeographicZonePreference {
  any,
  zona1Centar,
  zona2Periferija,
}

class UserPreferences {
  final bool preferEvCharging;
  final bool preferBudget;
  final bool preferNearby;
  final bool preferCovered;
  final GeographicZonePreference zonePreference;

  const UserPreferences({
    this.preferEvCharging = true,
    this.preferBudget = false,
    this.preferNearby = true,
    this.preferCovered = false,
    this.zonePreference = GeographicZonePreference.any,
  });

  UserPreferences copyWith({
    bool? preferEvCharging,
    bool? preferBudget,
    bool? preferNearby,
    bool? preferCovered,
    GeographicZonePreference? zonePreference,
  }) {
    return UserPreferences(
      preferEvCharging: preferEvCharging ?? this.preferEvCharging,
      preferBudget: preferBudget ?? this.preferBudget,
      preferNearby: preferNearby ?? this.preferNearby,
      preferCovered: preferCovered ?? this.preferCovered,
      zonePreference: zonePreference ?? this.zonePreference,
    );
  }
}
