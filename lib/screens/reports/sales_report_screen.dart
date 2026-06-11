import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

enum _DatePreset { today, thisWeek, thisMonth, lastMonth, thisYear, custom }

class SalesReportScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const SalesReportScreen({super.key, required this.onRouteSelected});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  List<Purchase> _allSales = [];
  List<Purchase> _allReturns = [];
  Map<int, double> _saleCosts = {};
  bool _isLoading = true;

  // Date range filter
  _DatePreset _preset = _DatePreset.thisMonth;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _applyPreset(_DatePreset.thisMonth, load: true);
  }

  void _applyPreset(_DatePreset preset, {bool load = false}) {
    final now = DateTime.now();
    DateTime from;
    DateTime to = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case _DatePreset.today:
        from = DateTime(now.year, now.month, now.day);
        break;
      case _DatePreset.thisWeek:
        final weekday = now.weekday; // Mon=1, Sun=7
        from = DateTime(now.year, now.month, now.day - weekday + 1);
        break;
      case _DatePreset.thisMonth:
        from = DateTime(now.year, now.month, 1);
        break;
      case _DatePreset.lastMonth:
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        from = DateTime(lastMonthYear, lastMonth, 1);
        to = DateTime(lastMonthYear, lastMonth + 1 < 13 ? lastMonth + 1 : 1, 1)
            .subtract(const Duration(seconds: 1));
        break;
      case _DatePreset.thisYear:
        from = DateTime(now.year, 1, 1);
        break;
      case _DatePreset.custom:
        // Handled separately via date picker
        return;
    }

    setState(() {
      _preset = preset;
      _fromDate = from;
      _toDate = to;
    });

    if (load) _loadReports();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: _fromDate ?? DateTime(now.year, now.month, 1),
      end: _toDate ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _preset = _DatePreset.custom;
        _fromDate = picked.start;
        _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final from = _fromDate;
      final to = _toDate;
      final allData = await SaleService.instance.getAllSalesHistory(
        filterType: 'All',
        startDate: from,
        endDate: to,
      );
      
      final db = await DatabaseHelper.instance.database;
      final saleIds = allData.map((e) => e.id).toList();
      Map<int, double> saleCosts = {};
      if (saleIds.isNotEmpty) {
        final idsStr = saleIds.join(',');
        final costMaps = await db.rawQuery('SELECT sale_id, SUM(cost_price * quantity) as total_cost FROM sale_items WHERE sale_id IN ($idsStr) GROUP BY sale_id');
        saleCosts = { for (var row in costMaps) row['sale_id'] as int: (row['total_cost'] as num).toDouble() };
      }

      final sales = allData.where((s) => s.type == 'Sale').toList();
      final returns = allData.where((s) => s.type == 'SaleReturn').toList();

      if (mounted) {
        setState(() {
          _allSales = sales;
          _allReturns = returns;
          _saleCosts = saleCosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _buildChartData() {
    // Build chart grouped by day or month depending on range
    final from = _fromDate;
    final to = _toDate;
    if (from == null || to == null) return [];

    final diff = to.difference(from).inDays;
    final Map<String, Map<String, double>> map = {};

    // Choose grouping: daily (<=31 days), weekly (<=90 days), monthly (>90)
    String Function(DateTime) keyFn;
    if (diff <= 31) {
      keyFn = (d) => DateFormat('dd MMM').format(d);
    } else if (diff <= 90) {
      // Group by week start
      keyFn = (d) {
        final weekStart = d.subtract(Duration(days: d.weekday - 1));
        return DateFormat('dd MMM').format(weekStart);
      };
    } else {
      keyFn = (d) => DateFormat('MMM yy').format(d);
    }

    // Pre-populate keys for the range
    DateTime cursor = from;
    while (!cursor.isAfter(to)) {
      final key = keyFn(cursor);
      map.putIfAbsent(key, () => {'sales': 0.0, 'profit': 0.0});
      cursor = diff <= 31
          ? cursor.add(const Duration(days: 1))
          : diff <= 90
              ? cursor.add(const Duration(days: 7))
              : DateTime(cursor.year, cursor.month + 1, 1);
    }

    for (var sale in _allSales) {
      final key = keyFn(sale.purchaseDate);
      if (map.containsKey(key)) {
        map[key]!['sales'] = (map[key]!['sales'] ?? 0.0) + sale.grandTotal;
        double cost = _saleCosts[sale.id] ?? sale.grandTotal * 0.7; // Fallback for legacy
        map[key]!['profit'] = (map[key]!['profit'] ?? 0.0) + (sale.grandTotal - cost);
      }
    }

    return map.entries
        .map((e) => {'period': e.key, 'sales': e.value['sales'], 'profit': e.value['profit']})
        .toList();
  }

  Future<void> _exportReport(String type) async {
    setState(() => _isLoading = true);
    try {
      final label = _rangeLabel();
      if (type == 'excel') {
        await ExcelExportHelper.exportPurchaseList('Sales Report ($label)', _allSales);
      } else {
        await PdfExportHelper.exportPurchaseList('Sales Report ($label)', _allSales);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _rangeLabel() {
    final fmt = DateFormat('dd MMM yyyy');
    if (_fromDate == null || _toDate == null) return 'All Time';
    switch (_preset) {
      case _DatePreset.today: return 'Today';
      case _DatePreset.thisWeek: return 'This Week';
      case _DatePreset.thisMonth: return 'This Month';
      case _DatePreset.lastMonth: return 'Last Month';
      case _DatePreset.thisYear: return 'This Year';
      case _DatePreset.custom:
        return '${fmt.format(_fromDate!)} – ${fmt.format(_toDate!)}';
    }
  }

  String _formatCompactNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;

    double totalSales = 0.0;
    double totalCost = 0.0;
    for (var sale in _allSales) {
      totalSales += sale.grandTotal;
      totalCost += _saleCosts[sale.id] ?? sale.grandTotal * 0.7; // Fallback for legacy
    }
    double totalProfit = totalSales - totalCost;
    double totalReturns = _allReturns.fold<double>(0.0, (s, p) => s + p.grandTotal);

    final chartData = _buildChartData();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sales Reports',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Overview of sales, profit, and returns',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _exportReport('excel'),
                    icon: const Icon(Icons.grid_on, size: 18),
                    label: const Text('Export Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _exportReport('pdf'),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Export PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _isLoading ? null : _loadReports,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Date Range Filter ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    const Text(
                      'DATE RANGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    if (_fromDate != null && _toDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _rangeLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip('Today', _DatePreset.today),
                    _presetChip('This Week', _DatePreset.thisWeek),
                    _presetChip('This Month', _DatePreset.thisMonth),
                    _presetChip('Last Month', _DatePreset.lastMonth),
                    _presetChip('This Year', _DatePreset.thisYear),
                    _customRangeChip(),
                  ],
                ),
                if (_preset == _DatePreset.custom && _fromDate != null && _toDate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('dd MMM yyyy').format(_fromDate!)}  →  ${DateFormat('dd MMM yyyy').format(_toDate!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _pickCustomRange,
                          child: const Icon(Icons.edit_calendar, size: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Summary Cards ────────────────────────────────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Total Sales', '$currency${totalSales.toStringAsFixed(2)}', Colors.blue, _allSales.length)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Total Profit', '$currency${totalProfit.toStringAsFixed(2)}', Colors.green, _allSales.length)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Total Cost', '$currency${totalCost.toStringAsFixed(2)}', Colors.orange, _allSales.length)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryCard('Returns', '$currency${totalReturns.toStringAsFixed(2)}', Colors.red, _allReturns.length)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Chart ──────────────────────────────────────────────────────────
            _buildChart(chartData),
            const SizedBox(height: 24),

            // ── Transactions List ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sales Transactions',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_allSales.length} records',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _allSales.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary.withAlpha(80)),
                                const SizedBox(height: 12),
                                Text(
                                  'No sales in this date range',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _allSales.length,
                          separatorBuilder: (_, __) => Divider(color: AppColors.border),
                          itemBuilder: (ctx, i) {
                            final sale = _allSales[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(sale.referenceNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${sale.items.length} items • ${DateFormat('dd MMM yyyy, HH:mm').format(sale.purchaseDate)}',
                              ),
                              trailing: Text(
                                '$currency${sale.grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              onTap: () => _showSaleItems(sale, currency),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _presetChip(String label, _DatePreset preset) {
    final isActive = _preset == preset;
    return GestureDetector(
      onTap: () {
        _applyPreset(preset);
        _loadReports();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textMain,
          ),
        ),
      ),
    );
  }

  Widget _customRangeChip() {
    final isActive = _preset == _DatePreset.custom;
    return GestureDetector(
      onTap: _pickCustomRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 14, color: isActive ? Colors.white : AppColors.textMain),
            const SizedBox(width: 6),
            Text(
              'Custom Range',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textMain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty || chartData.every((m) => (m['sales'] as double) == 0.0)) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('No data for chart', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    double maxY = 0;
    for (var m in chartData) {
      if ((m['sales'] as double) > maxY) maxY = m['sales'];
      if ((m['profit'] as double) > maxY) maxY = m['profit'];
    }
    if (maxY == 0) maxY = 100;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales & Profit — ${_rangeLabel()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
              ),
              Row(
                children: [
                  _legendItem('Sales', AppColors.primary),
                  const SizedBox(width: 16),
                  _legendItem('Profit', AppColors.success),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final period = chartData[group.x.toInt()]['period'];
                      final label = rodIndex == 0 ? 'Sales' : 'Profit';
                      return BarTooltipItem(
                        '$period\n$label: ${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              chartData[idx]['period'],
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          _formatCompactNumber(value),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chartData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: chartData[i]['sales'], color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: chartData[i]['profit'], color: AppColors.success, width: 14, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.trending_up, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text('$count transactions', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showSaleItems(Purchase sale, String currency) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Items — ${sale.referenceNo}'),
        content: SizedBox(
          width: 500,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: sale.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (c, i) {
              final it = sale.items[i];
              final itemProfit = it.subtotal - (it.costPrice * it.quantity);
              return ListTile(
                title: Text(it.product?.name ?? 'Unknown'),
                subtitle: Text(
                  'Qty: ${it.quantity} • Price: $currency${it.unitCost.toStringAsFixed(2)} • Cost: $currency${it.costPrice.toStringAsFixed(2)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$currency${it.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Profit: $currency${itemProfit.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
