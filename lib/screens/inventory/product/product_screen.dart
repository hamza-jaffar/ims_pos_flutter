import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/category.dart';
import 'package:ims_pos_system/models/brand.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/category_service.dart';
import 'package:ims_pos_system/services/brand_service.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/widgets/searchable_dropdown.dart';

class ProductScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;

  const ProductScreen({super.key, required this.onRouteSelected});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  List<Category> _categories = [];
  List<Brand> _brands = [];

  bool _isLoading = true;
  final Set<int> _hoveredRows = {};

  final TextEditingController _searchController = TextEditingController();

  int? _filterCategoryId;
  int? _filterBrandId;
  String _filterStockStatus =
      'All'; // 'All', 'In Stock', 'Low Stock', 'Out of Stock'

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final products = await ProductService.instance.getAll();
      final categories = await CategoryService.instance.getAll();
      final brands = await BrandService.instance.getAll();

      if (mounted) {
        setState(() {
          _products = products;
          _filtered = products;
          _categories = categories;
          _brands = brands;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $error'),
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
        // 1. Search Query
        final matchesQuery =
            query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            p.code.toLowerCase().contains(query) ||
            (p.categoryName?.toLowerCase().contains(query) ?? false) ||
            (p.brandName?.toLowerCase().contains(query) ?? false) ||
            (p.supplierName?.toLowerCase().contains(query) ?? false);

        // 2. Category Filter
        final matchesCategory =
            _filterCategoryId == null || p.categoryId == _filterCategoryId;

        // 3. Brand Filter
        final matchesBrand =
            _filterBrandId == null || p.brandId == _filterBrandId;

        // 4. Stock Status Filter
        bool matchesStock = true;
        if (_filterStockStatus == 'In Stock') {
          matchesStock = p.quantity > p.minStockQuantity;
        } else if (_filterStockStatus == 'Low Stock') {
          matchesStock = p.quantity <= p.minStockQuantity && p.quantity > 0;
        } else if (_filterStockStatus == 'Out of Stock') {
          matchesStock = p.quantity == 0;
        }

        return matchesQuery && matchesCategory && matchesBrand && matchesStock;
      }).toList();
    });
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ProductService.instance.delete(product.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${product.name}" deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadAllData();
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
        isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
        const SizedBox(height: 20),

        // Filters Container
        _buildFilters(isMobile),
        const SizedBox(height: 16),

        // Table / Card List
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

  Widget _buildDesktopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_products.length} products total',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => widget.onRouteSelected(AppRoutes.createProduct),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Product'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_products.length} products total',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => widget.onRouteSelected(AppRoutes.createProduct),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Search Field
          SizedBox(
            height: 42,
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14, color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: 'Search products by name, code, category, brand...',
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
          const SizedBox(height: 12),
          // Filter dropdowns
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 650;
              final dropdowns = [
                // Category Filter
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: SearchableDropdown<int>(
                    label: 'Category',
                    hint: 'All Categories',
                    selectedValue: _filterCategoryId,
                    items: _categories
                        .map(
                          (c) => SearchableDropdownItem<int>(
                            value: c.id!,
                            label: c.name,
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _filterCategoryId = val);
                      _applyFilters();
                    },
                  ),
                ),
                if (!isWide) const SizedBox(height: 10),
                if (isWide) const SizedBox(width: 10),
                // Brand Filter
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: SearchableDropdown<int>(
                    label: 'Brand',
                    hint: 'All Brands',
                    selectedValue: _filterBrandId,
                    items: _brands
                        .map(
                          (b) => SearchableDropdownItem<int>(
                            value: b.id!,
                            label: b.name,
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _filterBrandId = val);
                      _applyFilters();
                    },
                  ),
                ),
                if (!isWide) const SizedBox(height: 10),
                if (isWide) const SizedBox(width: 10),
                // Stock Status Filter
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: SearchableDropdown<String>(
                    label: 'Stock Status',
                    hint: 'All Stocks',
                    selectedValue: _filterStockStatus == 'All'
                        ? null
                        : _filterStockStatus,
                    items: const [
                      SearchableDropdownItem<String>(
                        value: 'In Stock',
                        label: 'In Stock',
                      ),
                      SearchableDropdownItem<String>(
                        value: 'Low Stock',
                        label: 'Low Stock',
                      ),
                      SearchableDropdownItem<String>(
                        value: 'Out of Stock',
                        label: 'Out of Stock',
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _filterStockStatus = val ?? 'All');
                      _applyFilters();
                    },
                  ),
                ),
              ];

              return isWide
                  ? Row(children: dropdowns)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: dropdowns,
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final isSearching =
        _searchController.text.isNotEmpty ||
        _filterCategoryId != null ||
        _filterBrandId != null ||
        _filterStockStatus != 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.inventory_2_outlined,
              size: 52,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              isSearching ? 'No results found' : 'No products yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try clearing some filters or searching for something else.'
                  : 'Click "Create Product" to add your first item.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: _headerCell('Product')),
              Expanded(flex: 2, child: _headerCell('Category/Brand')),
              Expanded(flex: 2, child: _headerCell('Stock Qty')),
              Expanded(flex: 2, child: _headerCell('Pricing')),
              Expanded(flex: 1, child: _headerCell('Status')),
              SizedBox(width: 80, child: _headerCell('Actions')),
            ],
          ),
        ),
        // Rows
        RefreshIndicator(
          onRefresh: _loadAllData,
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _filtered.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, index) => _buildRow(_filtered[index], index),
          ),
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
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildRow(Product product, int index) {
    final isHovered = _hoveredRows.contains(index);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRows.add(index)),
      onExit: (_) => setState(() => _hoveredRows.remove(index)),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (product.id != null) {
            widget.onRouteSelected('${AppRoutes.editProduct}/${product.id}');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: isHovered ? AppColors.background.withAlpha(40) : Colors.white,
          child: Row(
            children: [
              // Product Name
              Expanded(
                flex: 3,
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Category/Brand
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.categoryName ?? '—',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMain.withAlpha(220),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brandName ?? '—',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Stock quantity (Highlight low stock in orange, out of stock in red)
              Expanded(flex: 2, child: _buildStockQuantityCell(product)),
              // Pricing
              Expanded(flex: 2, child: _buildPriceCell(product)),
              // Status
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? AppColors.successLight
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: product.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 92,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.info,
                      tooltip: 'Edit',
                      onTap: () => widget.onRouteSelected(
                        '${AppRoutes.editProduct}/${product.id}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Delete',
                      onTap: () => _deleteProduct(product),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockQuantityCell(Product product) {
    Color badgeColor = AppColors.success;
    Color textColor = AppColors.success;
    Color bgColor = AppColors.successLight;
    String label = '${product.quantity} in stock';

    if (product.quantity == 0) {
      badgeColor = AppColors.danger;
      textColor = AppColors.danger;
      bgColor = AppColors.dangerLight;
      label = 'Out of Stock';
    } else if (product.quantity <= product.minStockQuantity) {
      badgeColor = AppColors.warning;
      textColor = AppColors.warning;
      bgColor = AppColors.warningLight;
      label = '${product.quantity} (Low Stock)';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withAlpha(40)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // _buildExpiryDateCell removed — expiry dates are not used in this system.

  Widget _buildPriceCell(Product product) {
    if (product.hasDiscount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                '${PlatformSettingsService.instance.settings.currencySymbol}${product.discountPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Promo',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${PlatformSettingsService.instance.settings.currencySymbol}${product.sellingPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }

    return Text(
      '${PlatformSettingsService.instance.settings.currencySymbol}${product.sellingPrice.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildCardList() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _filtered.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, index) => _buildCardItem(_filtered[index]),
      ),
    );
  }

  Widget _buildCardItem(Product product) {
    return InkWell(
      onTap: () {
        if (product.id != null) {
          widget.onRouteSelected('${AppRoutes.editProduct}/${product.id}');
        }
      },
      child: Padding(
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? AppColors.successLight
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: product.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details grid on mobile card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STOCK',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildStockText(product),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRICE',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: ${product.categoryName ?? "—"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    _actionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.info,
                      tooltip: 'Edit',
                      onTap: () => widget.onRouteSelected(
                        '${AppRoutes.editProduct}/${product.id}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: Icons.delete_outline,
                      color: AppColors.danger,
                      tooltip: 'Delete',
                      onTap: () => _deleteProduct(product),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockText(Product product) {
    if (product.quantity == 0) {
      return const Text(
        'Out of stock',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.danger,
        ),
      );
    } else if (product.quantity <= product.minStockQuantity) {
      return Text(
        '${product.quantity} (Low)',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.warning,
        ),
      );
    }
    return Text(
      '${product.quantity}',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.success,
      ),
    );
  }
}
