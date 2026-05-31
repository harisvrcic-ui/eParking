import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/favorite_parking_lot.dart';
import '../services/favorite_service.dart';
import '../widgets/form_navigation.dart';
import 'parking_lot_detail_screen.dart';

class ProfileFavoritesScreen extends StatefulWidget {
  const ProfileFavoritesScreen({super.key, required this.userId});

  final int userId;

  @override
  State<ProfileFavoritesScreen> createState() => _ProfileFavoritesScreenState();
}

class _ProfileFavoritesScreenState extends State<ProfileFavoritesScreen> {
  final _service = FavoriteService();
  List<FavoriteParkingLot> _items = [];
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

  Future<void> _remove(FavoriteParkingLot item, AppStrings s) async {
    try {
      await _service.remove(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.removedFromFavorites)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
          appBar: formScreenAppBar(context, title: s.myFavoritesTitle),
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
                                s.noFavorites,
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
                                    Icons.local_parking,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  title: Text(
                                    item.parkingLotName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    DateFormat.yMMMd().add_Hm().format(item.createdAt.toLocal()),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red),
                                    tooltip: s.removedFromFavorites,
                                    onPressed: () => _remove(item, s),
                                  ),
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
