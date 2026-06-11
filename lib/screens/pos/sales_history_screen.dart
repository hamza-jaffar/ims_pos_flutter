import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';

class SalesHistoryScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const SalesHistoryScreen({super.key, required this.onRouteSelected});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  bool _isLoading = true;
  List<Purchase> _allSales = [];
  List<Purchase> _filtered = [];
  String _filterType = 'All'; // All | Sale | SaleReturn
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _searchCtrl = TextEditingController();
  int _displayLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadSales();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales =
          await SaleService.instance.getAllSalesHistory(filterType: 'All');
      sales.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
      _allSales = sales;
      if (mounted) {
        setState(() => _isLoading = false);
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<Purchase> list = _allSales.where((p) {
      // Type filter
      bool typeMatch = true;
      if (_filterType == 'Sale') {
        typeMatch = p.type == 'Sale';
      } else if (_filterType == 'SaleReturn') {
        typeMatch = p.type == 'SaleReturn';
      }

      // Date range filter
      bool dateMatch = true;
      if (_fromDate != null) {
        dateMatch = dateMatch &&
            !p.purchaseDate.isBefore(
                DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day));
      }
      if (_toDate != null) {
        dateMatch = dateMatch &&
            !p.purchaseDate.isAfter(DateTime(
                _toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59));
      }

      // Search filter
      bool searchMatch = q.isEmpty ||
          p.referenceNo.toLowerCase().contains(q) ||
          (p.supplier?.name.toLowerCase().contains(q) ?? false);

      return typeMatch && dateMatch && searchMatch;
    }).toList();

    setState(() {
      _filtered = list;
      _displayLimit = 20; // reset on filter
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_fromDate ?? now) : (_toDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _applyFilter();
    }
  }

  void _clearDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _applyFilter();
  }

  Future<void> _viewSale(Purchase sale) async {
    try {
      final full = await SaleService.instance.getById(sale.id!);
      if (full != null && mounted) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SaleDetailSheet(sale: full),
        );
      }
    } catch (e) {
      _showSnack('Failed to load sale details: $e', isError: true);
    }
  }

  Future<void> _downloadPdf(Purchase sale) async {
    try {
      final full = await SaleService.instance.getById(sale.id!);
      if (full != null) await PdfExportHelper.exportPurchaseDetail(full);
    } catch (e) {
      _showSnack('PDF export failed: $e', isError: true);
    }
  }

  Future<void> _downloadExcel(Purchase sale) async {
    try {
      final full = await SaleService.instance.getById(sale.id!);
      if (full != null) await ExcelExportHelper.exportPurchaseDetail(full);
    } catch (e) {
      _showSnack('Excel export failed: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
    ));
  }

  // Compute summary stats from filtered list
  Map<String, double> get _stats {
    double totalRevenue = 0;
    double totalReturns = 0;
    int salesCount = 0;
    int returnsCount = 0;
    for (final s in _filtered) {
      if (s.type == 'Sale') {
        totalRevenue += s.grandTotal;
        salesCount++;
      } else if (s.type == 'SaleReturn') {
        totalReturns += s.grandTotal;
        returnsCount++;
      }
    }
    return {
      'revenue': totalRevenue,
      'returns': totalReturns,
      'salesCount': salesCount.toDouble(),
      'returnsCount': returnsCount.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        PlatformSettingsService.instance.settings.currencySymbol;
    final stats = _stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sales History',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View all POS sales and sale returns',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadSales,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary Cards ────────────────────────────────────
                Row(
                  children: [
                    _SummaryCard(
                      label: 'Total Revenue',
                      value:
                          '$currency${stats['revenue']!.toStringAsFixed(2)}',
                      count: stats['salesCount']!.toInt(),
                      color: AppColors.success,
                      icon: Icons.attach_money_rounded,
                    ),
                    const SizedBox(width: 16),
                    _SummaryCard(
                      label: 'Sales Transactions',
                      value: stats['salesCount']!.toInt().toString(),
                      count: stats['salesCount']!.toInt(),
                      color: AppColors.primary,
                      icon: Icons.shopping_bag_rounded,
                    ),
                    const SizedBox(width: 16),
                    _SummaryCard(
                      label: 'Total Returns',
                      value:
                          '$currency${stats['returns']!.toStringAsFixed(2)}',
                      count: stats['returnsCount']!.toInt(),
                      color: AppColors.danger,
                      icon: Icons.replay_rounded,
                    ),
                    const SizedBox(width: 16),
                    _SummaryCard(
                      label: 'Net Sales',
                      value:
                          '$currency${(stats['revenue']! - stats['returns']!).toStringAsFixed(2)}',
                      count: _filtered.length,
                      color: AppColors.purple,
                      icon: Icons.trending_up_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Filters ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      // Search
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search by reference or customer…',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Type dropdown
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filterType,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'All', child: Text('All Types')),
                                DropdownMenuItem(
                                    value: 'Sale', child: Text('Sales')),
                                DropdownMenuItem(
                                    value: 'SaleReturn',
                                    child: Text('Returns')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _filterType = val);
                                  _applyFilter();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // From date
                      _DateButton(
                        label: _fromDate == null
                            ? 'From Date'
                            : DateFormat('dd MMM yy').format(_fromDate!),
                        onTap: () => _pickDate(isFrom: true),
                      ),
                      const SizedBox(width: 8),

                      // To date
                      _DateButton(
                        label: _toDate == null
                            ? 'To Date'
                            : DateFormat('dd MMM yy').format(_toDate!),
                        onTap: () => _pickDate(isFrom: false),
                      ),

                      // Clear dates
                      if (_fromDate != null || _toDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _clearDates,
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Clear date filter',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.dangerLight,
                            foregroundColor: AppColors.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Table ────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 60),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long_outlined,
                                        size: 48,
                                        color: AppColors.border),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No sales found',
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                // Table header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: const BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                          flex: 2,
                                          child: Text('Reference',
                                              style: _headerStyle)),
                                      Expanded(
                                          flex: 2,
                                          child: Text('Customer',
                                              style: _headerStyle)),
                                      Expanded(
                                          flex: 2,
                                          child: Text('Date',
                                              style: _headerStyle)),
                                      Expanded(
                                          flex: 1,
                                          child: Text('Type',
                                              style: _headerStyle)),
                                      Expanded(
                                          flex: 1,
                                          child: Text('Status',
                                              style: _headerStyle)),
                                      Expanded(
                                          flex: 2,
                                          child: Text('Amount',
                                              style: _headerStyle,
                                              textAlign: TextAlign.right)),
                                      SizedBox(width: 48),
                                    ],
                                  ),
                                ),
                                const Divider(
                                    height: 1, color: AppColors.border),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _filtered.length > _displayLimit ? _displayLimit : _filtered.length,
                                  separatorBuilder: (_, _) => const Divider(
                                      height: 1, color: AppColors.border),
                                  itemBuilder: (ctx, i) {
                                    final sale = _filtered[i];
                                    final isReturn =
                                        sale.type == 'SaleReturn';
                                    final typeColor = isReturn
                                        ? AppColors.danger
                                        : AppColors.success;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 14),
                                      child: Row(
                                        children: [
                                          // Reference
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: typeColor
                                                        .withAlpha(30),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    isReturn
                                                        ? Icons
                                                            .replay_rounded
                                                        : Icons
                                                            .shopping_bag_rounded,
                                                    color: typeColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  sale.referenceNo,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 13,
                                                    color: AppColors.textMain,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Customer
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              sale.supplier?.name ??
                                                  'Walk-in Customer',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.textSecondary),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),

                                          // Date
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              DateFormat('dd MMM yyyy, hh:mm a')
                                                  .format(sale.purchaseDate),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary),
                                            ),
                                          ),

                                          // Type badge
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color:
                                                    typeColor.withAlpha(30),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isReturn ? 'Return' : 'Sale',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: typeColor,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),

                                          // Payment status
                                          Expanded(
                                            flex: 1,
                                            child: _StatusBadge(
                                                status:
                                                    sale.paymentStatus),
                                          ),

                                          // Amount
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '$currency${sale.grandTotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isReturn
                                                    ? AppColors.danger
                                                    : AppColors.textMain,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),

                                          // Actions
                                          PopupMenuButton<String>(
                                            onSelected: (val) {
                                              if (val == 'view') {
                                                _viewSale(sale);
                                              } else if (val == 'pdf') {
                                                _downloadPdf(sale);
                                              } else if (val == 'excel') {
                                                _downloadExcel(sale);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'view',
                                                child: Row(children: [
                                                  Icon(Icons.visibility,
                                                      color: Colors.blue,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('View Details'),
                                                ]),
                                              ),
                                              const PopupMenuItem(
                                                value: 'pdf',
                                                child: Row(children: [
                                                  Icon(
                                                      Icons.picture_as_pdf,
                                                      color: Colors.red,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Download PDF'),
                                                ]),
                                              ),
                                              const PopupMenuItem(
                                                value: 'excel',
                                                child: Row(children: [
                                                  Icon(Icons.grid_on,
                                                      color: Colors.green,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('Download Excel'),
                                                ]),
                                              ),
                                            ],
                                            icon: const Icon(
                                                Icons.more_vert,
                                                size: 20),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              if (_filtered.length > _displayLimit)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _displayLimit += 20;
                                        });
                                      },
                                      child: const Text('Load More'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ],
              ),
          ),
        ),
      ],
    );
  }
}

