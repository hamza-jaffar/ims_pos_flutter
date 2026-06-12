import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/models/purchase_item.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/services/excel_export_helper.dart';
import 'package:intl/intl.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final ValueChanged<String> onRouteSelected;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.onRouteSelected,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<Purchase> _invoices = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void didUpdateWidget(covariant SearchResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final q = widget.query.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() {
        _products = [];
        _invoices = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // 1. Search Products
      final allProducts = await ProductService.instance.getAll();
      _products = allProducts
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.code.toLowerCase().contains(q),
          )
          .toList();

      // 2. Search Invoices / Sales
      final sales = await SaleService.instance.getAllSalesHistory(
        filterType: 'All',
      );
      final purchases = await PurchaseService.instance.getAllByType('Purchase');
      final returns = await PurchaseService.instance.getAllByType('Return');

      final allInv = [...sales, ...purchases, ...returns];
      _invoices = allInv
          .where(
            (i) =>
                i.referenceNo.toLowerCase().contains(q) ||
                (i.supplier?.name.toLowerCase().contains(q) ?? false) ||
                (i.note?.toLowerCase().contains(q) ?? false),
          )
          .toList();

      _invoices.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Product actions ────────────────────────────────────────────────────────

  void _openProduct(Product p) {
    if (p.id == null) return;
    widget.onRouteSelected('${AppRoutes.editProduct}/${p.id}');
  }

  // ── Invoice actions ────────────────────────────────────────────────────────

  Future<void> _viewInvoice(Purchase invoice) async {
    try {
      Purchase? full;
      if (invoice.type == 'Sale' || invoice.type == 'SaleReturn') {
        full = await SaleService.instance.getById(invoice.id!);
      } else {
        full = await PurchaseService.instance.getById(invoice.id!);
      }
      if (full != null && mounted) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _InvoiceDetailSheet(
            invoice: full!,
            onReturnSuccess: _performSearch,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load invoice: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _downloadPdf(Purchase invoice) async {
    try {
      Purchase? full;
      if (invoice.type == 'Sale' || invoice.type == 'SaleReturn') {
        full = await SaleService.instance.getById(invoice.id!);
      } else {
        full = await PurchaseService.instance.getById(invoice.id!);
      }
      if (full != null) await PdfExportHelper.exportPurchaseDetail(full);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _downloadExcel(Purchase invoice) async {
    try {
      Purchase? full;
      if (invoice.type == 'Sale' || invoice.type == 'SaleReturn') {
        full = await SaleService.instance.getById(invoice.id!);
      } else {
        full = await PurchaseService.instance.getById(invoice.id!);
      }
      if (full != null) await ExcelExportHelper.exportPurchaseDetail(full);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;

    return Container(
      color: AppColors.background,
      width: double.infinity,
      // Main container with a fixed minimum height so it doesn't collapse
      constraints: const BoxConstraints(minHeight: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 28, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Results for "${widget.query}"',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Found ${_products.length} products and ${_invoices.length} invoices',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(60.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'An error occurred: $_error',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            )
          else
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                if (_products.isNotEmpty) ...[
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._products.map((p) => _buildProductCard(p, currency)),
                  const SizedBox(height: 24),
                ],
                if (_invoices.isNotEmpty) ...[
                  const Text(
                    'Invoices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._invoices.map((i) => _buildInvoiceCard(i, currency)),
                ],
                if (_products.isEmpty && _invoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No results found. Try a different search term.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Product card ───────────────────────────────────────────────────────────

  Widget _buildProductCard(Product p, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProduct(p),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        'Code: ${p.code} • Stock: ${p.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currency${p.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Invoice card ───────────────────────────────────────────────────────────

  Widget _buildInvoiceCard(Purchase i, String currency) {
    Color typeColor = Colors.blue;
    if (i.type == 'Sale') typeColor = Colors.green;
    if (i.type.contains('Return')) typeColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewInvoice(i),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long, color: typeColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.referenceNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        '${i.type} • ${DateFormat('yyyy-MM-dd').format(i.purchaseDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currency${i.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Invoice Detail Bottom Sheet ────────────────────────────────────────────────

class _InvoiceDetailSheet extends StatefulWidget {
  final Purchase invoice;
  final VoidCallback? onReturnSuccess;

  const _InvoiceDetailSheet({required this.invoice, this.onReturnSuccess});

  @override
  State<_InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<_InvoiceDetailSheet> {
  Purchase get invoice => widget.invoice;

  Future<void> _promptReturnFromSearch(Purchase sale, PurchaseItem item) async {
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Return Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Product: ${item.product?.name ?? "Product"}'),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity to Return',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final returnQty = int.tryParse(quantityController.text) ?? 0;
                  if (returnQty <= 0 || returnQty > item.quantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid return quantity'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  print(
                    '🔵 Creating return for item: ${item.product?.name}, qty: $returnQty',
                  );

                  // Calculate subtotal for return
                  final returnSubtotal = item.unitCost * returnQty;

                  // Create return purchase
                  final returnPurchase = Purchase(
                    referenceNo:
                        'RET-${sale.referenceNo}-${DateTime.now().millisecondsSinceEpoch}',
                    type: 'SaleReturn',
                    status: 'Completed',
                    customerId: sale.customerId,
                    purchaseDate: DateTime.now(),
                    grandTotal: returnSubtotal,
                    note: 'Return from invoice ${sale.referenceNo}',
                    items: [
                      PurchaseItem(
                        productId: item.productId,
                        quantity: returnQty,
                        unitCost: item.unitCost,
                        subtotal: returnSubtotal,
                        product: item.product,
                      ),
                    ],
                  );

                  await SaleService.instance.create(returnPurchase);
                  print('✅ Return created successfully');

                  Navigator.pop(context); // Close quantity dialog
                  Navigator.pop(context); // Close invoice detail dialog

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Returned $returnQty x ${item.product?.name}',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  widget.onReturnSuccess?.call();
                } catch (e, st) {
                  print('🔴 Return error: $e');
                  print('Stack: $st');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Return failed: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: const Text('Confirm Return'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          children: [
            Text(
              'Invoice ${invoice.referenceNo}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(invoice.purchaseDate)}',
            ),
            Text('Status: ${invoice.paymentStatus}'),
            const Divider(height: 32),
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...invoice.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product?.name ?? "Product"} (x${item.quantity})',
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$currency${item.subtotal.toStringAsFixed(2)}'),
                        if (invoice.type == 'Sale')
                          TextButton(
                            onPressed: () =>
                                _promptReturnFromSearch(invoice, item),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 20),
                            ),
                            child: const Text(
                              'Return',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$currency${invoice.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
