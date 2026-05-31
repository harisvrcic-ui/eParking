/// Još nije završila — prikaz u „Aktivne“ (uključuje i buduće rezervacije).
bool reservationIsNotEnded(DateTime end) {
  return end.toUtc().isAfter(DateTime.now().toUtc());
}

/// Trenutno drži parking mjesto zauzetim (za mapu; ne uključuje buduće termine).
bool reservationOccupiesSpotNow(DateTime start, DateTime end) {
  final now = DateTime.now().toUtc();
  final s = start.toUtc();
  final e = end.toUtc();
  return !s.isAfter(now) && e.isAfter(now);
}
