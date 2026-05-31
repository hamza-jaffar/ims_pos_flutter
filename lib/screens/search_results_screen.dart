import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
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
    setState(() => _isLoading = true);
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
      _products = allProducts.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q)).toList();

      // 2. Search Invoices
      final sales = await SaleService.instance.getAllSalesHistory(filterType: 'All');
      final purchases = await PurchaseService.instance.getAllByType('Purchase');
      final returns = await PurchaseService.instance.getAllByType('Return');
      
      final allInv = [...sales, ...purchases, ...returns];
      _invoices = allInv.where((i) =>
          i.referenceNo.toLowerCase().contains(q) ||
          (i.supplier?.name.toLowerCase().contains(q) ?? false) ||
          (i.note?.toLowerCase().contains(q) ?? false)).toList();
          
      _invoices.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    } catch (e) {
      // Handle error gracefully
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;
    
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search Results for "${widget.query}"', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                    const SizedBox(height: 4),
                    Text('Found ${_products.length} products and ${_invoices.length} invoices', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (_products.isNotEmpty) ...[
                        const Text('Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        const SizedBox(height: 12),
                        ..._products.map((p) => _buildProductCard(p, currency)),
                        const SizedBox(height: 24),
                      ],
                      if (_invoices.isNotEmpty) ...[
                        const Text('Invoices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                        const SizedBox(height: 12),
                        ..._invoices.map((i) => _buildInvoiceCard(i, currency)),
                      ],
                      if (_products.isEmpty && _invoices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('No results found. Try a different search term.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product p, String currency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.inventory_2, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain)),
                Text('Code: ${p.code} • Stock: ${p.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('$currency${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Purchase i, String currency) {
    Color typeColor = Colors.blue;
    if (i.type == 'Sale') typeColor = Colors.green;
    if (i.type.contains('Return')) typeColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: typeColor.withAlpha(20), shape: BoxShape.circle),
            child: Icon(Icons.receipt_long, color: typeColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.referenceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain)),
                Text('${i.type} • ${DateFormat('yyyy-MM-dd').format(i.purchaseDate)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text('$currency${i.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textMain)),
        ],
      ),
    );
  }
}
