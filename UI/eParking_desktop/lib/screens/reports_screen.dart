import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/api_client.dart';
import '../utils/money.dart';
import '../widgets/management_page_layout.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiClient();
  final _dateFormat = DateFormat('MMM d, yyyy HH:mm', 'bs');
  final _shortDateFormat = DateFormat('MMM d', 'bs');

  bool _loading = true;
  int _chartDays = 30;
  int _pageSize = 10;
  int _currentPage = 0;
  String _transactionSearch = '';

  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _lots = [];
  List<Map<String, dynamic>> _spots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getList('/Reservations'),
        _api.getList('/MyAppUsers'),
        _api.getList('/ParkingLots'),
        _api.getList('/ParkingSpots', query: {'isActive': 'true'}),
      ]);
      _reservations = results[0].cast<Map<String, dynamic>>();
      _users = results[1].cast<Map<String, dynamic>>();
      _lots = results[2].cast<Map<String, dynamic>>();
      _spots = results[3].cast<Map<String, dynamic>>();
    } catch (_) {
      _reservations = [];
      _users = [];
      _lots = [];
      _spots = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.parse(value.toString()).toLocal();
  }

  bool _inMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  Decimal _sumRevenue(Iterable<Map<String, dynamic>> items) =>
      items.fold(Decimal.zero, (s, r) => s + moneyFromJson(r['finalPrice']));

  String _reservationStatus(Map<String, dynamic> r) {
    final status = r['status']?.toString();
    if (status != null && status.isNotEmpty) {
      return switch (status) {
        'Pending' => 'Na čekanju',
        'Confirmed' => 'Aktivno',
        'Cancelled' => 'Otkazano',
        'Completed' => 'Završeno',
        _ => status,
      };
    }

    final now = DateTime.now();
    final start = _parseDate(r['startDate']);
    final end = _parseDate(r['endDate']);
    if (now.isBefore(start)) return 'Zakazano';
    if (now.isAfter(end)) return 'Završeno';
    return 'Aktivno';
  }

  List<Map<String, dynamic>> _filteredReservations() {
    if (_transactionSearch.trim().isEmpty) return _reservations;
    final q = _transactionSearch.trim().toLowerCase();
    return _reservations.where((r) {
      final fields = [
        r['userFullName'],
        r['parkingLotName'],
        r['parkingSpotDisplayName'],
        r['licensePlate'],
        r['status'],
        _reservationStatus(r),
      ];
      return fields.any((v) => v?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Widget _statusBadge(String status) {
    final isActive = status == 'Aktivno';
    final isDone = status == 'Završeno';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.activeGreenBg
            : isActive
                ? const Color(0xFFE3F2FD)
                : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isDone
              ? AppColors.activeGreen
              : isActive
                  ? const Color(0xFF1565C0)
                  : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  pw.Document _buildMonthlySummaryPdf() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final thisMonthRes =
        _reservations.where((r) => _inMonth(_parseDate(r['createdAt']), monthStart));
    final revenue = _sumRevenue(thisMonthRes);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('eParking — Mjesečni sažetak')),
          pw.Text('Datum izvještaja: ${DateFormat.yMMMd('bs').format(now)}'),
          pw.SizedBox(height: 12),
          pw.Text('Ukupan prihod (ovaj mjesec): ${formatMoneyKm(revenue)}'),
          pw.Text('Ukupno rezervacija (ovaj mjesec): ${thisMonthRes.length}'),
          pw.Text(
            'Novi korisnici (ovaj mjesec): '
            '${_users.where((u) => _inMonth(_parseDate(u['createdAt']), monthStart)).length}',
          ),
          pw.Text('Aktivni parkinzi: ${_lots.where((l) => l['isActive'] == true).length}'),
          pw.SizedBox(height: 16),
          pw.Text('Posljednje rezervacije (max. 50):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Korisnik', 'Parkir', 'Mjesto', 'Vrijeme', 'Iznos', 'Status'],
            data: _reservations.take(50).map((r) {
              return [
                r['userFullName']?.toString() ?? '',
                r['parkingLotName']?.toString() ?? '',
                r['parkingSpotDisplayName']?.toString() ?? '',
                _dateFormat.format(_parseDate(r['startDate'])),
                formatMoneyKmFromJson(r['finalPrice']),
                _reservationStatus(r),
              ];
            }).toList(),
          ),
        ],
      ),
    );
    return doc;
  }

  /// Grupiše rezervacije po korisniku — drugi PDF izvještaj (RS2).
  pw.Document _buildUsersReportPdf() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    final statsByUser = <int, _UserReservationStats>{};
    for (final r in _reservations) {
      final userId = r['userId'] as int? ?? 0;
      if (userId == 0) continue;
      final price = moneyFromJson(r['finalPrice']);
      final created = _parseDate(r['createdAt']);
      statsByUser.putIfAbsent(userId, () => _UserReservationStats()).add(price, created, monthStart);
    }

    final rows = <Map<String, dynamic>>[];
    for (final u in _users) {
      final id = u['id'] as int;
      final stats = statsByUser[id] ?? _UserReservationStats();
      rows.add({
        'username': u['username']?.toString() ?? '',
        'name': '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim(),
        'email': u['email']?.toString() ?? '',
        'total': stats.totalCount,
        'month': stats.monthCount,
        'spent': stats.totalSpent,
        'active': u['isActive'] == true ? 'Da' : 'Ne',
      });
    }
    rows.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

    final withReservations = rows.where((r) => (r['total'] as int) > 0).length;
    final top = rows.take(30).toList();

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('eParking — Izvještaj o korisnicima')),
          pw.Text('Datum izvještaja: ${DateFormat.yMMMd('bs').format(now)}'),
          pw.SizedBox(height: 12),
          pw.Text('Ukupno registriranih korisnika: ${_users.length}'),
          pw.Text('Korisnika s barem jednom rezervacijom: $withReservations'),
          pw.Text(
            'Novi korisnici (ovaj mjesec): '
            '${_users.where((u) => _inMonth(_parseDate(u['createdAt']), monthStart)).length}',
          ),
          pw.SizedBox(height: 16),
          pw.Text('Pregled po broju rezervacija (top 30):',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Korisnik',
              'Ime',
              'Email',
              'Rezervacije',
              'Ovaj mj.',
              'Ukupno KM',
              'Aktivan',
            ],
            data: top
                .map(
                  (r) => [
                    r['username'],
                    r['name'],
                    r['email'],
                    '${r['total']}',
                    r['month'].toString(),
                    formatMoney(r['spent'] as Decimal),
                    r['active'],
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return doc;
  }

  Future<void> _printPdf(pw.Document doc) async {
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _downloadPdf(pw.Document doc, String filename) async {
    await Printing.sharePdf(bytes: await doc.save(), filename: filename);
  }

  Future<void> _exportMonthlySummary({required bool download}) async {
    final doc = _buildMonthlySummaryPdf();
    if (download) {
      await _downloadPdf(doc, 'eparking-mjesecni-sazetak.pdf');
    } else {
      await _printPdf(doc);
    }
  }

  Future<void> _exportUsersReport({required bool download}) async {
    final doc = _buildUsersReportPdf();
    if (download) {
      await _downloadPdf(doc, 'eparking-korisnici.pdf');
    } else {
      await _printPdf(doc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    final thisMonthRes =
        _reservations.where((r) => _inMonth(_parseDate(r['createdAt']), thisMonth)).toList();
    final lastMonthRes =
        _reservations.where((r) => _inMonth(_parseDate(r['createdAt']), lastMonth)).toList();

    final revenue = _sumRevenue(thisMonthRes);
    final lastRevenue = _sumRevenue(lastMonthRes);
    final revenueDelta = revenue - lastRevenue;
    final revenuePct = _percentChange(revenue.toDouble(), lastRevenue.toDouble());

    final resCount = thisMonthRes.length;
    final lastResCount = lastMonthRes.length;
    final resPct = _percentChange(resCount.toDouble(), lastResCount.toDouble());

    final newUsers = _users.where((u) => _inMonth(_parseDate(u['createdAt']), thisMonth)).length;
    final lastNewUsers = _users.where((u) => _inMonth(_parseDate(u['createdAt']), lastMonth)).length;
    final usersPct = _percentChange(newUsers.toDouble(), lastNewUsers.toDouble());

    final activeLots = _lots.where((l) => l['isActive'] == true).length;

    final filteredRes = _filteredReservations();
    final sortedRes = [...filteredRes]
      ..sort((a, b) => ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0));
    final totalPages = sortedRes.isEmpty ? 1 : (sortedRes.length / _pageSize).ceil();
    final pageStart = (_currentPage * _pageSize).clamp(0, sortedRes.length);
    final pageEnd = (pageStart + _pageSize).clamp(0, sortedRes.length);
    final paged = pageStart >= sortedRes.length ? <Map<String, dynamic>>[] : sortedRes.sublist(pageStart, pageEnd);

    return Container(
      color: AppColors.pageBackground,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth > 1100 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: cols,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.4,
                          children: [
                            _kpiCard(
                              'Ukupan prihod (ovaj mjesec)',
                              formatMoneyKm(revenue),
                              revenuePct,
                              subtitle: revenueDelta >= Decimal.zero
                                  ? '+${formatMoney(revenueDelta)} KM u odnosu na prošli mjesec'
                                  : '${formatMoney(revenueDelta)} KM u odnosu na prošli mjesec',
                            ),
                            _kpiCard(
                              'Ukupno rezervacija',
                              '$resCount',
                              resPct,
                              subtitle: 'U odnosu na prošli mjesec',
                            ),
                            _kpiCard(
                              'Novi korisnici',
                              '$newUsers',
                              usersPct,
                              subtitle: 'U odnosu na prošli mjesec',
                            ),
                            _kpiCard(
                              'Aktivni parkinzi',
                              '$activeLots',
                              null,
                              subtitle: 'Trenutno aktivnih lokacija',
                              showTrend: false,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 900) {
                          return Column(
                            children: [
                              _revenueChartCard(),
                              const SizedBox(height: 16),
                              _occupancyChartCard(),
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 3, child: _revenueChartCard()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _occupancyChartCard()),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTransactionsTable(paged, sortedRes.length, totalPages),
                  ],
                ),
            ),
    );
  }

  double? _percentChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Izvještaji i analitika',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
              ),
              SizedBox(height: 4),
              Text(
                'Pregled poslovanja i performansi parkirnog sistema',
                style: TextStyle(fontSize: 15, color: Color(0xFF757575)),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Osvježi'),
        ),
        const SizedBox(width: 12),
        _pdfReportActions(
          title: '1. Mjesečni sažetak',
          onPrint: () => _exportMonthlySummary(download: false),
          onDownload: () => _exportMonthlySummary(download: true),
        ),
        const SizedBox(width: 12),
        _pdfReportActions(
          title: '2. Korisnici',
          onPrint: () => _exportUsersReport(download: false),
          onDownload: () => _exportUsersReport(download: true),
        ),
      ],
    );
  }

  Widget _pdfReportActions({
    required String title,
    required VoidCallback onPrint,
    required VoidCallback onDownload,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _loading ? null : onPrint,
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Štampaj'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : onDownload,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Preuzmi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    double? trendPct, {
    required String subtitle,
    bool showTrend = true,
  }) {
    final positive = (trendPct ?? 0) >= 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                if (showTrend && trendPct != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: positive ? AppColors.activeGreenBg : const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          positive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14,
                          color: positive ? AppColors.activeGreen : Colors.red.shade700,
                        ),
                        Text(
                          '${trendPct.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: positive ? AppColors.activeGreen : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _revenueChartCard() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: _chartDays - 1));
    final daily = <DateTime, double>{};
    for (var i = 0; i < _chartDays; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      daily[d] = 0;
    }
    for (final r in _reservations) {
      final created = _parseDate(r['createdAt']);
      final day = DateTime(created.year, created.month, created.day);
      if (!daily.containsKey(day)) continue;
      daily[day] = (daily[day] ?? 0) + moneyFromJson(r['finalPrice']).toDouble();
    }

    final spots = daily.entries.toList();
    final maxY = spots.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final chartMax = maxY <= 0 ? 10.0 : maxY * 1.15;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Trend prihoda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
                  ),
                ),
                DropdownButton<int>(
                  value: _chartDays,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('Zadnjih 7 dana')),
                    DropdownMenuItem(value: 30, child: Text('Zadnjih 30 dana')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _chartDays = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: chartMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMax / 4,
                    getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (_chartDays / 5).ceilToDouble().clamp(1, 30),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= spots.length) return const SizedBox.shrink();
                          if (_chartDays == 30 && idx % 5 != 0 && idx != spots.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _shortDateFormat.format(spots[idx].key),
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < spots.length; i++)
                          FlSpot(i.toDouble(), spots[i].value),
                      ],
                      isCurved: true,
                      color: const Color(0xFF5C6BC0),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF5C6BC0).withValues(alpha: 0.35),
                            const Color(0xFF5C6BC0).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _occupancyByZone() {
    final zoneTotals = <String, int>{};
    final zoneOccupied = <String, int>{};
    final spotZone = <int, String>{};

    for (final s in _spots) {
      final zone = s['zoneName']?.toString() ?? 'Nepoznata zona';
      if (zone.isEmpty) continue;
      zoneTotals[zone] = (zoneTotals[zone] ?? 0) + 1;
      spotZone[s['id'] as int] = zone;
    }

    final now = DateTime.now();
    for (final r in _reservations) {
      final start = _parseDate(r['startDate']);
      final end = _parseDate(r['endDate']);
      if (now.isBefore(start) || now.isAfter(end)) continue;
      final spotId = r['parkingSpotId'] as int?;
      final zone = spotId != null ? spotZone[spotId] : null;
      if (zone == null) continue;
      zoneOccupied[zone] = (zoneOccupied[zone] ?? 0) + 1;
    }

    final result = <String, double>{};
    for (final entry in zoneTotals.entries) {
      final occupied = zoneOccupied[entry.key] ?? 0;
      result[entry.key] = entry.value == 0 ? 0 : (occupied / entry.value) * 100;
    }
    result.removeWhere((_, v) => v.isNaN);
    if (result.isEmpty) {
      return {'Zona 1': 0, 'Zona 2': 0};
    }
    return result;
  }

  Widget _occupancyChartCard() {
    final occupancy = _occupancyByZone();
    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFFFFB74D),
      const Color(0xFFEF5350),
    ];
    final entries = occupancy.entries.toList();
    final totalPct = entries.fold<double>(0, (s, e) => s + e.value);
    final normalized = totalPct <= 0
        ? entries.map((e) => MapEntry(e.key, 100.0 / entries.length)).toList()
        : entries;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Popunjenost po zoni',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 52,
                        sections: [
                          for (var i = 0; i < normalized.length; i++)
                            PieChartSectionData(
                              value: normalized[i].value <= 0 ? 1 : normalized[i].value,
                              color: colors[i % colors.length],
                              radius: 42,
                              title: '${normalized[i].value.toStringAsFixed(0)}%',
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < normalized.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${normalized[i].key} (${normalized[i].value.toStringAsFixed(0)}%)',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Ukupno',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTable(
    List<Map<String, dynamic>> paged,
    int total,
    int totalPages,
  ) {
    final start = total == 0 ? 0 : _currentPage * _pageSize + 1;
    final end = ((_currentPage + 1) * _pageSize).clamp(0, total);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ukupno transakcija: $total',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Pretraži po korisniku, parkingu, mjestu ili statusu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _transactionSearch = value;
                  _currentPage = 0;
                });
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Stranica: ${_currentPage + 1} od $totalPages',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (paged.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Nema transakcija za prikaz.')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 890,
                  child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(150),
                    1: FixedColumnWidth(140),
                    2: FixedColumnWidth(140),
                    3: FixedColumnWidth(200),
                    4: FixedColumnWidth(88),
                    5: FixedColumnWidth(120),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: _headerCells(const [
                        'KORISNIK',
                        'PARKIR',
                        'MJESTO',
                        'VRIJEME REZERVACIJE',
                        'IZNOS',
                        'STATUS',
                      ]),
                    ),
                    ...paged.map((r) {
                      final status = _reservationStatus(r);
                      return TableRow(
                        children: [
                          _cell(r['userFullName']?.toString() ?? ''),
                          _cell(r['parkingLotName']?.toString() ?? ''),
                          _cell(r['parkingSpotDisplayName']?.toString() ?? ''),
                          _cell(_dateFormat.format(_parseDate(r['startDate']))),
                          _cell(formatMoneyKmFromJson(r['finalPrice'])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: _statusBadge(status),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Prikaz $start do $end od $total',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const Spacer(),
                const Text('Prikaži:'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _pageSize,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5')),
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 25, child: Text('25')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _pageSize = v;
                        _currentPage = 0;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                const Text('po stranici'),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  child: const Text('< Prethodna'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  child: const Text('Sljedeća >'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _headerCells(List<String> headers) {
    return headers
        .map(
          (h) => Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              h,
              maxLines: 2,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
                fontSize: 12,
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _cell(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );

}

class _UserReservationStats {
  int totalCount = 0;
  int monthCount = 0;
  Decimal totalSpent = Decimal.zero;

  void add(Decimal price, DateTime created, DateTime monthStart) {
    totalCount++;
    totalSpent += price;
    if (created.year == monthStart.year && created.month == monthStart.month) {
      monthCount++;
    }
  }
}
