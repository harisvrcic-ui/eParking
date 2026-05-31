import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/parking_data_refresh.dart';
import '../models/lookup_item.dart';
import '../models/parking_lot_overview.dart';
import '../services/location_service.dart';
import '../services/lookup_service.dart';
import '../l10n/app_strings.dart';
import '../services/parking_service.dart';
import '../utils/search_text.dart';
import '../widgets/parking_search_card.dart';
import 'parking_lot_detail_screen.dart';

enum AvailabilityFilter { any, availableOnly }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.userId});

  final int userId;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _parkingService = ParkingService();
  final _lookupService = LookupService();
  final _locationService = LocationService();
  final _searchController = TextEditingController();

  List<_SearchItem> _allItems = [];
  List<_SearchItem> _filteredItems = [];
  List<LookupItem> _cities = [];
  Position? _userPosition;

  bool _loading = true;
  String? _error;
  int? _selectedCityId;
  AvailabilityFilter _availability = AvailabilityFilter.any;

  static const _allCitiesKey = -1;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilters);
    ParkingDataRefresh.tick.addListener(_onParkingDataChanged);
  }

  void _onParkingDataChanged() => _load();

  @override
  void dispose() {
    ParkingDataRefresh.tick.removeListener(_onParkingDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _parkingService.getParkingLotsOverview(),
        _lookupService.getCities(),
        _locationService.getCurrentPosition(),
      ]);

      final overviews = results[0] as List<ParkingLotOverview>;
      _cities = results[1] as List<LookupItem>;
      _userPosition = results[2] as Position?;

      _allItems = overviews.map((o) {
        double? km = LocationService.demoDistanceKmForParkir(o.name);
        if (km == null &&
            _userPosition != null &&
            o.latitude != null &&
            o.longitude != null) {
          km = LocationService.distanceKm(
            _userPosition!.latitude,
            _userPosition!.longitude,
            o.latitude!,
            o.longitude!,
          );
        }
        final distanceLabel =
            km != null ? LocationService.formatDistanceKm(km) : '—';
        return _SearchItem(overview: o, distanceLabel: distanceLabel);
      }).toList();

      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _filteredItems = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    final cityName = _selectedCityId == null || _selectedCityId == _allCitiesKey
        ? null
        : _cities.firstWhere((c) => c.id == _selectedCityId).name.toLowerCase();

    setState(() {
      _filteredItems = _allItems.where((item) {
        if (query.isNotEmpty && !SearchText.contains(item.overview.name, query)) {
          return false;
        }
        if (cityName != null &&
            !LocationService.parkirMatchesCity(item.overview.name, cityName)) {
          return false;
        }
        if (_availability == AvailabilityFilter.availableOnly &&
            item.overview.availableSpots <= 0) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(s.searchTitle),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: s.searchByNameHint,
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
              ),
            ),
            SliverToBoxAdapter(child: _buildFilters(context)),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(s.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_filteredItems.isEmpty)
              SliverFillRemaining(
                child: Center(child: Text(s.noFilterResults)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.separated(
                  itemCount: _filteredItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return ParkingSearchCard(
                      overview: item.overview,
                      distanceLabel: item.distanceLabel,
                      onViewParking: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ParkingLotDetailScreen(
                              lotId: item.overview.id,
                              lotName: item.overview.name,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final s = context.s;
    final cityFilter = _FilterDropdown<int?>(
      label: s.city,
      value: _selectedCityId ?? _allCitiesKey,
      items: [
        DropdownMenuItem(
          value: _allCitiesKey,
          child: Text(s.allCities, overflow: TextOverflow.ellipsis),
        ),
        ..._cities.map(
          (c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (v) {
        setState(() {
          _selectedCityId = v == _allCitiesKey ? null : v;
        });
        _applyFilters();
      },
    );
    final availabilityFilter = _FilterDropdown<AvailabilityFilter>(
      label: s.availability,
      value: _availability,
      items: [
        DropdownMenuItem(
          value: AvailabilityFilter.any,
          child: Text(s.allAvailability, overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: AvailabilityFilter.availableOnly,
          child: Text(s.availableOnly, overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() => _availability = v);
        _applyFilters();
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cityFilter,
                const SizedBox(height: 8),
                availabilityFilter,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: cityFilter),
              const SizedBox(width: 8),
              Expanded(child: availabilityFilter),
            ],
          );
        },
      ),
    );
  }
}

class _SearchItem {
  final ParkingLotOverview overview;
  final String distanceLabel;

  _SearchItem({required this.overview, required this.distanceLabel});
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
