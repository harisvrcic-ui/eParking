import 'package:flutter/material.dart';

import '../models/login_response.dart';
import '../services/auth_service.dart';
import '../widgets/management_page_layout.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'pages/crud_pages.dart';
import 'pages/cars_page.dart';
import 'pages/parking_lots_page.dart';
import 'reports_screen.dart';

enum AdminSection {
  dashboard,
  users,
  parkingLots,
  parkingSpots,
  parkingZones,
  spotTypes,
  reservations,
  reservationTypes,
  brands,
  colors,
  cars,
  cities,
  countries,
  genders,
  favorites,
  notifications,
  news,
  reviews,
  viewHistory,
  reports,
}

class _NavItem {
  const _NavItem(this.section, this.icon, this.label);

  final AdminSection section;
  final IconData icon;
  final String label;
}

const _navItems = [
  _NavItem(AdminSection.dashboard, Icons.dashboard, 'Dashboard'),
  _NavItem(AdminSection.users, Icons.people, 'Korisnici'),
  _NavItem(AdminSection.parkingLots, Icons.local_parking, 'Parkinzi'),
  _NavItem(AdminSection.parkingSpots, Icons.grid_on, 'Parking mjesta'),
  _NavItem(AdminSection.parkingZones, Icons.map, 'Parking zone'),
  _NavItem(AdminSection.spotTypes, Icons.category, 'Tipovi mjesta'),
  _NavItem(AdminSection.reservations, Icons.event, 'Rezervacije'),
  _NavItem(AdminSection.reservationTypes, Icons.schedule, 'Tipovi rezervacija'),
  _NavItem(AdminSection.brands, Icons.directions_car, 'Brendovi'),
  _NavItem(AdminSection.colors, Icons.palette, 'Boje'),
  _NavItem(AdminSection.cars, Icons.garage, 'Vozila'),
  _NavItem(AdminSection.cities, Icons.location_city, 'Gradovi'),
  _NavItem(AdminSection.countries, Icons.public, 'Države'),
  _NavItem(AdminSection.genders, Icons.wc, 'Spolovi'),
  _NavItem(AdminSection.favorites, Icons.favorite, 'Omiljeni'),
  _NavItem(AdminSection.notifications, Icons.notifications, 'Obavještenja'),
  _NavItem(AdminSection.news, Icons.newspaper, 'News'),
  _NavItem(AdminSection.reviews, Icons.rate_review, 'Recenzije'),
  _NavItem(AdminSection.viewHistory, Icons.history, 'Historija pregleda'),
  _NavItem(AdminSection.reports, Icons.bar_chart, 'Izvještaji'),
];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.user});

  final LoginResponse user;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminSection _section = AdminSection.dashboard;

  void _goToSection(String key) {
    final section = switch (key) {
      'users' => AdminSection.users,
      'parkingLots' => AdminSection.parkingLots,
      'parkingSpots' => AdminSection.parkingSpots,
      'parkingZones' => AdminSection.parkingZones,
      'spotTypes' => AdminSection.spotTypes,
      'reservations' => AdminSection.reservations,
      'reservationTypes' => AdminSection.reservationTypes,
      'brands' => AdminSection.brands,
      'colors' => AdminSection.colors,
      'cars' => AdminSection.cars,
      'cities' => AdminSection.cities,
      'countries' => AdminSection.countries,
      'genders' => AdminSection.genders,
      'favorites' => AdminSection.favorites,
      'notifications' => AdminSection.notifications,
      'news' => AdminSection.news,
      'reviews' => AdminSection.reviews,
      'viewHistory' => AdminSection.viewHistory,
      'reports' => AdminSection.reports,
      _ => AdminSection.dashboard,
    };
    setState(() => _section = section);
  }

  Widget _buildPage() {
    return switch (_section) {
      AdminSection.dashboard => DashboardScreen(onNavigate: _goToSection),
      AdminSection.users => const UsersPage(),
      AdminSection.parkingLots => const ParkingLotsPage(),
      AdminSection.parkingSpots => const ParkingSpotsPage(),
      AdminSection.parkingZones => const ParkingZonesPage(),
      AdminSection.spotTypes => const ParkingSpotTypesPage(),
      AdminSection.reservations => const ReservationsPage(),
      AdminSection.reservationTypes => const ReservationTypesPage(),
      AdminSection.brands => const BrandsPage(),
      AdminSection.colors => const ColorsPage(),
      AdminSection.cars => const CarsPage(),
      AdminSection.cities => const CitiesPage(),
      AdminSection.countries => const CountriesPage(),
      AdminSection.genders => const GendersPage(),
      AdminSection.favorites => const FavoriteParkingLotsPage(),
      AdminSection.notifications => const UserNotificationsPage(),
      AdminSection.news => const NewsPage(),
      AdminSection.reviews => const ReviewsPage(),
      AdminSection.viewHistory => const ParkingLotViewHistoriesPage(),
      AdminSection.reports => const ReportsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: ColoredBox(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        Icon(Icons.local_parking, size: 36, color: primary),
                        const SizedBox(height: 6),
                        Text(
                          'eParking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        Text(
                          widget.user.username,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final selected = _section == item.section;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            selected: selected,
                            selectedTileColor: primary.withValues(alpha: 0.12),
                            leading: Icon(
                              item.icon,
                              color: selected ? primary : Colors.grey.shade700,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                color: selected ? primary : Colors.grey.shade800,
                              ),
                            ),
                            onTap: () => setState(() => _section = item.section),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.logout, color: Colors.grey.shade700),
                    title: const Text('Odjava', style: TextStyle(fontSize: 13)),
                    onTap: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }
}
