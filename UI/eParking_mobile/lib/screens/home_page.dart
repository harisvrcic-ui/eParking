import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/parking_data_refresh.dart';
import '../models/login_response.dart';
import '../models/news_item.dart';
import '../models/parking_lot_display.dart';
import '../models/user_preferences.dart';
import '../services/location_service.dart';
import '../services/news_service.dart';
import '../services/parking_service.dart';
import '../services/recommendation_engine.dart';
import '../services/reservation_service.dart';
import '../services/user_notification_service.dart';
import '../services/parking_lot_view_history_api_service.dart';
import '../l10n/app_strings.dart';
import '../utils/search_text.dart';
import '../widgets/news_image.dart';
import '../widgets/parking_lot_card.dart';
import 'parking_lot_detail_screen.dart';
import 'profile_notifications_screen.dart';
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.preferences,
    this.onPreferencesTap,
  });

  final LoginResponse user;
  final UserPreferences preferences;
  final VoidCallback? onPreferencesTap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _pollInterval = Duration(seconds: 12);

  final _parkingService = ParkingService();
  final _reservationService = ReservationService();
  final _locationService = LocationService();
  final _newsService = NewsService();
  final _notificationService = UserNotificationService();
  final _viewHistoryApi = ParkingLotViewHistoryApiService();
  final _searchController = TextEditingController();

  List<ParkingLotDisplay> _lots = [];
  List<NewsItem> _news = [];
  int _unreadNotifications = 0;
  Timer? _notificationPollTimer;
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
    _loadNews();
    _refreshNotifications();
    _notificationPollTimer = Timer.periodic(_pollInterval, (_) => _refreshNotifications());
    _searchController.addListener(_applyFilter);
    ParkingDataRefresh.tick.addListener(_onParkingDataChanged);
  }

  void _onParkingDataChanged() {
    _load();
    _refreshNotifications();
  }

  @override
  void dispose() {
    _notificationPollTimer?.cancel();
    ParkingDataRefresh.tick.removeListener(_onParkingDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    try {
      final news = await _newsService.getActiveNewsWithImages();
      if (mounted) setState(() => _news = news);
    } catch (_) {}
  }

  Future<void> _refreshNotifications() async {
    try {
      final count = await _notificationService.unreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  void _openNotifications() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ProfileNotificationsScreen(userId: widget.user.id),
          ),
        )
        .then((_) => _refreshNotifications());
  }
  List<ParkingLotDisplay> _allLots = [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Position? position;
      try {
        position = await _locationService.getCurrentPosition();
      } catch (_) {}

      final results = await Future.wait([
        _parkingService.getParkingLotsOverview(),
        _parkingService.getParkingSpots(),
        _reservationService.getMyReservations(),
        _viewHistoryApi.getMy(),
      ]);

      final overviews = results[0];
      final spots = results[1];
      final reservations = results[2];
      final viewHistory = results[3];

      _allLots = RecommendationEngine().buildDisplayList(
        overviews: overviews.cast(),
        spots: spots.cast(),
        user: widget.user,
        preferences: widget.preferences,
        reservations: reservations.cast(),
        viewCountByLotId: ParkingLotViewHistoryApiService.toViewCountByLotId(
          viewHistory.cast(),
        ),
        userPosition: position,
      );
      _applyFilter();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _lots = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim();
    setState(() {
      _lots = q.isEmpty
          ? _allLots
          : _allLots.where((l) => SearchText.contains(l.lot.name, q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final firstName = widget.user.firstName.isNotEmpty
        ? widget.user.firstName
        : widget.user.username;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_load(), _loadNews(), _refreshNotifications()]);
      },      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      firstName[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.hello(firstName),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: _openNotifications,
                    icon: Badge(
                      isLabelVisible: _unreadNotifications > 0,
                      label: Text('$_unreadNotifications'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                  ),                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Material(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onPreferencesTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.mySettings,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_news.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Obavijesti',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _news.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = _news[index];
                          return SizedBox(
                            width: 280,
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  newsImage(item.image, height: 100),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.createdAt.day}.${item.createdAt.month}.${item.createdAt.year}.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(                controller: _searchController,
                decoration: InputDecoration(
                  hintText: s.searchParkingHint,
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
                      FilledButton(onPressed: _load, child: Text(s.retry)),
                    ],
                  ),
                ),
              ),
            )
          else if (_lots.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(s.noParkingLots)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: _lots.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _lots[index];
                  return ParkingLotCard(
                    item: item,
                    onViewDetails: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParkingLotDetailScreen(
                            lotId: item.lot.id,
                            lotName: item.lot.name,
                            userId: widget.user.id,
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
    );
  }
}
