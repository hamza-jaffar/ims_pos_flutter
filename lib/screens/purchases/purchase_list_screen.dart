import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:intl/intl.dart';

class PurchaseListScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  final String purchaseType; // Purchase, Order, Return

  const PurchaseListScreen({
    super.key,
    required this.onRouteSelected,
    this.purchaseType = 'Purchase',
  });

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  List<Purchase> _purchases = [];
  List<Purchase> _filtered = [];
  bool _isLoading = true;
  final Set<int> _hoveredRows = {};
  final TextEditingController _searchController = TextEditingController();
  int _displayLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
    _searchController.addListener(_onSearch);
  }

  @override
  void didUpdateWidget(covariant PurchaseListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.purchaseType != oldWidget.purchaseType) {
      _searchController.clear();
      _loadPurchases();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    try {
      final data = await PurchaseService.instance.getAllByType(
        widget.purchaseType,
      );
      if (mounted) {
        setState(() {
          _purchases = data;
          _filtered = data;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load records: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _purchases
          : _purchases.where((p) {
              return p.referenceNo.toLowerCase().contains(q) ||
                  (p.supplier?.name.toLowerCase().contains(q) ?? false);
            }).toList();
      _displayLimit = 20; // reset on filter
    });
  }

  Future<void> _deletePurchase(Purchase purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Record',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${purchase.referenceNo}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PurchaseService.instance.delete(purchase.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${purchase.referenceNo} deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadPurchases();
      }
    }
  }

  Future<void> _showUpdateStatusDialog(Purchase purchase) async {
    String selectedStatus = purchase.status;
    String selectedPaymentStatus = purchase.paymentStatus;
    final currentPaidAmount = purchase.paidAmount;
    final currentDueAmount = purchase.grandTotal - purchase.paidAmount;
    double selectedPaidAmount = 0.0;
    final paidAmountController = TextEditingController();
    String? paidAmountError;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Update Status - ${purchase.referenceNo}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Fulfillment Status',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedStatus,
                items: ['Received', 'Pending', 'Ordered', 'Returned']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedStatus = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedPaymentStatus,
                items: ['Paid', 'Unpaid', 'Partial']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() {
                      selectedPaymentStatus = v;
                      if (selectedPaymentStatus != 'Partial') {
                        paidAmountController.text = '';
                        paidAmountError = null;
                        selectedPaidAmount = 0.0;
                      }
                    });
                  }
                },
              ),
              if (selectedPaymentStatus == 'Partial') ...[
                const SizedBox(height: 16),
                Text(
                  'Already received: ${PlatformSettingsService.instance.settings.currencySymbol}${currentPaidAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining due: ${PlatformSettingsService.instance.settings.currencySymbol}${currentDueAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: paidAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount received now',
                    border: const OutlineInputBorder(),
                    errorText: paidAmountError,
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPaidAmount = double.tryParse(value) ?? 0.0;
                      paidAmountError = null;
                    });
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedPaymentStatus == 'Partial') {
                  final amount =
                      double.tryParse(paidAmountController.text) ?? 0.0;
                  if (amount <= 0 || amount > currentDueAmount) {
                    setDialogState(
                      () => paidAmountError =
                          'Enter an amount up to the remaining due',
                    );
                    return;
                  }
                  selectedPaidAmount = amount;
                  if (amount == currentDueAmount) {
                    selectedPaymentStatus = 'Paid';
                  }
                }
                Navigator.of(ctx).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        await PurchaseService.instance.updateStatuses(
          purchase.id!,
          status: selectedStatus,
          paymentStatus: selectedPaymentStatus,
          paidAmount: selectedPaymentStatus == 'Partial'
              ? selectedPaidAmount
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Statuses updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          _loadPurchases();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating status: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadPdfInvoice(Purchase purchase) async {
    setState(() => _isLoading = true);
    try {
      final fullPurchase = await PurchaseService.instance.getById(purchase.id!);
      if (fullPurchase != null) {
        await PdfExportHelper.exportPurchaseDetail(fullPurchase);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadExcelInvoice(Purchase purchase) async {
    setState(() => _isLoading = true);
    try {
      final fullPurchase = await PurchaseService.instance.getById(purchase.id!);
      if (fullPurchase != null) {
        await ExcelExportHelper.exportPurchaseDetail(fullPurchase);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate Excel: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCreateRoute() {
    switch (widget.purchaseType) {
      case 'Order':
        return AppRoutes.createPurchaseOrder;
      case 'Return':
        return AppRoutes.createPurchaseReturn;
      default:
        return AppRoutes.createPurchase;
    }
  }

  String _getScreenTitle() {
    switch (widget.purchaseType) {
      case 'Order':
        return 'Purchase Orders';
      case 'Return':
        return 'Purchase Returns';
      default:
        return 'Purchases';
    }
  }

  Widget _buildExportButtons(String title) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await ExcelExportHelper.exportPurchaseList(
                      title,
                      _filtered,
                    );
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
                },
          icon: const Icon(Icons.grid_on, size: 18),
          label: const Text('Export Excel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await PdfExportHelper.exportPurchaseList(title, _filtered);
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
                },
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('Export PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _loadPurchases,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMain,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final title = _getScreenTitle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage $title',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_purchases.length} total records',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildExportButtons(title),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => widget.onRouteSelected(_getCreateRoute()),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    isMobile ? 'Create' : 'Create ${widget.purchaseType}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 42,
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'Search by reference no or supplier...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No records found.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : _buildTable(),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: _headerCell('Date')),
              Expanded(flex: 2, child: _headerCell('Reference')),
              Expanded(flex: 3, child: _headerCell('Supplier')),
              Expanded(flex: 2, child: _headerCell('Status')),
              Expanded(flex: 2, child: _headerCell('Payment Status')),
              Expanded(flex: 2, child: _headerCell('Received')),
              Expanded(flex: 2, child: _headerCell('Grand Total')),
              SizedBox(width: 60, child: _headerCell('')),
            ],
          ),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _filtered.length > _displayLimit ? _displayLimit : _filtered.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, index) => _buildRow(_filtered[index], index),
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
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildRow(Purchase purchase, int index) {
    final isHovered = _hoveredRows.contains(index);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRows.add(index)),
      onExit: (_) => setState(() => _hoveredRows.remove(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isHovered ? AppColors.background.withAlpha(40) : Colors.white,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                dateFormat.format(purchase.purchaseDate),
                style: TextStyle(fontSize: 14, color: AppColors.textMain),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                purchase.referenceNo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMain,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                purchase.supplier?.name ?? 'Walk-in',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => _showUpdateStatusDialog(purchase),
                  borderRadius: BorderRadius.circular(20),
                  child: _buildStatusBadge(purchase.status),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => _showUpdateStatusDialog(purchase),
                  borderRadius: BorderRadius.circular(20),
                  child: _buildPaymentStatusBadge(purchase.paymentStatus),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${PlatformSettingsService.instance.settings.currencySymbol}${purchase.paidAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${PlatformSettingsService.instance.settings.currencySymbol}${purchase.grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'update') {
                        _showUpdateStatusDialog(purchase);
                      } else if (value == 'pdf') {
                        _downloadPdfInvoice(purchase);
                      } else if (value == 'excel') {
                        _downloadExcelInvoice(purchase);
                      } else if (value == 'delete') {
                        _deletePurchase(purchase);
                      }
                    },
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'update',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text('Update Status'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Download PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'excel',
                        child: Row(
                          children: [
                            Icon(Icons.grid_on, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Download Excel'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Record',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ],
                        ),
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

  Widget _buildStatusBadge(String status) {
    Color bgColor = AppColors.border;
    Color textColor = AppColors.textSecondary;

    if (status == 'Received' || status == 'Returned') {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
    } else if (status == 'Pending') {
      bgColor = AppColors.warning.withAlpha(30);
      textColor = AppColors.warning;
    } else if (status == 'Ordered') {
      bgColor = AppColors.info.withAlpha(30);
      textColor = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bgColor = AppColors.border;
    Color textColor = AppColors.textSecondary;

    if (status == 'Paid') {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
    } else if (status == 'Unpaid') {
      bgColor = AppColors.danger.withAlpha(20);
      textColor = AppColors.danger;
    } else if (status == 'Partial') {
      bgColor = AppColors.warning.withAlpha(20);
      textColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
