import 'package:flutter/material.dart';

import '../models/reservation.dart';
import 'detail_info_row.dart';

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    required this.timeLabel,
    required this.statusLabel,
    required this.statusColor,
    this.onCancel,
  });

  final Reservation reservation;
  final String timeLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onCancel;

  String? get _statusNoteLabel {
    final note = reservation.statusNote?.trim();
    if (note == null || note.isEmpty) return null;
    if (reservation.isCancelled) return 'Razlog otkazivanja';
    return 'Napomena';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    reservation.locationTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reservation.parkingLotName.isNotEmpty)
              DetailInfoRow(
                icon: Icons.local_parking,
                label: 'Parking',
                value: reservation.parkingLotName,
              ),
            if (reservation.parkingSpotDisplayName.isNotEmpty)
              DetailInfoRow(
                icon: Icons.place,
                label: 'Mjesto',
                value: reservation.parkingSpotDisplayName,
              ),
            if (reservation.carLabel.isNotEmpty)
              DetailInfoRow(
                icon: Icons.directions_car,
                label: 'Vozilo',
                value: reservation.carLabel,
              ),
            DetailInfoRow(
              icon: Icons.calendar_today,
              label: 'Period',
              value: timeLabel,
            ),
            DetailInfoRow(
              icon: Icons.payments_outlined,
              label: 'Cijena',
              value: '${reservation.finalPrice.toStringAsFixed(2)} KM',
            ),
            if (_statusNoteLabel != null) ...[
              const SizedBox(height: 4),
              DetailInfoRow(
                icon: Icons.notes,
                label: _statusNoteLabel!,
                value: reservation.statusNote!.trim(),
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('Otkaži rezervaciju'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
