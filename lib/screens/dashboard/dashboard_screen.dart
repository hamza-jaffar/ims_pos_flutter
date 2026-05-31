import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const DashboardScreen({super.key, required this.onRouteSelected});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  
  List<Purchase> _allSales = [];
  List<Purchase> _allPurchases = [];
  
  double _totalRevenue = 0;
  double _totalSpend = 0;
  double _totalProfit = 0;
  double _totalReturns = 0;

  List<Map<String, dynamic>> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final salesData = await SaleService.instance.getAllSalesHistory(filterType: 'All');
      final purchaseData = await PurchaseService.instance.getAllByType('Purchase');
      final returnData = await PurchaseService.instance.getAllByType('Return');

      _allSales = salesData;
      _allPurchases = [...purchaseData, ...returnData];

      // Reset metrics
      _totalRevenue = 0;
      _totalSpend = 0;
      _totalProfit = 0;
      _totalReturns = 0;

      final now = DateTime.now();
      final Map<String, Map<String, double>> monthlyMap = {};
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM yy').format(d);
        monthlyMap[key] = {'sales': 0.0, 'spend': 0.0};
      }

      // Process Sales
      for (var sale in _allSales) {
        if (sale.type == 'Sale') {
          _totalRevenue += sale.grandTotal;
          double cost = 0;
          for (var item in sale.items) cost += item.costPrice * item.quantity;
          _totalProfit += (sale.grandTotal - cost);

          final key = DateFormat('MMM yy').format(sale.purchaseDate);
          if (monthlyMap.containsKey(key)) {
            monthlyMap[key]!['sales'] = (monthlyMap[key]!['sales'] ?? 0.0) + sale.grandTotal;
          }
        } else if (sale.type == 'SaleReturn') {
          _totalReturns += sale.grandTotal;
        }
      }

      // Process Purchases
      for (var pur in _allPurchases) {
        if (pur.type == 'Purchase') {
          _totalSpend += pur.grandTotal;

          final key = DateFormat('MMM yy').format(pur.purchaseDate);
          if (monthlyMap.containsKey(key)) {
            monthlyMap[key]!['spend'] = (monthlyMap[key]!['spend'] ?? 0.0) + pur.grandTotal;
          }
        } else if (pur.type == 'Return') {
          _totalReturns += pur.grandTotal;
        }
      }

      List<Map<String, dynamic>> processedMonthly = [];
      monthlyMap.forEach((k, v) {
        processedMonthly.add({'period': k, 'sales': v['sales'], 'spend': v['spend']});
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
    setState(() => _isLoading = true);
    try {
      final summaryData = {
        'totalRevenue': _totalRevenue,
        'totalSpend': _totalSpend,
        'totalProfit': _totalProfit,
        'totalReturns': _totalReturns,
        'monthlyData': _monthlyData,
      };

      if (type == 'excel') {
        await ExcelExportHelper.exportSystemReport('System Dashboard Report', summaryData);
      } else {
        await PdfExportHelper.exportSystemReport('System Dashboard Report', summaryData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report exported successfully!'), backgroundColor: AppColors.success),
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

  String _formatCompact(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(currency),
          const SizedBox(height: 24),
          _buildMainChart(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'System Dashboard',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
            ),
            SizedBox(height: 4),
            Text(
              'Overall performance, sales, profit, and expenses',
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
              onPressed: _isLoading ? null : _loadDashboardData,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh Data',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards(String currency) {
    return Row(
      children: [
        Expanded(
          child: _buildCard('Total Revenue', '$currency${_totalRevenue.toStringAsFixed(2)}', Colors.blue, Icons.attach_money),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard('Total Spend', '$currency${_totalSpend.toStringAsFixed(2)}', Colors.orange, Icons.shopping_cart),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard('Gross Profit', '$currency${_totalProfit.toStringAsFixed(2)}', Colors.green, Icons.trending_up),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCard('Total Returns', '$currency${_totalReturns.toStringAsFixed(2)}', Colors.red, Icons.replay),
        ),
      ],
    );
  }

  Widget _buildCard(String title, String value, Color color, IconData icon) {
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
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain)),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    if (_monthlyData.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var m in _monthlyData) {
      if (m['sales'] > maxY) maxY = m['sales'];
      if (m['spend'] > maxY) maxY = m['spend'];
    }
    if (maxY == 0) maxY = 100;

    return Container(
      height: 400,
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
              const Text(
                'Revenue vs Spend (Last 6 Months)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
              ),
              Row(
                children: [
                  _legendItem('Revenue', Colors.blue),
                  const SizedBox(width: 16),
                  _legendItem('Spend', Colors.orange),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: maxY * 1.2,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < _monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              _monthlyData[value.toInt()]['period'],
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                          _formatCompact(value),
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(_monthlyData.length, (i) => FlSpot(i.toDouble(), _monthlyData[i]['sales'])),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withAlpha(30),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(_monthlyData.length, (i) => FlSpot(i.toDouble(), _monthlyData[i]['spend'])),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
