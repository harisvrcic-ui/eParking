import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../screens/forms/form_helpers.dart' show showCancelReservationDialog, showDeleteConfirmDialog;
import 'management_page_layout.dart';

typedef ListReload = Future<void> Function();

typedef CrudRowBuilder = ManagementRow Function(
  Map<String, dynamic> item,
  ListReload reload, {
  VoidCallback? onEdit,
  VoidCallback? onDelete,
});

typedef ItemFilter = bool Function(Map<String, dynamic> item, String query);
typedef FormCallback = Future<void> Function(
  BuildContext context,
  Map<String, dynamic>? item,
  ListReload reload,
);

class GenericCrudPage extends StatefulWidget {
  const GenericCrudPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.endpoint,
    required this.searchHint,
    required this.totalItemLabel,
    required this.columnHeaders,
    required this.buildRow,
    required this.showForm,
    this.filter,
    this.queryParams,
    this.filterBar,
    this.cancelInsteadOfDelete = false,
  });

  final String title;
  final String subtitle;
  final String endpoint;
  final String searchHint;
  final String totalItemLabel;
  final List<String> columnHeaders;
  final CrudRowBuilder buildRow;
  final FormCallback showForm;
  final ItemFilter? filter;
  final Map<String, String>? queryParams;
  final Widget? filterBar;
  final bool cancelInsteadOfDelete;

  @override
  State<GenericCrudPage> createState() => _GenericCrudPageState();
}

class _GenericCrudPageState extends State<GenericCrudPage> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  String _query = '';

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
      final data = await _api.getList(widget.endpoint, query: widget.queryParams);
      _items = data.cast<Map<String, dynamic>>();
      _items.sort((a, b) => _itemId(b).compareTo(_itemId(a)));
      _applyFilter();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static int _itemId(Map<String, dynamic> item) {
    final id = item['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return 0;
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = List.from(_items);
    } else {
      final q = _query.toLowerCase();
      _filtered = _items.where((item) {
        if (widget.filter != null) return widget.filter!(item, q);
        return item.values.any((v) => v?.toString().toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  Future<void> _confirmDelete(int id) async {
    try {
      if (widget.cancelInsteadOfDelete) {
        final reason = await showCancelReservationDialog(
          context,
          title: 'Otkaži rezervaciju',
        );
        if (reason == null) return;

        await _api.post('${widget.endpoint}/$id/cancel', {'reason': reason});
      } else {
        final ok = await showDeleteConfirmDialog(
          context,
          itemLabel: widget.totalItemLabel.toLowerCase(),
        );
        if (!ok) return;

        await _api.delete(widget.endpoint, id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cancelInsteadOfDelete
                ? 'Rezervacija je otkazana.'
                : 'Zapis je uspješno obrisan.'),
          ),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered.map((item) {
      return widget.buildRow(
        item,
        () => _load(),
        onEdit: () => widget.showForm(context, item, _load),
        onDelete: () => _confirmDelete(item['id'] as int),
      );
    }).toList();

    final page = ManagementPageLayout(
      title: widget.title,
      subtitle: widget.subtitle,
      searchHint: widget.searchHint,
      totalLabel: 'Total ${widget.totalItemLabel}: ${_filtered.length}',
      columnHeaders: widget.columnHeaders,
      rows: rows,
      isLoading: _loading,
      error: _error,
      onRefresh: _load,
      onAdd: () => widget.showForm(context, null, _load),
      onSearchChanged: (q) {
        setState(() {
          _query = q;
          _applyFilter();
        });
      },
    );

    if (widget.filterBar == null) return page;

    return Container(
      color: AppColors.pageBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: widget.filterBar!,
          ),
          Expanded(child: page),
        ],
      ),
    );
  }
}
