/// Parking lot status values aligned with API `ParkingLotStatusIds`.
class ParkingLotStatusIds {
  ParkingLotStatusIds._();

  static const int active = 1;
  static const int inactive = 2;
  static const int maintenance = 3;
  static const int full = 4;

  static const statusOptions = <int, String>{
    active: 'Active',
    inactive: 'Inactive',
    maintenance: 'Maintenance',
    full: 'Full',
  };
}
