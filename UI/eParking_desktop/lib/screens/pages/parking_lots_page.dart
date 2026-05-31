import 'package:flutter/material.dart';

import '../../config/parking_lot_status.dart';
import '../../core/api_client.dart';
import '../../widgets/coordinate_picker_dialog.dart';
import '../../widgets/generic_crud_page.dart';
import '../../widgets/management_page_layout.dart';
import '../forms/form_helpers.dart';

class ParkingLotsPage extends StatelessWidget {
  const ParkingLotsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudPage(
      title: 'Parkinzi',
      subtitle: 'Upravljanje parkinzima (Vijećnica, Baščaršija, Aria Mall)',
      endpoint: '/ParkingLots',
      searchHint: 'Search by lot name...',
      totalItemLabel: 'Parkinzi',
      columnHeaders: const ['Naziv', 'Broj mjesta', 'Zona', 'Status'],
      filter: (item, q) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      },
      buildRow: (item, reload, {onEdit, onDelete}) {
        final zoneLabel = _zoneLabelForParkir(item['name']?.toString() ?? '');
        return ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${item['numberOfSpots']}'),
            Text(zoneLabel),
            statusBadge(item['status']?.toString() ?? ''),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      showForm: _showForm,
    );
  }

  Future<void> _showForm(
    BuildContext context,
    Map<String, dynamic>? item,
    Future<void> Function() reload,
  ) async {
    final api = ApiClient();
    final nameC = TextEditingController(text: item?['name']?.toString() ?? '');
    var status = _statusToInt(item?['status']);
    var isActive = item?['isActive'] as bool? ?? true;
    double? latitude = (item?['latitude'] as num?)?.toDouble();
    double? longitude = (item?['longitude'] as num?)?.toDouble();

    await showCrudDialog(
      context: context,
      title: item == null ? 'Add Parking Lot' : 'Edit Parking Lot',
      successMessage: item == null
          ? 'Parking je uspješno dodan.'
          : 'Parking je uspješno ažuriran.',
      fields: [
        textField(nameC, 'Lot name'),
        StatefulBuilder(
          builder: (ctx, setS) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showCoordinatePickerDialog(
                    ctx,
                    initialLat: latitude ?? 43.8564,
                    initialLng: longitude ?? 18.4131,
                    addressHint: nameC.text.trim().isEmpty ? 'Sarajevo' : nameC.text.trim(),
                  );
                  if (picked != null) {
                    setS(() {
                      latitude = picked.lat;
                      longitude = picked.lng;
                    });
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Odaberi lokaciju na karti'),
              ),
              if (latitude != null && longitude != null) ...[
                const SizedBox(height: 8),
                detailInfoRow(
                  icon: Icons.my_location,
                  label: 'Koordinate',
                  value: '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Koordinate nisu postavljene — obavezno odaberite lokaciju.',
                    style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        StatefulBuilder(
          builder: (ctx, setS) => DropdownButtonFormField<int>(
            value: status,
            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
            items: ParkingLotStatusIds.statusOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setS(() => status = v ?? ParkingLotStatusIds.active),
          ),
        ),
        const SizedBox(height: 12),
        StatefulBuilder(
          builder: (ctx, setS) => compactCheckboxListTile(
            title: 'Active',
            value: isActive,
            onChanged: (v) => setS(() => isActive = v ?? true),
          ),
        ),
      ],
      onSave: () async {
        if (latitude == null || longitude == null) {
          throw Exception('Odaberite koordinate parkinga na karti.');
        }
        final body = {
          'name': nameC.text.trim(),
          'status': status,
          'isActive': isActive,
          'latitude': latitude,
          'longitude': longitude,
        };
        if (item == null) {
          await api.post('/ParkingLots', body);
        } else {
          body['id'] = item['id'];
          await api.put('/ParkingLots', item['id'] as int, body);
        }
        await reload();
      },
    );
  }

  int _statusToInt(dynamic status) {
    return switch (status?.toString()) {
      'Inactive' => ParkingLotStatusIds.inactive,
      'Maintenance' => ParkingLotStatusIds.maintenance,
      'Full' => ParkingLotStatusIds.full,
      _ => ParkingLotStatusIds.active,
    };
  }

  /// Aria Mall = periferija (Zona 2); Vijećnica i Baščaršija = centar (Zona 1).
  static String _zoneLabelForParkir(String name) {
    if (name.toLowerCase().contains('aria')) {
      return 'Zona 2';
    }
    return 'Zona 1';
  }
}
