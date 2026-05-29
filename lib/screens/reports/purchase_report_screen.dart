import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
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
      if (mounted) {
        setState(() {
          _purchases = purchases;
          _returns = returns;
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
        await ExcelExportHelper.exportPurchaseList(
          'Purchase Report',
          _purchases,
        );
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
                children: [
                  const Text(
                    'Purchase Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _exportReport('pdf'),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Export PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                  '$currency$purchaseTotal',
                  Colors.blue,
                  _purchases.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Paid',
                  '$currency$purchasePaid',
                  Colors.green,
                  _countByStatus(_purchases, 'Paid'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Due',
                  '$currency$purchaseDue',
                  Colors.orange,
                  _countByStatus(_purchases, 'Unpaid') +
                      _countByStatus(_purchases, 'Partial'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Returns',
                  '$currency$returnTotal',
                  Colors.red,
                  _returns.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment Status Summary
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
                  'Payment Status Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusSummary(
                        'Paid',
                        _countByStatus(_purchases, 'Paid'),
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusSummary(
                        'Unpaid',
                        _countByStatus(_purchases, 'Unpaid'),
                        AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusSummary(
                        'Partial',
                        _countByStatus(_purchases, 'Partial'),
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fulfillment Status Summary
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
                  'Fulfillment Status Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusSummary(
                        'Received',
                        _purchases.where((p) => p.status == 'Received').length,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusSummary(
                        'Pending',
                        _purchases.where((p) => p.status == 'Pending').length,
                        AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusSummary(
                        'Ordered',
                        _purchases.where((p) => p.status == 'Ordered').length,
                        AppColors.info,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Top Suppliers
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
                  'Top Suppliers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTopSuppliersTable(currency),
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
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

  Widget _buildStatusSummary(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

    final sortedSuppliers = supplierMap.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    if (sortedSuppliers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No purchase data available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
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
              Expanded(
                flex: 3,
                child: Text(
                  'Supplier',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedSuppliers.length.clamp(0, 10),
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, index) {
            final supplier = sortedSuppliers[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      supplier.$1,
                      style: TextStyle(fontSize: 14, color: AppColors.textMain),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$currency${supplier.$2.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${supplier.$3}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
