import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PurchaseReportScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;

  const PurchaseReportScreen({super.key, required this.onRouteSelected});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  List<Purchase> _purchases = [];
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
      final purchases = await PurchaseService.instance.getAllByType('Purchase');
      final returns = await PurchaseService.instance.getAllByType('Return');

      final now = DateTime.now();
      final Map<String, Map<String, double>> monthlyMap = {};
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM yy').format(d);
        monthlyMap[key] = {'purchases': 0.0, 'returns': 0.0};
      }

      for (var p in purchases) {
        final key = DateFormat('MMM yy').format(p.purchaseDate);
        if (monthlyMap.containsKey(key)) {
          monthlyMap[key]!['purchases'] = (monthlyMap[key]!['purchases'] ?? 0.0) + p.grandTotal;
        }
      }
      for (var r in returns) {
        final key = DateFormat('MMM yy').format(r.purchaseDate);
        if (monthlyMap.containsKey(key)) {
          monthlyMap[key]!['returns'] = (monthlyMap[key]!['returns'] ?? 0.0) + r.grandTotal;
        }
      }

      List<Map<String, dynamic>> processedMonthly = [];
      monthlyMap.forEach((k, v) {
        processedMonthly.add({'period': k, 'purchases': v['purchases'], 'returns': v['returns']});
      });

      if (mounted) {
        setState(() {
          _purchases = purchases;
          _returns = returns;
          _monthlyData = processedMonthly;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  double _calculateTotalAmount(List<Purchase> purchases) {
    return purchases.fold(0.0, (sum, p) => sum + p.grandTotal);
  }

  double _calculateTotalPaid(List<Purchase> purchases) {
    return purchases.fold(0.0, (sum, p) => sum + p.paidAmount);
  }

  double _calculateTotalDue(List<Purchase> purchases) {
    return purchases.fold(0.0, (sum, p) => sum + p.dueAmount);
  }

  int _countByStatus(List<Purchase> purchases, String status) {
    return purchases.where((p) => p.paymentStatus == status).length;
  }

  Future<void> _exportReport(String type) async {
    setState(() => _isLoading = true);
    try {
      if (type == 'excel') {
        await ExcelExportHelper.exportPurchaseList('Purchase Report', _purchases);
      } else if (type == 'pdf') {
        await PdfExportHelper.exportPurchaseList('Purchase Report', _purchases);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report exported successfully!'),
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final purchaseTotal = _calculateTotalAmount(_purchases);
    final purchasePaid = _calculateTotalPaid(_purchases);
    final purchaseDue = _calculateTotalDue(_purchases);
    final returnTotal = _calculateTotalAmount(_returns);

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
                    'Purchase Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Overview of all purchases and related transactions',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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
                  'Total Purchases',
                  '$currency${purchaseTotal.toStringAsFixed(2)}',
                  Colors.blue,
                  _purchases.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Paid',
                  '$currency${purchasePaid.toStringAsFixed(2)}',
                  Colors.green,
                  _countByStatus(_purchases, 'Paid'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Due',
                  '$currency${purchaseDue.toStringAsFixed(2)}',
                  Colors.orange,
                  _countByStatus(_purchases, 'Unpaid') + _countByStatus(_purchases, 'Partial'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Returns',
                  '$currency${returnTotal.toStringAsFixed(2)}',
                  Colors.red,
                  _returns.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildPurchaseReturnsChart(),

          const SizedBox(height: 24),

          // Top Suppliers and Purchases List side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Container(
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
                        'Top Suppliers',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      const SizedBox(height: 20),
                      _buildTopSuppliersTable(currency),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildPurchasesList(currency),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseReturnsChart() {
    if (_monthlyData.isEmpty) return const SizedBox();

    double maxY = 0;
    for (var m in _monthlyData) {
      if (m['purchases'] > maxY) maxY = m['purchases'];
      if (m['returns'] > maxY) maxY = m['returns'];
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
                'Purchases & Returns (Last 6 Months)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain),
              ),
              Row(
                children: [
                  _legendItem('Purchases', Colors.blue),
                  const SizedBox(width: 16),
                  _legendItem('Returns', Colors.red),
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
                        toY: _monthlyData[i]['purchases'],
                        color: Colors.blue,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: _monthlyData[i]['returns'],
                        color: Colors.red,
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

  Widget _buildPurchasesList(String currency) {
    return Container(
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
            'Recent Purchases',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
          ),
          const SizedBox(height: 12),
          _purchases.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No purchases to display', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchases.length.clamp(0, 50),
                  separatorBuilder: (_, __) => Divider(color: AppColors.border),
                  itemBuilder: (ctx, i) {
                    final p = _purchases[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.referenceNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.items.length} items • ${DateFormat('yyyy-MM-dd').format(p.purchaseDate)}'),
                      trailing: Text(
                        '$currency${p.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onTap: () => _showPurchaseItems(p, currency),
                    );
                  },
                ),
        ],
      ),
    );
  }

  void _showPurchaseItems(Purchase purchase, String currency) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Items - ${purchase.referenceNo}'),
          content: SizedBox(
            width: 400,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: purchase.items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (c, i) {
                final it = purchase.items[i];
                return ListTile(
                  title: Text(it.product?.name ?? 'Unknown'),
                  subtitle: Text(
                    'Qty: ${it.quantity} • Unit: $currency${it.unitCost.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '$currency${it.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.trending_up, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textMain)),
          const SizedBox(height: 8),
          Text('$count transactions', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildTopSuppliersTable(String currency) {
    final supplierMap = <int?, (String, double, int)>{};

    for (var purchase in _purchases) {
      final supplierId = purchase.supplierId;
      final supplierName = purchase.supplier?.name ?? 'Walk-in';
      if (supplierMap.containsKey(supplierId)) {
        final current = supplierMap[supplierId]!;
        supplierMap[supplierId] = (
          supplierName,
          current.$2 + purchase.grandTotal,
          current.$3 + 1,
        );
      } else {
        supplierMap[supplierId] = (supplierName, purchase.grandTotal, 1);
      }
    }

    final sortedSuppliers = supplierMap.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));

    if (sortedSuppliers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No data available', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Supplier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.right)),
              Expanded(flex: 1, child: Text('Count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center)),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedSuppliers.length.clamp(0, 10),
          separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, index) {
            final supplier = sortedSuppliers[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(supplier.$1, style: const TextStyle(fontSize: 14, color: AppColors.textMain))),
                  Expanded(flex: 2, child: Text('$currency${supplier.$2.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain), textAlign: TextAlign.right)),
                  Expanded(flex: 1, child: Text('${supplier.$3}', style: TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
