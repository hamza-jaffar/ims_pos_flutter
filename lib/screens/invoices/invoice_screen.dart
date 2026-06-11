import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';

class InvoiceScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  const InvoiceScreen({super.key, required this.onRouteSelected});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool _isLoading = true;
  List<Purchase> _allInvoices = [];
  List<Purchase> _filtered = [];
  String _filterType = 'All'; // All | Sale | Purchase | Return
  final TextEditingController _searchCtrl = TextEditingController();
  int _displayLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final sales = await SaleService.instance.getAllSalesHistory(filterType: 'All');
      final purchases = await PurchaseService.instance.getAllByType('Purchase');
      final returns = await PurchaseService.instance.getAllByType('Return');

      List<Purchase> combined = [...sales, ...purchases, ...returns];
      // Sort newest first
      combined.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      _allInvoices = combined;
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
    
    List<Purchase> list = _allInvoices.where((p) {
      bool typeMatch = true;
      if (_filterType == 'Sale') {
        typeMatch = p.type == 'Sale' || p.type == 'SaleReturn';
      } else if (_filterType == 'Purchase') {
        typeMatch = p.type == 'Purchase';
      } else if (_filterType == 'Return') {
        typeMatch = p.type == 'Return' || p.type == 'SaleReturn';
      }

      bool searchMatch = q.isEmpty || p.referenceNo.toLowerCase().contains(q) || (p.supplier?.name.toLowerCase().contains(q) ?? false);
      
      return typeMatch && searchMatch;
    }).toList();

    setState(() {
      _filtered = list;
      _displayLimit = 20;
    });
  }

  Future<void> _downloadPdf(Purchase purchase) async {
    try {
      // Need full items for invoice
      Purchase? fullPurchase;
      if (purchase.type == 'Sale' || purchase.type == 'SaleReturn') {
        fullPurchase = await SaleService.instance.getById(purchase.id!);
      } else {
        fullPurchase = await PurchaseService.instance.getById(purchase.id!);
      }
      
      if (fullPurchase != null) {
        await PdfExportHelper.exportPurchaseDetail(fullPurchase);
      }
    } catch (e) {
      _showError('PDF Download Failed: $e');
    }
  }

  Future<void> _downloadExcel(Purchase purchase) async {
    try {
      Purchase? fullPurchase;
      if (purchase.type == 'Sale' || purchase.type == 'SaleReturn') {
        fullPurchase = await SaleService.instance.getById(purchase.id!);
      } else {
        fullPurchase = await PurchaseService.instance.getById(purchase.id!);
      }
      
      if (fullPurchase != null) {
        await ExcelExportHelper.exportPurchaseDetail(fullPurchase);
      }
    } catch (e) {
      _showError('Excel Download Failed: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  void _viewInvoice(Purchase purchase) async {
    try {
      Purchase? fullPurchase;
      if (purchase.type == 'Sale' || purchase.type == 'SaleReturn') {
        fullPurchase = await SaleService.instance.getById(purchase.id!);
      } else {
        fullPurchase = await PurchaseService.instance.getById(purchase.id!);
      }
      
      if (fullPurchase != null && mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => InvoiceDetailSheet(sale: fullPurchase!),
        );
      }
    } catch (e) {
      _showError('Failed to load invoice details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Invoice Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                  SizedBox(height: 4),
                  Text('View and download all system invoices', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadInvoices,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              )
            ],
          ),
        ),

        // Toolbar
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by Invoice ID or Name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Invoices')),
                        DropdownMenuItem(value: 'Sale', child: Text('Sales')),
                        DropdownMenuItem(value: 'Purchase', child: Text('Purchases')),
                        DropdownMenuItem(value: 'Return', child: Text('Returns')),
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
            ],
          ),
        ),

        // List
        _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            : _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No invoices found.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _filtered.length > _displayLimit ? _displayLimit : _filtered.length,
                        itemBuilder: (ctx, i) {
                            final invoice = _filtered[i];
                            Color typeColor = Colors.blue;
                            if (invoice.type == 'Sale') typeColor = Colors.green;
                            if (invoice.type.contains('Return')) typeColor = Colors.red;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: typeColor.withAlpha(30), shape: BoxShape.circle),
                                  child: Icon(Icons.receipt_long, color: typeColor),
                                ),
                                title: Text(invoice.referenceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${invoice.type} • ${DateFormat('yyyy-MM-dd HH:mm').format(invoice.purchaseDate)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$currency${invoice.grandTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(width: 16),
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'view') _viewInvoice(invoice);
                                        if (val == 'pdf') _downloadPdf(invoice);
                                        if (val == 'print') _downloadPdf(invoice);
                                        if (val == 'excel') _downloadExcel(invoice);
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility, color: Colors.blue, size: 20), SizedBox(width: 8), Text('View Invoice')])),
                                        const PopupMenuItem(value: 'print', child: Row(children: [Icon(Icons.print_rounded, color: Colors.purple, size: 20), SizedBox(width: 8), Text('Print Invoice')])),
                                        const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red, size: 20), SizedBox(width: 8), Text('Download PDF')])),
                                        const PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.grid_on, color: Colors.green, size: 20), SizedBox(width: 8), Text('Download Excel')])),
                                      ],
                                      icon: const Icon(Icons.more_vert),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (_filtered.length > _displayLimit)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => setState(() => _displayLimit += 20),
                              icon: const Icon(Icons.expand_more),
                              label: Text('Load More (${_filtered.length - _displayLimit} remaining)'),
                            ),
                          ),
                        ),
                    ],
                  ),
      ],
    );
  }
}

