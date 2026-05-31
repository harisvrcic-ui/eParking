import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../screens/forms/form_helpers.dart';

/// Modal za odabir koordinata na karti (RS2 tačka 6).
Future<({double lat, double lng})?> showCoordinatePickerDialog(
  BuildContext context, {
  double? initialLat,
  double? initialLng,
  String? addressHint,
}) async {
  return showDialog<({double lat, double lng})>(
    context: context,
    builder: (ctx) => _CoordinatePickerDialog(
      initialLat: initialLat ?? 43.8564,
      initialLng: initialLng ?? 18.4131,
      addressHint: addressHint,
    ),
  );
}

class _CoordinatePickerDialog extends StatefulWidget {
  const _CoordinatePickerDialog({
    required this.initialLat,
    required this.initialLng,
    this.addressHint,
  });

  final double initialLat;
  final double initialLng;
  final String? addressHint;

  @override
  State<_CoordinatePickerDialog> createState() => _CoordinatePickerDialogState();
}

class _CoordinatePickerDialogState extends State<_CoordinatePickerDialog> {
  late LatLng _point;
  final _addressC = TextEditingController();
  final _mapController = MapController();
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _point = LatLng(widget.initialLat, widget.initialLng);
    if (widget.addressHint != null && widget.addressHint!.isNotEmpty) {
      _addressC.text = widget.addressHint!;
    }
  }

  @override
  void dispose() {
    _addressC.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _geocodeAddress() async {
    final query = _addressC.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '1',
      });
      final resp = await http.get(
        uri,
        headers: const {'User-Agent': 'eParkingDesktop/1.0 (RS2 project)'},
      );
      if (resp.statusCode != 200) {
        throw Exception('Geocoding servis nije dostupan.');
      }

      final list = jsonDecode(resp.body) as List<dynamic>;
      if (list.isEmpty) {
        setState(() => _searchError = 'Adresa nije pronađena. Pokušajte drugi unos.');
        return;
      }

      final item = list.first as Map<String, dynamic>;
      final lat = double.parse(item['lat'].toString());
      final lng = double.parse(item['lon'].toString());
      setState(() => _point = LatLng(lat, lng));
      _mapController.move(_point, 15);
    } catch (e) {
      setState(() => _searchError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: dialogTitleBar(context, 'Odabir koordinata'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _addressC,
              decoration: InputDecoration(
                labelText: 'Adresa / grad / ulica',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Pretraži lokaciju',
                  onPressed: _searching ? null : _geocodeAddress,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _geocodeAddress(),
            ),
            if (_searchError != null) ...[
              const SizedBox(height: 6),
              Text(_searchError!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Text(
              'Kliknite na kartu da postavite tačku lokacije.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: 14,
                    onTap: (_, point) => setState(() => _point = point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.eparking.desktop',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _point,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            detailInfoRow(
              icon: Icons.my_location,
              label: 'Koordinate',
              value: '${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)}',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (lat: _point.latitude, lng: _point.longitude)),
          child: const Text('Potvrdi lokaciju'),
        ),
      ],
    );
  }
}
