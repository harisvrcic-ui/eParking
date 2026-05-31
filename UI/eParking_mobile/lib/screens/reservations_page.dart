import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../utils/reservation_time.dart';
import '../widgets/dialog_helpers.dart';
import '../widgets/reservation_card.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key, required this.userId});

  final int userId;

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final _service = ReservationService();

  List<Reservation> _active = [];
  List<Reservation> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final all = await _service.getMyReservations();
      setState(() {
        _active = all.where((r) => reservationIsNotEnded(r.endDate)).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        _history = all.where((r) => !reservationIsNotEnded(r.endDate)).toList()
          ..sort((a, b) => b.endDate.compareTo(a.endDate));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _cancel(Reservation reservation) async {
    final s = context.s;
    final confirm = await showDestructiveConfirmDialog(
      context,
      title: s.cancelReservationQuestion,
      message: s.cancelReservation,
      details:
          '${reservation.locationTitle}\n${_formatRange(reservation.startDate, reservation.endDate)}',
      confirmLabel: s.yesCancel,
      destructive: true,
    );

    if (!confirm) return;

    try {
      await _service.cancelReservation(reservation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.reservationCancelled)),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatRange(DateTime start, DateTime end) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);

    final timePart = '${_formatTime(start)} - ${_formatTime(end)}';
    if (startDay == today) {
      return 'Danas, $timePart';
    }
    return '${start.day}.${start.month}.${start.year}., $timePart';
  }

  static String _statusLabel(Reservation r, AppStrings s) {
    if (r.isCancelled) return 'Otkazano';
    if (r.isCompleted) return 'Završeno';
    if (r.isPending) return s.statusPending;
    if (r.isConfirmed) return s.statusConfirmed;
    return r.status;
  }

  static Color _statusColor(Reservation r) {
    if (r.isCancelled) return Colors.red.shade400;
    if (r.isCompleted) return Colors.green.shade600;
    if (r.isPending) return Colors.orange.shade700;
    if (r.isConfirmed) return Colors.teal.shade600;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Moje rezervacije'),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
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
                          child: const Text('Pokušaj ponovo'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      _SectionHeader(title: 'Aktivne rezervacije'),
                      if (_active.isEmpty)
                        const _EmptyHint(text: 'Nema aktivnih rezervacija.')
                      else
                        ..._active.map(
                          (r) => ReservationCard(
                            reservation: r,
                            timeLabel: _formatRange(r.startDate, r.endDate),
                            statusLabel: _statusLabel(r, s),
                            statusColor: _statusColor(r),
                            onCancel: r.isCancelled || r.isCompleted
                                ? null
                                : () => _cancel(r),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _SectionHeader(title: 'Historija rezervacija'),
                      if (_history.isEmpty)
                        const _EmptyHint(text: 'Nema prethodnih rezervacija.')
                      else
                        ..._history.map(
                          (r) => ReservationCard(
                            reservation: r,
                            timeLabel: _formatRange(r.startDate, r.endDate),
                            statusLabel: _statusLabel(r, s),
                            statusColor: _statusColor(r),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}
