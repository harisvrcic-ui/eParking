import 'package:flutter/material.dart';

import '../models/parking_lot_detail.dart';
import '../services/car_service.dart';
import '../widgets/form_navigation.dart';
import '../widgets/parking_spot_tile.dart';
import 'reservation_screen.dart';

class ParkingLocationSpotsScreen extends StatefulWidget {
  const ParkingLocationSpotsScreen({
    super.key,
    required this.locationName,
    required this.spots,
    required this.userId,
  });

  final String locationName;
  final List<ParkingSpotDetail> spots;
  final int userId;

  @override
  State<ParkingLocationSpotsScreen> createState() =>
      _ParkingLocationSpotsScreenState();
}

class _ParkingLocationSpotsScreenState extends State<ParkingLocationSpotsScreen> {
  final _searchController = TextEditingController();
  int? _selectedSpotId;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _filter = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String spotCode(ParkingSpotDetail spot) => 'P${spot.parkingNumber}';

  ParkingSpotDetail? get _selectedSpot {
    final id = _selectedSpotId;
    if (id == null) return null;
    for (final spot in widget.spots) {
      if (spot.id == id) return spot;
    }
    return null;
  }

  Future<void> _openReservation() async {
    final spot = _selectedSpot;
    if (spot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prvo odaberi slobodno mjesto.')),
      );
      return;
    }

    try {
      final cars = await CarService().getMyCars();
      if (cars.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nema registriranih vozila. Dodaj vozilo u profilu prije rezervacije.',
            ),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservationScreen(
          userId: widget.userId,
          parkingSpotId: spot.id,
          locationName: widget.locationName,
          spotLabel: spotCode(spot),
        ),
      ),
    );
  }

  List<ParkingSpotDetail> get _visibleSpots {
    if (_filter.isEmpty) return widget.spots;
    return widget.spots.where((s) {
      final code = spotCode(s).toLowerCase();
      return code.contains(_filter) ||
          s.label.toLowerCase().contains(_filter) ||
          (s.displayName ?? '').toLowerCase().contains(_filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = _visibleSpots;
    final available = widget.spots.where((s) => s.isAvailableNow).length;

    return Scaffold(
      appBar: formScreenAppBar(context, title: widget.locationName),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Odaberi slobodno mjesto',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$available / ${widget.spots.length} slobodno',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LegendDot(color: Colors.green, label: 'Slobodno'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red, label: 'Zauzeto'),
              const SizedBox(width: 16),
              _LegendDot(
                color: theme.colorScheme.primary,
                label: 'Odabrano',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pretraži mjesto (npr. P1)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Nema mjesta za prikaz.')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final spot = visible[index];
                final code = spotCode(spot);
                final selected = _selectedSpotId == spot.id;

                return ParkingSpotTile(
                  code: code,
                  isAvailable: spot.isAvailableNow,
                  isSelected: selected,
                  onTap: spot.isAvailableNow
                      ? () => setState(() {
                            _selectedSpotId = selected ? null : spot.id;
                          })
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ovo mjesto je zauzeto — odaberi slobodno mjesto (zeleno).',
                              ),
                            ),
                          );
                        },
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: _selectedSpot != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Odabrano: ${spotCode(_selectedSpot!)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    FilledButton(
                      onPressed: _openReservation,
                      child: const Text('Rezerviši'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
