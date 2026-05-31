import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SalesReportScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const SalesReportScreen({super.key, required this.onRouteSelected});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  List<Purchase> _sales = [];
  List<Purchase> _returns = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final allData = await SaleService.instance.getAllSalesHistory(filterType: 'All');
      final sales = allData.where((s) => s.type == 'Sale').toList();
      final returns = allData.where((s) => s.type == 'SaleReturn').toList();

      final now = DateTime.now();
      final Map<String, Map<String, double>> monthlyMap = {};
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM yy').format(d);
        monthlyMap[key] = {'sales': 0.0, 'profit': 0.0};
      }

      for (var sale in sales) {
        final key = DateFormat('MMM yy').format(sale.purchaseDate);
        if (monthlyMap.containsKey(key)) {
          monthlyMap[key]!['sales'] = (monthlyMap[key]!['sales'] ?? 0.0) + sale.grandTotal;
          double cost = 0;
          for (var item in sale.items) {
            cost += item.costPrice * item.quantity;
          }
          monthlyMap[key]!['profit'] = (monthlyMap[key]!['profit'] ?? 0.0) + (sale.grandTotal - cost);
        }
      }

      List<Map<String, dynamic>> processedMonthly = [];
      monthlyMap.forEach((k, v) {
        processedMonthly.add({'period': k, 'sales': v['sales'], 'profit': v['profit']});
      });

      if (mounted) {
        setState(() {
          _sales = sales;
          _returns = returns;
          _monthlyData = processedMonthly;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport(String type) async {
    setState(() => _isLoading = true);
    try {
      if (type == 'excel') {
        await ExcelExportHelper.exportPurchaseList('Sales Report', _sales);
      } else {
        await PdfExportHelper.exportPurchaseList('Sales Report', _sales);
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

  String _formatCompactNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    double totalSales = 0.0;
    double totalCost = 0.0;
    for (var sale in _sales) {
      totalSales += sale.grandTotal;
      for (var item in sale.items) {
        totalCost += (item.costPrice * item.quantity);
      }
    }
    double totalProfit = totalSales - totalCost;
    double totalReturns = _returns.fold<double>(0.0, (s, p) => s + p.grandTotal);

    return SingleChildScrollView(
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
                    'Sales Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Overview of all sales, profit, and related transactions',
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
          const SizedBox(height: 24),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Sales',
                  '$currency${totalSales.toStringAsFixed(2)}',
                  Colors.blue,
                  _sales.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Profit',
                  '$currency${totalProfit.toStringAsFixed(2)}',
                  Colors.green,
                  _sales.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Cost',
                  '$currency${totalCost.toStringAsFixed(2)}',
                  Colors.orange,
                  _sales.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Returns',
                  '$currency${totalReturns.toStringAsFixed(2)}',
                  Colors.red,
                  _returns.length,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSalesProfitChart(),

          const SizedBox(height: 24),

          // Sales List
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
                const Text(
                  'Recent Sales Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                _sales.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No sales to display',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sales.length.clamp(0, 50),
                        separatorBuilder: (_, __) => Divider(color: AppColors.border),
                        itemBuilder: (ctx, i) {
                          final sale = _sales[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(sale.referenceNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${sale.items.length} items • ${DateFormat('yyyy-MM-dd').format(sale.purchaseDate)}',
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
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 8),
          Text(
            '$count transactions',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesProfitChart() {
    if (_monthlyData.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var m in _monthlyData) {
      if (m['sales'] > maxY) maxY = m['sales'];
      if (m['profit'] > maxY) maxY = m['profit'];
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
              const Text(
                'Sales & Profit (Last 6 Months)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
              ),
              Row(
                children: [
                  _legendItem('Sales', AppColors.primary),
                  const SizedBox(width: 16),
                  _legendItem('Profit', AppColors.success),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_monthlyData[group.x.toInt()]['period']}\n${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        if (value >= 0 && value < _monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
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
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          _formatCompactNumber(value),
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_monthlyData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _monthlyData[i]['sales'],
                        color: AppColors.primary,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: _monthlyData[i]['profit'],
                        color: AppColors.success,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  void _showSaleItems(Purchase sale, String currency) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Items - ${sale.referenceNo}'),
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
                    'Qty: ${it.quantity} • Sell Price: $currency${it.unitCost.toStringAsFixed(2)} • Cost: $currency${it.costPrice.toStringAsFixed(2)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency${it.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Profit: $currency${itemProfit.toStringAsFixed(2)}',
                        style: const TextStyle(color: AppColors.success, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