// ── Constants ──────────────────────────────────────────────────────────────────

const _headerStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
                  label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            Text(
              '$count transactions',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_rounded, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Paid':
        color = AppColors.success;
        break;
      case 'Partial':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.danger;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Sale Detail Bottom Sheet ───────────────────────────────────────────────────

class _SaleDetailSheet extends StatelessWidget {
  final Purchase sale;
  const _SaleDetailSheet({required this.sale});

  @override
  Widget build(BuildContext context) {
    final currency =
        PlatformSettingsService.instance.settings.currencySymbol;
    final isReturn = sale.type == 'SaleReturn';
    final typeColor = isReturn ? AppColors.danger : AppColors.success;
    final typeLabel = isReturn ? 'Sale Return' : 'Sale';

    Color payColor;
    switch (sale.paymentStatus) {
      case 'Paid':
        payColor = AppColors.success;
        break;
      case 'Partial':
        payColor = AppColors.warning;
        break;
      default:
        payColor = AppColors.danger;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isReturn
                          ? Icons.replay_rounded
                          : Icons.shopping_bag_rounded,
                      color: typeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              sale.referenceNo,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textMain),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: typeColor),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(sale.purchaseDate),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Info tiles
                  Row(
                    children: [
                      _infoTile('Payment',
                          sale.paymentMethod ?? 'N/A',
                          Icons.credit_card_rounded),
                      const SizedBox(width: 12),
                      _infoTile(
                          'Status',
                          sale.paymentStatus,
                          Icons.check_circle_outline_rounded,
                          payColor),
                      const SizedBox(width: 12),
                      _infoTile(
                          'Customer',
                          sale.supplier?.name ?? 'Walk-in',
                          Icons.person_outline_rounded),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Items header
                  const Text('Items',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textMain)),
                  const SizedBox(height: 10),

                  if (sale.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'No item details available.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    ...sale.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.product?.name ??
                                    'Product #${item.productId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textMain),
                              ),
                            ),
                            Text(
                              '${item.quantity} × $currency${item.unitCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$currency${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textMain),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _totalRow('Subtotal',
                            '$currency${sale.grandTotal.toStringAsFixed(2)}'),
                        if (sale.dueAmount > 0) ...[
                          const Divider(color: AppColors.border, height: 20),
                          _totalRow('Paid',
                              '$currency${sale.paidAmount.toStringAsFixed(2)}'),
                          _totalRow(
                              'Due',
                              '$currency${sale.dueAmount.toStringAsFixed(2)}',
                              color: AppColors.danger),
                        ],
                        const Divider(color: AppColors.border, height: 20),
                        _totalRow(
                            'Grand Total',
                            '$currency${sale.grandTotal.toStringAsFixed(2)}',
                            isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon,
      [Color? valueColor]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textMain),
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: isBold ? 16 : 13,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? AppColors.textMain)),
        ],
      ),
    );
  }
}
