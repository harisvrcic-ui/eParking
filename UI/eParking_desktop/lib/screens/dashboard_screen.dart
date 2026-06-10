import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../utils/money.dart';
import '../widgets/management_page_layout.dart';

class _DashboardTile {
  const _DashboardTile({
    required this.title,
    required this.sectionKey,
    required this.icon,
    required this.statKey,
    this.isRevenue = false,
  });

  final String title;
  final String sectionKey;
  final IconData icon;
  final String statKey;
  final bool isRevenue;
}

/// Kartice usklađene s lijevim navigacijskim menijem (bez samog Dashboard-a).
const _tiles = [
  _DashboardTile(title: 'Korisnici', sectionKey: 'users', icon: Icons.people, statKey: 'users'),
  _DashboardTile(title: 'Parkinzi', sectionKey: 'parkingLots', icon: Icons.local_parking, statKey: 'lots'),
  _DashboardTile(title: 'Parking mjesta', sectionKey: 'parkingSpots', icon: Icons.grid_on, statKey: 'spots'),
  _DashboardTile(title: 'Parking zone', sectionKey: 'parkingZones', icon: Icons.map, statKey: 'zones'),
  _DashboardTile(title: 'Tipovi mjesta', sectionKey: 'spotTypes', icon: Icons.category, statKey: 'spotTypes'),
  _DashboardTile(title: 'Rezervacije', sectionKey: 'reservations', icon: Icons.event, statKey: 'reservations'),
  _DashboardTile(title: 'Tipovi rezervacija', sectionKey: 'reservationTypes', icon: Icons.schedule, statKey: 'reservationTypes'),
  _DashboardTile(title: 'Brendovi', sectionKey: 'brands', icon: Icons.directions_car, statKey: 'brands'),
  _DashboardTile(title: 'Boje', sectionKey: 'colors', icon: Icons.palette, statKey: 'colors'),
  _DashboardTile(title: 'Gradovi', sectionKey: 'cities', icon: Icons.location_city, statKey: 'cities'),
  _DashboardTile(
    title: 'Izvještaji',
    sectionKey: 'reports',
    icon: Icons.bar_chart,
    statKey: 'revenue',
    isRevenue: true,
  ),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigate});

  final void Function(String sectionKey)? onNavigate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiClient();
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getList('/MyAppUsers'),
        _api.getList('/ParkingLots'),
        _api.getList('/ParkingSpots'),
        _api.getList('/ParkingZones'),
        _api.getList('/ParkingSpotTypes'),
        _api.getList('/Reservations'),
        _api.getList('/ReservationTypes'),
        _api.getList('/Brands'),
        _api.getList('/Colors'),
        _api.getList('/Cities'),
      ]);

      var revenue = Decimal.zero;
      for (final r in results[5]) {
        revenue += moneyFromJson((r as Map<String, dynamic>)['finalPrice']);
      }

      _stats = {
        'users': results[0].length,
        'lots': results[1].length,
        'spots': results[2].length,
        'zones': results[3].length,
        'spotTypes': results[4].length,
        'reservations': results[5].length,
        'reservationTypes': results[6].length,
        'brands': results[7].length,
        'colors': results[8].length,
        'cities': results[9].length,
        'revenue': revenue,
      };
    } catch (_) {
      _stats = {};
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _valueForTile(_DashboardTile tile) {
    final raw = _stats[tile.statKey];
    if (tile.isRevenue) {
      return formatMoneyKm(raw is Decimal ? raw : moneyFromJson(raw));
    }
    return '${raw ?? 0}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBackground,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administratorski dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
          ),
          const SizedBox(height: 4),
          Text('Pregled ključnih metrika sistema', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 4
                      : constraints.maxWidth > 800
                          ? 3
                          : 2;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.3,
                    ),
                    itemCount: _tiles.length,
                    itemBuilder: (context, index) {
                      final tile = _tiles[index];
                      return _statCard(
                        tile.title,
                        _valueForTile(tile),
                        tile.icon,
                        sectionKey: tile.sectionKey,
                        subtitle: tile.isRevenue ? 'Ukupan prihod' : null,
                      );
                    },
                  );
                },
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Osvježi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon, {
    required String sectionKey,
    String? subtitle,
  }) {
    final canNavigate = widget.onNavigate != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canNavigate ? () => widget.onNavigate!(sectionKey) : null,
        hoverColor: AppColors.primaryYellow.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.3),
                child: Icon(icon, color: AppColors.darkBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey.shade600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
              if (canNavigate) Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