class InvoiceDetailSheet extends StatelessWidget {
  final Purchase sale;
  const InvoiceDetailSheet({required this.sale});

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;
    final isSale = sale.type == 'Sale' || sale.type == 'SaleReturn';
    final typeColor = isSale ? AppColors.success : AppColors.purple;
    final typeLabel = sale.type;

    Color payColor;
    if (sale.paymentStatus == 'Paid') payColor = AppColors.success;
    else if (sale.paymentStatus == 'Partial') payColor = AppColors.warning;
    else payColor = AppColors.danger;

    return DraggableScrollableSheet(
      initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44, decoration: BoxDecoration(color: typeColor.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                    child: Icon(isSale ? Icons.shopping_bag_rounded : Icons.replay_rounded, color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(sale.referenceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain)),
                            const SizedBox(width: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: typeColor.withAlpha(30), borderRadius: BorderRadius.circular(20)), child: Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor))),
                          ],
                        ),
                        Text(DateFormat('dd MMM yyyy, hh:mm a').format(sale.purchaseDate), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle, border: Border.all(color: AppColors.border)), child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary)),
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
                  Row(
                    children: [
                      _infoTile('Payment', sale.paymentMethod ?? 'N/A', Icons.credit_card_rounded), const SizedBox(width: 12),
                      _infoTile('Status', sale.paymentStatus, Icons.check_circle_outline_rounded, payColor), const SizedBox(width: 12),
                      _infoTile(isSale ? 'Customer' : 'Supplier', sale.supplier?.name ?? 'Walk-in', Icons.person_outline_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain)),
                  const SizedBox(height: 10),
                  if (sale.items.isEmpty)
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)), child: const Text('No item details available.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)))
                  else
                    ...sale.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18), const SizedBox(width: 10),
                          Expanded(child: Text(item.product?.name ?? 'Product #${item.productId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMain))),
                          Text('${item.quantity} × $currency${item.unitCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), const SizedBox(width: 12),
                          Text('$currency${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMain)),
                        ],
                      ),
                    )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        _totalRow('Subtotal', '$currency${sale.grandTotal.toStringAsFixed(2)}'),
                        if (sale.dueAmount > 0) ...[
                          const Divider(color: AppColors.border, height: 20),
                          _totalRow('Paid', '$currency${sale.paidAmount.toStringAsFixed(2)}'),
                          _totalRow('Due', '$currency${sale.dueAmount.toStringAsFixed(2)}', color: AppColors.danger),
                        ],
                        const Divider(color: AppColors.border, height: 20),
                        _totalRow('Grand Total', '$currency${sale.grandTotal.toStringAsFixed(2)}', isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await PdfExportHelper.exportPurchaseDetail(sale);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Error: $e'), backgroundColor: AppColors.danger));
                          }
                        }
                      },
                      icon: const Icon(Icons.print_rounded, size: 20),
                      label: const Text('Print Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Built by Degvora',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, [Color? valueColor]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary), const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.textMain), overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: isBold ? 16 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? AppColors.textMain)),
        ],
      ),
    );
  }
}
