import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/parking_lot_view_history.dart';
import '../services/parking_lot_view_history_api_service.dart';
import '../widgets/form_navigation.dart';
import 'parking_lot_detail_screen.dart';

class ProfileViewHistoryScreen extends StatefulWidget {
  const ProfileViewHistoryScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ProfileViewHistoryScreen> createState() => _ProfileViewHistoryScreenState();
}

class _ProfileViewHistoryScreenState extends State<ProfileViewHistoryScreen> {
  final _service = ParkingLotViewHistoryApiService();
  List<ParkingLotViewHistoryEntry> _items = [];
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
      final items = await _service.getMy();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final s = context.s;
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: formScreenAppBar(context, title: s.viewHistoryTitle),
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
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          if (_items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                s.noViewHistory,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          else
                            ..._items.map(
                              (item) => Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.history,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  title: Text(
                                    item.parkingLotName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${s.viewCountLabel(item.viewCount)} · ${s.lastViewedLabel(DateFormat.yMMMd().add_Hm().format(item.lastViewedAt.toLocal()))}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ParkingLotDetailScreen(
                                          lotId: item.parkingLotId,
                                          lotName: item.parkingLotName,
                                          userId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
