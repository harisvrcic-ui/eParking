import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/favorite_parking_lot.dart';
import '../models/parking_location.dart';
import '../models/parking_lot_detail.dart';
import '../models/review.dart';
import '../core/parking_data_refresh.dart';
import '../services/location_service.dart';
import '../services/parking_service.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../services/favorite_service.dart';
import '../services/review_service.dart';
import '../services/view_history_service.dart';
import '../utils/reservation_time.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/form_navigation.dart';
import '../widgets/review_editor_dialog.dart';
import 'parking_location_spots_screen.dart';

class ParkingLotDetailScreen extends StatefulWidget {
  const ParkingLotDetailScreen({
    super.key,
    required this.lotId,
    required this.lotName,
    required this.userId,
  });

  final int lotId;
  final String lotName;
  final int userId;

  @override
  State<ParkingLotDetailScreen> createState() => _ParkingLotDetailScreenState();
}

class _ParkingLotDetailScreenState extends State<ParkingLotDetailScreen> {
  final _parkingService = ParkingService();
  final _locationService = LocationService();
  final _reviewService = ReviewService();
  final _reservationService = ReservationService();
  final _favoriteService = FavoriteService();

  ParkingLotDetail? _detail;
  FavoriteParkingLot? _favorite;
  bool _favoriteBusy = false;
  List<ParkingLocationSummary> _locations = [];
  List<Review> _reviews = [];
  Review? _myReview;
  bool _canReview = false;
  String? _distanceLabel;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    ViewHistoryService.recordLotView(widget.lotId, userId: widget.userId);
    ParkingDataRefresh.tick.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    ParkingDataRefresh.tick.removeListener(_load);
    super.dispose();
  }

  bool _sameParkingLot(Reservation r) => r.parkingLotId == widget.lotId;

  bool _reservationAllowsReview(Reservation r) {
    if (!_sameParkingLot(r)) return false;
    if (r.status == 'Completed') return true;
    if (r.status == 'Confirmed' && !reservationIsNotEnded(r.endDate)) return true;
    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detail = await _parkingService.getParkingLotDetail(widget.lotId);
      final reviews = await _reviewService.getForParkingLot(widget.lotId);
      final reservations = await _reservationService.getMyReservations(
        userId: widget.userId,
      );
      final favorite = await _favoriteService.findForLot(widget.lotId);

      Review? myReview;
      for (final review in reviews) {
        if (review.userId == widget.userId) {
          myReview = review;
          break;
        }
      }

      final canReview = reservations.any(_reservationAllowsReview);

      String? distanceLabel;
      final pos = await _locationService.getCurrentPosition();
      final strings = AppStrings.current;
      final distance = LocationService.resolveDistanceResult(
        lotName: detail.name,
        gpsKm: LocationService.distanceKmToLot(
          lotName: detail.name,
          userPosition: pos,
          lotLatitude: detail.latitude,
          lotLongitude: detail.longitude,
        ),
        lotLatitude: detail.latitude,
        lotLongitude: detail.longitude,
      );
      if (distance.km != null) {
        distanceLabel = LocationService.formatDistanceLabel(
          distance,
          gpsSuffix: strings.distanceFromGps,
          centerSuffix: strings.distanceFromCenter,
        );
      }

      if (mounted) {
        setState(() {
          _detail = detail;
          _locations = ParkingLocationSummary.fromLotDetail(detail);
          _reviews = reviews;
          _myReview = myReview;
          _canReview = canReview;
          _distanceLabel = distanceLabel;
          _favorite = favorite;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(AppStrings s) async {
    if (_favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    try {
      if (_favorite != null) {
        await _favoriteService.remove(_favorite!.id);
        if (!mounted) return;
        setState(() => _favorite = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.removedFromFavorites)),
        );
      } else {
        final added = await _favoriteService.add(widget.lotId);
        if (!mounted) return;
        setState(() => _favorite = added);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.addedToFavorites)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _openReviewEditor(AppStrings s) async {
    final saved = await showReviewEditorDialog(
      context: context,
      parkingLotId: widget.lotId,
      strings: s,
      existing: _myReview,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.reviewSaved)),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final s = context.s;
        return Scaffold(
          appBar: formScreenAppBar(
            context,
            title: widget.lotName,
            actions: [
              if (!_loading && _error == null)
                IconButton(
                  icon: _favoriteBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _favorite != null ? Icons.favorite : Icons.favorite_border,
                          color: _favorite != null ? Colors.red : null,
                        ),
                  onPressed: _favoriteBusy ? null : () => _toggleFavorite(s),
                ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
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
                    )
                  : _buildContent(context, _detail!, s),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ParkingLotDetail detail, AppStrings s) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            detail.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DetailInfoRow(
                    icon: Icons.local_parking,
                    label: 'Status',
                    value: detail.status,
                    iconColor: Colors.blue.shade700,
                  ),
                  DetailInfoRow(
                    icon: Icons.grid_view,
                    label: 'Mjesta',
                    value: '${detail.availableSpots} slobodno / ${detail.totalSpots} ukupno',
                  ),
                  DetailInfoRow(
                    icon: Icons.map,
                    label: 'Zone',
                    value: '${detail.zones.length}',
                  ),
                  if (_distanceLabel != null)
                    DetailInfoRow(
                      icon: Icons.location_on,
                      label: 'Udaljenost',
                      value: _distanceLabel!,
                      iconColor: Colors.green.shade600,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...detail.zones.map(
            (z) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      z.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (z.description != null && z.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        z.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pregled mjesta',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_locations.isEmpty)
            Text(
              'Nema dostupnih mjesta.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            FilledButton.icon(
              onPressed: detail.availableSpots == 0
                  ? null
                  : () {
                      final allSpots =
                          _locations.expand((loc) => loc.spots).toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParkingLocationSpotsScreen(
                            locationName: detail.name,
                            spots: allSpots,
                            userId: widget.userId,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.grid_view),
              label: Text(
                detail.availableSpots == 0
                    ? 'Nema slobodnih mjesta'
                    : 'Prikaži mjesta (${detail.availableSpots} / ${detail.totalSpots} slobodno)',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            s.reviewsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_reviews.isNotEmpty)
            Text(
              s.reviewsAverage(
                _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                    _reviews.length,
                _reviews.length,
              ),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          if (_myReview != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openReviewEditor(s),
              icon: const Icon(Icons.edit_outlined),
              label: Text(s.editMyReview),
            ),
          ] else if (_canReview) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _openReviewEditor(s),
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(s.addReview),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              s.reviewNeedCompleted,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            Text(
              s.noReviews,
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ..._reviews.map((review) => _ReviewTile(review: review)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd(
      LocaleController.instance.locale.toString(),
    ).format(review.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.userFullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(dateLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700,
                  size: 18,
                );
              }),
            ),
            if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!.trim()),
            ],
          ],
        ),
      ),
    );
  }
}
