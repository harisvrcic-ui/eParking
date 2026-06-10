import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/parking_lot_overview.dart';

class ParkingSearchCard extends StatelessWidget {
  const ParkingSearchCard({
    super.key,
    required this.overview,
    required this.distanceLabel,
    this.distanceFromGps = false,
    this.onViewParking,
  });

  final ParkingLotOverview overview;
  final String distanceLabel;
  final bool distanceFromGps;
  final VoidCallback? onViewParking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final s = context.s;
    final spotsLabel = s.spotsAvailable(overview.availableSpots);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              overview.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  distanceFromGps ? Icons.my_location : Icons.location_on,
                  size: 16,
                  color: distanceFromGps
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${overview.name} · $distanceLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: distanceFromGps
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                      fontWeight:
                          distanceFromGps ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              spotsLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onViewParking,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(s.viewParking),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
