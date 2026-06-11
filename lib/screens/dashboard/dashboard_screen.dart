import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const DashboardScreen({super.key, required this.onRouteSelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _showNumbers = false;



  double _totalRevenue = 0;
  double _totalSpend = 0;
  double _totalProfit = 0;
  double _totalReturns = 0;
  int _totalSalesCount = 0;
  int _totalPurchasesCount = 0;

  List<Map<String, dynamic>> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;

      _totalRevenue = 0;
      _totalSpend = 0;
      _totalProfit = 0;
      _totalReturns = 0;
      _totalSalesCount = 0;
      _totalPurchasesCount = 0;

      final legacySales = await db.rawQuery("SELECT SUM(grand_total) as total, COUNT(*) as cnt FROM purchases WHERE type = 'Sale'");
      final newSales = await db.rawQuery("SELECT SUM(grand_total) as total, COUNT(*) as cnt FROM sales WHERE type = 'Sale'");
      _totalRevenue = ((legacySales.first['total'] as num?)?.toDouble() ?? 0) + ((newSales.first['total'] as num?)?.toDouble() ?? 0);
      _totalSalesCount = ((legacySales.first['cnt'] as num?)?.toInt() ?? 0) + ((newSales.first['cnt'] as num?)?.toInt() ?? 0);

      final spendData = await db.rawQuery("SELECT SUM(grand_total) as total, COUNT(*) as cnt FROM purchases WHERE type = 'Purchase'");
      _totalSpend = (spendData.first['total'] as num?)?.toDouble() ?? 0;
      _totalPurchasesCount = (spendData.first['cnt'] as num?)?.toInt() ?? 0;

      final ret1 = await db.rawQuery("SELECT SUM(grand_total) as total FROM purchases WHERE type IN ('Return', 'SaleReturn')");
      final ret2 = await db.rawQuery("SELECT SUM(grand_total) as total FROM sales WHERE type = 'SaleReturn'");
      _totalReturns = ((ret1.first['total'] as num?)?.toDouble() ?? 0) + ((ret2.first['total'] as num?)?.toDouble() ?? 0);

      final exactCost = await db.rawQuery("SELECT SUM(cost_price * quantity) as total FROM sale_items");
      double totalCost = (exactCost.first['total'] as num?)?.toDouble() ?? 0;
      double legacyCost = ((legacySales.first['total'] as num?)?.toDouble() ?? 0) * 0.7;
      _totalProfit = _totalRevenue - (totalCost + legacyCost);

      final now = DateTime.now();
      final Map<String, Map<String, double>> monthlyMap = {};
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM yy').format(d);
        monthlyMap[key] = {'sales': 0.0, 'spend': 0.0, 'profit': 0.0};
      }

      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1).toIso8601String();
      
      final recentSales = await db.rawQuery("SELECT id, purchase_date, grand_total FROM sales WHERE type = 'Sale' AND purchase_date >= ?", [sixMonthsAgo]);
      final recentLegacySales = await db.rawQuery("SELECT id, purchase_date, grand_total FROM purchases WHERE type = 'Sale' AND purchase_date >= ?", [sixMonthsAgo]);
      
      final recentCosts = await db.rawQuery("SELECT sale_id, SUM(cost_price * quantity) as total_cost FROM sale_items GROUP BY sale_id");
      final Map<int, double> saleCosts = { for (var row in recentCosts) row['sale_id'] as int: (row['total_cost'] as num).toDouble() };

      for (var row in recentSales) {
        final date = DateTime.parse(row['purchase_date'] as String);
        final key = DateFormat('MMM yy').format(date);
        if (monthlyMap.containsKey(key)) {
          final revenue = (row['grand_total'] as num).toDouble();
          monthlyMap[key]!['sales'] = (monthlyMap[key]!['sales'] ?? 0) + revenue;
          final cost = saleCosts[row['id'] as int] ?? (revenue * 0.7);
          monthlyMap[key]!['profit'] = (monthlyMap[key]!['profit'] ?? 0) + (revenue - cost);
        }
      }

      for (var row in recentLegacySales) {
        final date = DateTime.parse(row['purchase_date'] as String);
        final key = DateFormat('MMM yy').format(date);
        if (monthlyMap.containsKey(key)) {
          final revenue = (row['grand_total'] as num).toDouble();
          monthlyMap[key]!['sales'] = (monthlyMap[key]!['sales'] ?? 0) + revenue;
          monthlyMap[key]!['profit'] = (monthlyMap[key]!['profit'] ?? 0) + (revenue * 0.3);
        }
      }

      final recentSpend = await db.rawQuery("SELECT purchase_date, grand_total FROM purchases WHERE type = 'Purchase' AND purchase_date >= ?", [sixMonthsAgo]);
      for (var row in recentSpend) {
        final date = DateTime.parse(row['purchase_date'] as String);
        final key = DateFormat('MMM yy').format(date);
        if (monthlyMap.containsKey(key)) {
          monthlyMap[key]!['spend'] = (monthlyMap[key]!['spend'] ?? 0) + (row['grand_total'] as num).toDouble();
        }
      }

      List<Map<String, dynamic>> processedMonthly = [];
      monthlyMap.forEach((k, v) {
        processedMonthly.add({'period': k, 'sales': v['sales'], 'spend': v['spend'], 'profit': v['profit']});
      });
      _monthlyData = processedMonthly;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport(String type) async {
    try {
      final summaryData = {
        'totalRevenue': _totalRevenue,
        'totalSpend': _totalSpend,
        'totalProfit': _totalProfit,
        'totalReturns': _totalReturns,
        'monthlyData': _monthlyData,
      };

      if (type == 'excel') {
        await ExcelExportHelper.exportSystemReport(
          'System Dashboard Report',
          summaryData,
        );
      } else {
        await PdfExportHelper.exportSystemReport(
          'System Dashboard Report',
          summaryData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report exported!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _fmt(double n) {
    if (!_showNumbers) return '***';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 24),
          _buildKpiRow(currency),
          const SizedBox(height: 20),
          _buildSecondRow(currency),
          const SizedBox(height: 20),
          _buildMainChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final now = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Dashboard',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              now,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _actionBtn(
              label: 'Excel',
              icon: Icons.grid_on_rounded,
              color: const Color(0xFF217346),
              onTap: () => _exportReport('excel'),
            ),
            const SizedBox(width: 10),
            _actionBtn(
              label: 'PDF',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFD32F2F),
              onTap: () => _exportReport('pdf'),
            ),
            const SizedBox(width: 10),
            _actionBtn(
              label: 'Invoices',
              icon: Icons.receipt_long_rounded,
              color: AppColors.purple,
              onTap: () => widget.onRouteSelected(AppRoutes.invoices),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _showNumbers = !_showNumbers),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(
                  _showNumbers ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _loadDashboardData,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KPI Cards ──────────────────────────────────────────────────────────────
  Widget _buildKpiRow(String currency) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            title: 'Total Revenue',
            value: _showNumbers ? '$currency${_fmt(_totalRevenue)}' : '***',
            subtitle: _showNumbers ? '$_totalSalesCount sales' : '*** sales',
            icon: Icons.trending_up_rounded,
            gradientColors: const [Color(0xFF4776E6), Color(0xFF8E54E9)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            title: 'Gross Profit',
            value: _showNumbers ? '$currency${_fmt(_totalProfit)}' : '***',
            subtitle: _showNumbers
                ? '${_totalRevenue > 0 ? (_totalProfit / _totalRevenue * 100).toStringAsFixed(1) : 0}% margin'
                : '***% margin',
            icon: Icons.account_balance_wallet_rounded,
            gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            title: 'Total Spend',
            value: _showNumbers ? '$currency${_fmt(_totalSpend)}' : '***',
            subtitle: _showNumbers ? '$_totalPurchasesCount purchases' : '*** purchases',
            icon: Icons.shopping_bag_rounded,
            gradientColors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            title: 'Total Returns',
            value: _showNumbers ? '$currency${_fmt(_totalReturns)}' : '***',
            subtitle: 'Net impact',
            icon: Icons.replay_rounded,
            gradientColors: const [Color(0xFFEB3349), Color(0xFFF45C43)],
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(200),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _isLoading ? '...' : value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.circle, color: Colors.white.withAlpha(120), size: 7),
              const SizedBox(width: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Second Row ─────────────────────────────────────────────────────────────
  Widget _buildSecondRow(String currency) {
    final profitRate = _totalRevenue > 0
        ? (_totalProfit / _totalRevenue * 100)
        : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini stat cards
        Expanded(
          child: Column(
            children: [
              _miniStatCard(
                title: 'Net Balance',
                value: _showNumbers
                    ? '$currency${(_totalRevenue - _totalSpend).toStringAsFixed(0)}'
                    : '***',
                icon: Icons.account_balance_rounded,
                color: AppColors.purple,
              ),
              const SizedBox(height: 14),
              _miniStatCard(
                title: 'Profit Margin',
                value: _showNumbers ? '${profitRate.toStringAsFixed(1)}%' : '***%',
                icon: Icons.pie_chart_rounded,
                color: AppColors.success,
              ),
              const SizedBox(height: 14),
              _miniStatCard(
                title: 'Avg. Sale Value',
                value: _showNumbers
                    ? (_totalSalesCount > 0
                        ? '$currency${(_totalRevenue / _totalSalesCount).toStringAsFixed(0)}'
                        : '${currency}0')
                    : '***',
                icon: Icons.bar_chart_rounded,
                color: AppColors.info,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Quick actions
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Navigate to key system areas',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _quickActionTile(
                      'Sales Report',
                      Icons.show_chart_rounded,
                      const Color(0xFF4776E6),
                      AppRoutes.salesReport,
                    ),
                    _quickActionTile(
                      'Purchase Report',
                      Icons.bar_chart_rounded,
                      const Color(0xFF11998E),
                      AppRoutes.purchaseReport,
                    ),
                    _quickActionTile(
                      'Invoices',
                      Icons.receipt_long_rounded,
                      AppColors.purple,
                      AppRoutes.invoices,
                    ),
                    _quickActionTile(
                      'Products',
                      Icons.inventory_2_rounded,
                      AppColors.warning,
                      AppRoutes.products,
                    ),
                    _quickActionTile(
                      'Purchases',
                      Icons.shopping_bag_rounded,
                      const Color(0xFFEB3349),
                      AppRoutes.purchases,
                    ),
                    _quickActionTile(
                      'Settings',
                      Icons.settings_rounded,
                      AppColors.textSecondary,
                      AppRoutes.platformSettings,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading ? '...' : value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile(
    String label,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => widget.onRouteSelected(route),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Chart ─────────────────────────────────────────────────────────────
  Widget _buildMainChart() {
    if (_isLoading) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_monthlyData.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var m in _monthlyData) {
      if ((m['sales'] as double) > maxY) maxY = m['sales'] as double;
      if ((m['spend'] as double) > maxY) maxY = m['spend'] as double;
    }
    if (maxY == 0) maxY = 100;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Revenue vs Spend',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '6-month trend comparison',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _legendDot('Revenue', const Color(0xFF4776E6)),
                  const SizedBox(width: 20),
                  _legendDot('Spend', const Color(0xFFF7971E)),
                  const SizedBox(width: 20),
                  _legendDot('Profit', const Color(0xFF11998E)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                maxY: maxY * 1.25,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1B2559),
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            _showNumbers ? _fmt(s.y) : '***',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1.5),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _monthlyData[idx]['period'],
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      getTitlesWidget: (value, _) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          _fmt(value),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _lineBar(
                    spots: List.generate(
                      _monthlyData.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        _monthlyData[i]['sales'] as double,
                      ),
                    ),
                    color: const Color(0xFF4776E6),
                  ),
                  _lineBar(
                    spots: List.generate(
                      _monthlyData.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        _monthlyData[i]['spend'] as double,
                      ),
                    ),
                    color: const Color(0xFFF7971E),
                  ),
                  _lineBar(
                    spots: List.generate(
                      _monthlyData.length,
                      (i) => FlSpot(
                        i.toDouble(),
                        _monthlyData[i]['profit'] as double,
                      ),
                    ),
                    color: const Color(0xFF11998E),
                    dashed: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineBar({
    required List<FlSpot> spots,
    required Color color,
    bool dashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: dashed ? 2.5 : 3.5,
      isStrokeCapRound: true,
      dashArray: dashed ? [6, 4] : null,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 4,
          color: Colors.white,
          strokeWidth: 2.5,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: !dashed,
        gradient: LinearGradient(
          colors: [color.withAlpha(50), color.withAlpha(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
