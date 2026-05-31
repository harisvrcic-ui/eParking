import 'package:flutter/foundation.dart';

/// Notifies list/detail screens to reload parking availability from the API.
class ParkingDataRefresh {
  ParkingDataRefresh._();

  static final ValueNotifier<int> tick = ValueNotifier(0);

  static void notify() => tick.value++;
}
