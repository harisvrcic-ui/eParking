import 'package:flutter/material.dart';

class AppColors {
  static const primaryYellow = Color(0xFFFFD600);
  static const darkBlue = Color(0xFF1A237E);
  static const pageBackground = Color(0xFFF5F6FA);
  static const activeGreen = Color(0xFF2E7D32);
  static const activeGreenBg = Color(0xFFE8F5E9);
}

class ManagementPageLayout extends StatefulWidget {
  const ManagementPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    required this.totalLabel,
    required this.columnHeaders,
    required this.rows,
    required this.onRefresh,
    this.onAdd,
    this.onSearchChanged,
    this.isLoading = false,
    this.error,
    this.emptyMessage = 'No records found.',
  });

  final String title;
  final String subtitle;
  final String searchHint;
  final String totalLabel;
  final List<String> columnHeaders;
  final List<ManagementRow> rows;
  final VoidCallback onRefresh;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onSearchChanged;
  final bool isLoading;
  final String? error;
  final String emptyMessage;

  @override
  State<ManagementPageLayout> createState() => _ManagementPageLayoutState();
}

class ManagementRow {
  ManagementRow({
    required this.cells,
    this.onEdit,
    this.onDelete,
    this.extraActions = const [],
  });

  final List<Widget> cells;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final List<Widget> extraActions;
}

class _ManagementPageLayoutState extends State<ManagementPageLayout> {
  int _pageSize = 10;
  int _currentPage = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ManagementRow> get _pagedRows {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.rows.length);
    if (start >= widget.rows.length) return [];
    return widget.rows.sublist(start, end);
  }

  int get _totalPages => widget.rows.isEmpty ? 1 : (widget.rows.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.pageBackground,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Text(
              widget.totalLabel,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Page: ${_currentPage + 1} of $_totalPages',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildTable()),
            const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Tooltip(
          message: widget.isLoading ? 'Učitavanje podataka…' : 'Osvježi listu',
          child: OutlinedButton.icon(
            onPressed: widget.isLoading ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
        const SizedBox(width: 12),
        if (widget.onAdd != null)
          Tooltip(
            message: widget.isLoading ? 'Pričekajte da se podaci učitaju' : 'Dodaj novi zapis',
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 0,
              ),
              child: Text(_addButtonLabel()),
            ),
          ),
      ],
    );
  }

  String _addButtonLabel() {
    if (widget.title.contains('Lots')) return 'Add Parking Lot';
    if (widget.title.contains('Users')) return 'Add User';
    if (widget.title.contains('Spots')) return 'Add Parking Spot';
    if (widget.title.contains('Zones')) return 'Add Zone';
    return 'Add New';
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: widget.onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.searchHint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.error != null) {
      return Center(child: Text(widget.error!, style: const TextStyle(color: Colors.red)));
    }
    if (widget.rows.isEmpty) {
      return Center(child: Text(widget.emptyMessage));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          child: Table(
            columnWidths: {
              for (var i = 0; i < widget.columnHeaders.length; i++)
                i: const FlexColumnWidth(1.2),
              widget.columnHeaders.length: const FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  ...widget.columnHeaders.map(
                    (h) => Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        h.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'ACTIONS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              ..._pagedRows.map(_buildDataRow),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildDataRow(ManagementRow row) {
    return TableRow(
      children: [
        ...row.cells.map(
          (cell) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: cell,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...row.extraActions,
              _actionIcon(Icons.edit_outlined, row.onEdit, tooltip: 'Uredi'),
              _actionIcon(Icons.delete_outline, row.onDelete, tooltip: 'Obriši'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback? onTap, {String? tooltip}) {
    final disabled = onTap == null;
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: disabled ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip, child: child);
  }

  Widget _buildFooter() {
    final start = widget.rows.isEmpty ? 0 : _currentPage * _pageSize + 1;
    final end = ((_currentPage + 1) * _pageSize).clamp(0, widget.rows.length);

    return Row(
      children: [
        Text(
          'Showing $start to $end of ${widget.rows.length}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const Spacer(),
        const Text('Show:'),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _pageSize,
          items: const [
            DropdownMenuItem(value: 5, child: Text('5')),
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
          ],
          onChanged: (v) {
            if (v != null) setState(() {
              _pageSize = v;
              _currentPage = 0;
            });
          },
        ),
        const SizedBox(width: 8),
        const Text('per page'),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
          child: const Text('< Prev'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _currentPage < _totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
          child: const Text('Next >'),
        ),
      ],
    );
  }
}

Widget statusBadge(String status) {
  final isActive = status.toLowerCase() == 'active';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isActive ? AppColors.activeGreenBg : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: isActive ? AppColors.activeGreen : Colors.grey.shade700,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),
  );
}
