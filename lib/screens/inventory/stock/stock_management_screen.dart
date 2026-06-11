import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/services/product_service.dart';

class StockManagementScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;

  const StockManagementScreen({super.key, required this.onRouteSelected});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  String _filterStockStatus = 'All';
  int _displayLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductService.instance.getAll();
      if (mounted) {
        setState(() {
          _products = products;
          _filtered = products;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stock data: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final matchesQuery =
            query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query) ||
            (p.categoryName?.toLowerCase().contains(query) ?? false) ||
            (p.brandName?.toLowerCase().contains(query) ?? false) ||
            (p.roomName?.toLowerCase().contains(query) ?? false);

        var matchesStock = true;
        if (_filterStockStatus == 'In Stock') {
          matchesStock = p.quantity > p.minStockQuantity;
        } else if (_filterStockStatus == 'Low Stock') {
          matchesStock = p.quantity <= p.minStockQuantity && p.quantity > 0;
        } else if (_filterStockStatus == 'Out of Stock') {
          matchesStock = p.quantity == 0;
        }

        return matchesQuery && matchesStock;
      }).toList();
      _displayLimit = 20;
    });
  }

  Widget _buildStatus(Product product) {
    if (product.quantity == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(color: AppColors.danger, fontSize: 12),
        ),
      );
    }
    if (product.quantity <= product.minStockQuantity) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Low Stock',
          style: TextStyle(color: AppColors.warning, fontSize: 12),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Healthy',
        style: TextStyle(color: AppColors.success, fontSize: 12),
      ),
    );
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: const WidgetStatePropertyAll(AppColors.background),
            columns: const [
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Code')),
              DataColumn(label: Text('Room')),
              DataColumn(label: Text('Quantity')),
              DataColumn(label: Text('Min Stock')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: _filtered.take(_displayLimit).map((product) {
              return DataRow(
                cells: [
                  DataCell(Text(product.name)),
                  DataCell(Text(product.code)),
                  DataCell(Text(product.roomName ?? '-')),
                  DataCell(Text(product.quantity.toString())),
                  DataCell(Text(product.minStockQuantity.toString())),
                  DataCell(_buildStatus(product)),
                  DataCell(
                    ElevatedButton(
                      onPressed: () {
                        widget.onRouteSelected(
                          '${AppRoutes.stockAdjustment}/${product.id}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Adjust'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
          ],
        );
      },
    );
  }

  Widget _buildCardList() {
    return Column(
      children: [
        ..._filtered.take(_displayLimit).map((product) {
          return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    product.code,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Room: ${product.roomName ?? 'N/A'}'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Qty: ${product.quantity}  •  Min: ${product.minStockQuantity}',
                  ),
                  const SizedBox(width: 8),
                  _buildStatus(product),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onRouteSelected(
                      '${AppRoutes.stockAdjustment}/${product.id}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Adjust Stock'),
                ),
              ),
            ],
          ),
        );
      }),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.textSecondary.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final totalProducts = _products.length;
    final lowStockCount = _products
        .where((p) => p.quantity <= p.minStockQuantity && p.quantity > 0)
        .length;
    final outOfStockCount = _products.where((p) => p.quantity == 0).length;
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
                  'Stock Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track inventory levels, adjust stock, and review history.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => widget.onRouteSelected(AppRoutes.lowStocks),
                  icon: const Icon(Icons.trending_down, size: 18),
                  label: const Text('Low Stocks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      widget.onRouteSelected(AppRoutes.stockHistory),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
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
        Row(
          children: [
            _buildSummaryCard(
              'Total Products',
              totalProducts.toString(),
              AppColors.primary,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Low Stock',
              lowStockCount.toString(),
              AppColors.warning,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Out of Stock',
              outOfStockCount.toString(),
              AppColors.danger,
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
              hintText: 'Search products, code, category, or room...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
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
              fillColor: AppColors.background.withAlpha(120),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by stock status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: ['All', 'In Stock', 'Low Stock', 'Out of Stock'].map((
                  status,
                ) {
                  final active = _filterStockStatus == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: active,
                    onSelected: (_) {
                      setState(() {
                        _filterStockStatus = status;
                      });
                      _applyFilters();
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.textMain,
                    ),
                    backgroundColor: AppColors.background,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : _filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 52,
                          color: AppColors.textSecondary.withAlpha(100),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No stock items found',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Update products or adjust your search filters.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    isMobile ? _buildCardList() : _buildTable(),
                    if (_filtered.length > _displayLimit)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _displayLimit += 20;
                            });
                          },
                          child: const Text('Load More'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
