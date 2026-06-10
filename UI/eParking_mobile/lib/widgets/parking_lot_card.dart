import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/parking_lot_display.dart';

class ParkingLotCard extends StatelessWidget {
  const ParkingLotCard({
    super.key,
    required this.item,
    this.onViewDetails,
  });

  final ParkingLotDisplay item;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    final primary = theme.colorScheme.primary;

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
            if (item.badge != RecommendationBadge.none) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.badgeTitle,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              item.displayTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  item.distanceFromGps ? Icons.my_location : Icons.location_on,
                  size: 16,
                  color: item.distanceFromGps
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.locationLabel} · ${item.distanceLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.distanceFromGps
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                      fontWeight:
                          item.distanceFromGps ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            if (item.badgeHint != null) ...[
              const SizedBox(height: 6),
              Text(
                item.badgeHint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  s.spotsAvailable(item.availableSpots),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onViewDetails,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(s.details),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
