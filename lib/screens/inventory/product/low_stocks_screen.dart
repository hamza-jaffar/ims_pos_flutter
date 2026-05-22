import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/services/product_service.dart';

class LowStocksScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;

  const LowStocksScreen({super.key, required this.onRouteSelected});

  @override
  State<LowStocksScreen> createState() => _LowStocksScreenState();
}

class _LowStocksScreenState extends State<LowStocksScreen> {
  List<Product> _lowStockProducts = [];
  List<Product> _filtered = [];
  bool _isLoading = true;
  final Set<int> _hoveredRows = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLowStockProducts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLowStockProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await ProductService.instance.getLowStockProducts();
      if (mounted) {
        setState(() {
          _lowStockProducts = data;
          _filtered = data;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load low stock products: $error'),
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
          ? _lowStockProducts
          : _lowStockProducts.where((p) {
              return p.name.toLowerCase().contains(q) ||
                  (p.supplierName?.toLowerCase().contains(q) ?? false) ||
                  (p.categoryName?.toLowerCase().contains(q) ?? false);
            }).toList();
    });
  }

  Future<void> _quickReplenish(Product product) async {
    final controller = TextEditingController(text: '10');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Replenish Stock',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add quantity to the current stock of "${product.name}".',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                'Current Stock: ${product.quantity} pcs',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: product.quantity <= 0 ? AppColors.danger : AppColors.warning,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity to Add',
                  hintText: 'e.g. 10',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter quantity.';
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Must be a valid positive whole number greater than 0.';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final qtyToAdd = int.parse(controller.text.trim());
              final newQty = product.quantity + qtyToAdd;
              await ProductService.instance.updateStock(product.id!, newQty);
              if (ctx.mounted) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );

    if (updated == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock replenished successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadLowStockProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alerts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_lowStockProducts.length} items are below their minimum threshold',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Search Bar
        SizedBox(
          height: 42,
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 14, color: AppColors.textMain),
            decoration: InputDecoration(
              hintText: 'Search low-stock products by name or code...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // List
        Container(
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
                  ? _buildEmpty()
                  : (isMobile ? _buildCardList() : _buildTable()),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.check_circle_outline,
              size: 52,
              color: isSearching 
                  ? AppColors.textSecondary.withAlpha(100)
                  : AppColors.success.withAlpha(150),
            ),
            const SizedBox(height: 12),
            Text(
              isSearching ? 'No matching products' : 'All Stock Levels Normal!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try a different keyword search.'
                  : 'Great! All products in your inventory have sufficient stock levels.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.warningLight.withAlpha(80),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: _headerCell('Product')),
              Expanded(flex: 2, child: _headerCell('Current Stock')),
              Expanded(flex: 2, child: _headerCell('Min Threshold')),
              Expanded(flex: 3, child: _headerCell('Supplier')),
              SizedBox(width: 140, child: _headerCell('Actions')),
            ],
          ),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _filtered.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, index) => _buildRow(_filtered[index], index),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildRow(Product product, int index) {
    final isHovered = _hoveredRows.contains(index);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRows.add(index)),
      onExit: (_) => setState(() => _hoveredRows.remove(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isHovered ? AppColors.warningLight.withAlpha(20) : Colors.white,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                product.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: product.quantity <= 0 ? AppColors.danger : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product.quantity} items',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: product.quantity <= 0 ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${product.minStockQuantity} items',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                product.supplierName ?? 'No supplier linked',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _quickReplenish(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningLight,
                      foregroundColor: AppColors.warning,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Replenish', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.info),
                    onPressed: () => widget.onRouteSelected('${AppRoutes.editProduct}/${product.id}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (_, index) => _buildCardItem(_filtered[index]),
    );
  }

  Widget _buildCardItem(Product product) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.quantity <= 0 ? AppColors.dangerLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.quantity <= 0 ? 'Out of Stock' : 'Low Stock',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: product.quantity <= 0 ? AppColors.danger : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CURRENT STOCK', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '${product.quantity} pcs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: product.quantity <= 0 ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MIN THRESHOLD', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('${product.minStockQuantity} pcs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SUPPLIER', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(product.supplierName ?? '—', style: const TextStyle(fontSize: 13, color: AppColors.textMain)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _quickReplenish(product),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.warning),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Replenish', style: TextStyle(color: AppColors.warning, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => widget.onRouteSelected('${AppRoutes.editProduct}/${product.id}'),
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
