import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/customer.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/models/purchase_item.dart';
import 'package:ims_pos_system/services/customer_service.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/sale_service.dart';
import 'package:ims_pos_system/services/pdf_export_helper.dart';
import 'package:ims_pos_system/screens/invoices/invoice_screen.dart';

class CartItem {
  final Product product;
  int quantity;
  double unitPrice;
  final int? maxReturnQty;

  CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    this.maxReturnQty,
  });

  double get subtotal => quantity * unitPrice;
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];
  final List<CartItem> _cart = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSearching = false;
  bool _isReturnMode = false;
  Timer? _refreshTimer;
  Timer? _searchDebounce;
  double? _manualTotal; // override for grand total when user edits it

  Purchase? _selectedReturnOrder;
  List<Purchase> _recentSales = [];
  bool _isFetchingSales = false;

  // Customer & Payment
  String _customerType = 'walkin';
  Customer? _selectedCustomer;
  String _paymentMethod = 'Cash';

  late AnimationController _modeAnimController;

  final List<String> _paymentMethods = [
    'Cash',
    'Card',
    'Check',
    'Bank Transfer',
    'Wallet',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _modeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadData();
    _startAutoRefreshTimer();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    _modeAnimController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_isLoading) {
      _loadData(showLoading: false);
    }
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _isSearching = false;
      });
    } else {
      setState(() {
        _isRefreshing = true;
        _isSearching = false;
      });
    }

    try {
      final results = await Future.wait([
        ProductService.instance.getActiveProducts(),
        CustomerService.instance.getActiveCustomers(),
      ]);

      final products = results[0] as List<Product>;
      final customers = results[1] as List<Customer>;

      if (mounted) {
        setState(() {
          _products = products;
          _customers = customers;
          _isLoading = false;
          _isRefreshing = false;
          _isSearching = false;
        });
        final query = _searchController.text.trim();
        if (query.isEmpty) {
          setState(() => _filteredProducts = []);
        } else {
          await _searchProducts(query);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load data: $error'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _filteredProducts = [];
          _isSearching = false;
        });
        _loadData(showLoading: false);
      } else {
        _searchProducts(query);
      }
    });
  }

  Future<void> _searchProducts(String query) async {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredProducts = [];
    });

    try {
      final results = await ProductService.instance.search(query);
      if (!mounted) return;
      setState(() {
        _filteredProducts = results;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      _showSnack('Search failed: $error', AppColors.danger);
    }
  }

  Future<void> _fetchRecentSales() async {
    setState(() => _isFetchingSales = true);
    try {
      final sales = await SaleService.instance.getAll();
      if (mounted) {
        setState(() => _recentSales = sales);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to fetch sales: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _isFetchingSales = false);
    }
  }

  void _startAutoRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _isLoading || _isRefreshing) return;
      _loadData(showLoading: false);
    });
  }

  void _toggleMode(bool isReturn) {
    if (_isReturnMode == isReturn) return;
    setState(() {
      _isReturnMode = isReturn;
      _cart.clear();
      _selectedReturnOrder = null;
    });
    if (isReturn) {
      _modeAnimController.forward();
      _fetchRecentSales();
    } else {
      _modeAnimController.reverse();
    }
  }

  String get _transactionType => _isReturnMode ? 'SaleReturn' : 'Sale';
  String get _checkoutLabel => _isReturnMode ? 'Process Return' : 'Checkout';

  int get _totalItems => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get _grandTotal => _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _effectiveTotal => _manualTotal ?? _grandTotal;

  int _currentReturnQuantity(int productId) {
    final matches = _cart.where((item) => item.product.id == productId);
    return matches.isEmpty ? 0 : matches.first.quantity;
  }

  void _addToCart(
    Product product, {
    int? maxReturnQty,
    int quantity = 1,
    double? unitPrice,
  }) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      final existing = _cart[existingIndex];
      // If caller supplied a specific unit price (e.g. return using original
      // purchase unit cost), update the existing line to use it.
      if (unitPrice != null) existing.unitPrice = unitPrice;
      final nextQuantity = existing.quantity + quantity;
      if (!_isReturnMode && nextQuantity > product.quantity && !PlatformSettingsService.instance.settings.continueSellingWhenStockEmpty) {
        _showSnack('Cannot add more than available stock.', AppColors.danger);
        return;
      }
      if (_isReturnMode &&
          existing.maxReturnQty != null &&
          nextQuantity > existing.maxReturnQty!) {
        _showSnack('Cannot exceed purchased quantity.', AppColors.danger);
        return;
      }
      setState(() => existing.quantity = nextQuantity);
      return;
    }

    if (!_isReturnMode && product.quantity <= 0 && !PlatformSettingsService.instance.settings.continueSellingWhenStockEmpty) {
      _showSnack('Product is out of stock.', AppColors.danger);
      return;
    }

    if (_isReturnMode && maxReturnQty != null && quantity > maxReturnQty) {
      _showSnack(
        'Return quantity cannot exceed purchased quantity.',
        AppColors.danger,
      );
      return;
    }

    setState(() {
      _cart.add(
        CartItem(
          product: product,
          quantity: quantity,
          unitPrice: unitPrice ?? product.sellingPrice,
          maxReturnQty: maxReturnQty,
        ),
      );
      _manualTotal = null; // reset manual override when cart changes
    });
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _updateCartQuantity(CartItem item, int delta) {
    final index = _cart.indexOf(item);
    if (index < 0) return;
    final nextQuantity = item.quantity + delta;
    if (nextQuantity <= 0) {
      setState(() => _cart.removeAt(index));
      return;
    }
    if (!_isReturnMode && nextQuantity > item.product.quantity && !PlatformSettingsService.instance.settings.continueSellingWhenStockEmpty) {
      _showSnack('Cannot exceed available stock.', AppColors.danger);
      return;
    }
    if (_isReturnMode &&
        item.maxReturnQty != null &&
        nextQuantity > item.maxReturnQty!) {
      _showSnack('Cannot exceed purchased quantity.', AppColors.danger);
      return;
    }
    setState(() {
      _cart[index].quantity = nextQuantity;
      _manualTotal = null; // reset manual override when qty changes
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      _showSnack(
        'Add at least one item to cart before checkout.',
        AppColors.danger,
      );
      return;
    }

    if (_customerType == 'customer' && _selectedCustomer == null) {
      _showSnack('Please select a customer.', AppColors.danger);
      return;
    }

    if (_isReturnMode && _selectedReturnOrder == null) {
      _showSnack('Please select a sale order to return.', AppColors.danger);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final items = _cart.map((cartItem) {
        return PurchaseItem(
          productId: cartItem.product.id!,
          quantity: cartItem.quantity,
          unitCost: cartItem.unitPrice,
          subtotal: cartItem.subtotal,
        );
      }).toList();

      final customerNote = _customerType == 'walkin'
          ? 'Walk-in customer'
          : 'Customer: ${_selectedCustomer?.name}';

      final purchase = Purchase(
        referenceNo: '',
        purchaseDate: DateTime.now(),
        customerId: _selectedCustomer?.id,
        type: _transactionType,
        status: 'Completed',
        paymentStatus: 'Paid',
        grandTotal: _effectiveTotal,
        paidAmount: _effectiveTotal,
        dueAmount: 0.0,
        paymentMethod: _paymentMethod,
        note: _isReturnMode
            ? '$customerNote - Return processed for ${_selectedReturnOrder!.referenceNo}'
            : '$customerNote - Sale processed',
        items: items,
      );

      // Both Sale and SaleReturn go through SaleService
      // SaleService handles updating invoice totals and quantities
      final saleId = await SaleService.instance.create(purchase);
      final completedSale = await SaleService.instance.getById(saleId);
      await _loadData();
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _manualTotal = null;
        _selectedCustomer = null;
        _customerType = 'walkin';
        _paymentMethod = 'Cash';
        if (_isReturnMode) {
          _selectedReturnOrder = null;
        }
      });

      _showSnack(
        _isReturnMode
            ? 'Return processed and stock updated.'
            : 'Sale completed and stock updated.',
        AppColors.success,
      );

      if (completedSale != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => InvoiceDetailSheet(sale: completedSale),
        );
      }
    } catch (error) {
      if (mounted) {
        _showSnack('Checkout failed: $error', AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditTotalDialog(String currency) async {
    final controller = TextEditingController(
      text: _effectiveTotal.toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Edit Grand Total',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cart total: $currency${_grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter a custom total (e.g. apply a discount).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Custom Total',
                prefixText: currency,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _manualTotal = null);
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset to Cart Total',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _manualTotal = result);
    }
  }

  Future<void> _showEditPriceDialog(CartItem item, String currency) async {
    final controller = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Edit Unit Price', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New Price',
            prefixText: currency,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        item.unitPrice = result;
        _manualTotal = null; // reset grand total override if any
      });
    }
  }

  // ─────────────────────────── PRODUCT CARD ────────────────────────────────
  Widget _buildProductCard(Product product) {
    final availableStock = product.quantity;
    final isOutOfStock = !_isReturnMode && availableStock <= 0 && !PlatformSettingsService.instance.settings.continueSellingWhenStockEmpty;
    final currency = PlatformSettingsService.instance.settings.currencySymbol;

    Color stockColor = AppColors.success;
    String stockLabel = 'In Stock';
    if (isOutOfStock) {
      stockColor = AppColors.danger;
      stockLabel = 'Out of Stock';
    } else if (availableStock <= 5) {
      stockColor = AppColors.warning;
      stockLabel = 'Low Stock';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isOutOfStock ? null : () => _addToCart(product),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOutOfStock ? AppColors.border : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isOutOfStock
                                    ? AppColors.textSecondary
                                    : AppColors.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SKU: ${product.code}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          stockLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stockColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$currency${product.sellingPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Qty: $availableStock',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (product.categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purpleLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.categoryName!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.purple,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      GestureDetector(
                        onTap: isOutOfStock ? null : () => _addToCart(product),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: isOutOfStock
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryDark,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: isOutOfStock ? AppColors.border : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isReturnMode
                                ? Icons.replay_rounded
                                : Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── CART PANEL ──────────────────────────────────

  Widget _buildCartHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(20))),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cart & Checkout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_totalItems items',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCart(bool isMobile) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2559),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withAlpha(60),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildCartHeader(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Type
                        _sectionLabel('Customer Type', light: true),
                        const SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withAlpha(20),
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _customerTypeChip(
                                'walkin',
                                'Walk-in',
                                Icons.directions_walk_rounded,
                              ),
                              _customerTypeChip(
                                'customer',
                                'Customer',
                                Icons.person_rounded,
                              ),
                            ],
                          ),
                        ),

                        if (_customerType == 'customer') ...[
                          const SizedBox(height: 12),
                          _sectionLabel('Select Customer', light: true),
                          const SizedBox(height: 8),
                          _premiumDropdown<Customer>(
                            value: _selectedCustomer,
                            hint: 'Choose a customer',
                            items: _customers.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              );
                            }).toList(),
                            onChanged: (c) =>
                                setState(() => _selectedCustomer = c),
                            icon: Icons.person_search_rounded,
                          ),
                        ],

                        const SizedBox(height: 12),

                        _sectionLabel('Payment Method', light: true),
                        const SizedBox(height: 8),

                        _premiumDropdown<String>(
                          value: _paymentMethod,
                          hint: 'Select payment',
                          items: _paymentMethods.map((m) {
                            return DropdownMenuItem(value: m, child: Text(m));
                          }).toList(),
                          onChanged: (m) {
                            if (m != null) {
                              setState(() => _paymentMethod = m);
                            }
                          },
                          icon: Icons.payment_rounded,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      color: Colors.white.withAlpha(20),
                      height: 1,
                    ),
                  ),

                  if (_cart.isEmpty)
                    _buildEmptyCart()
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: _cart.length,
                      separatorBuilder: (_, _) => Divider(
                        color: Colors.white.withAlpha(20),
                        height: 20,
                      ),
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return _buildCartItem(item, index, currency);
                      },
                    ),
                ],
              ),
            ),
          ),

          // Fixed Footer
          if (_cart.isNotEmpty) _buildCheckoutFooter(currency),
        ],
      ),
    );
  }

  Widget _customerTypeChip(String type, String label, IconData icon) {
    final isSelected = _customerType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _customerType = type;
            if (type == 'walkin') _selectedCustomer = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: isSelected
                ? Border.all(color: Colors.white.withAlpha(40))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primary : Colors.white54,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withAlpha(25)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withAlpha(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                dropdownColor: const Color(0xFF243060),
                hint: Text(
                  hint,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                value: value,
                items: items,
                onChanged: onChanged,
                iconEnabledColor: Colors.white54,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, {bool light = false}) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: light ? Colors.white60 : AppColors.textSecondary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(30)),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white38,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Cart is empty',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select products from the left\nto add them here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index, String currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.inventory_2_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _showEditPriceDialog(item, currency),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isReturnMode
                          ? '$currency${item.unitPrice.toStringAsFixed(2)} × ${item.quantity} = -$currency${item.subtotal.toStringAsFixed(2)}'
                          : '$currency${item.unitPrice.toStringAsFixed(2)} × ${item.quantity} = $currency${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isReturnMode
                            ? const Color(0xFFFF6B6B)
                            : Colors.white54,
                        fontWeight: _isReturnMode
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 10, color: Colors.white70),
                          SizedBox(width: 2),
                          Text('Edit', style: TextStyle(fontSize: 9, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Quantity controls
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyButton(
                icon: Icons.remove_rounded,
                onTap: () => _updateCartQuantity(item, -1),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  item.quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              _qtyButton(
                icon: Icons.add_rounded,
                onTap: () => _updateCartQuantity(item, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Delete
        GestureDetector(
          onTap: () => setState(() {
            _cart.removeAt(index);
            _manualTotal = null;
          }),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.danger.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFFFF6B6B),
              size: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: Colors.white70),
      ),
    );
  }

  Widget _buildCheckoutFooter(String currency) {
    final checkoutColor = _isReturnMode ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withAlpha(20))),
        color: Colors.white.withAlpha(5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_totalItems item${_totalItems > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Order Total',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isReturnMode ? 'Refund' : 'Total',
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                      const SizedBox(width: 6),
                      if (!_isReturnMode)
                        GestureDetector(
                          onTap: () => _showEditTotalDialog(currency),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(60),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary.withAlpha(100)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_rounded, size: 12, color: Colors.white70),
                                SizedBox(width: 4),
                                Text('Edit', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_isReturnMode ? '-' : ''}$currency${_effectiveTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _isReturnMode
                          ? const Color(0xFFFF6B6B)
                          : (_manualTotal != null ? AppColors.warning : Colors.white),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (_manualTotal != null)
                    Text(
                      'Original: $currency${_grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: _isLoading ? null : _checkout,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [checkoutColor, checkoutColor.withAlpha(210)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: checkoutColor.withAlpha(100),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isReturnMode
                                  ? Icons.replay_rounded
                                  : Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _checkoutLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── MAIN BUILD ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isMobile),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: isMobile
                    ? Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildSearchAndList(isMobile),
                          ),
                          const SizedBox(height: 12),
                          Expanded(flex: 5, child: _buildCart(isMobile)),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildSearchAndList(isMobile),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: _buildCart(isMobile)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final titleContent = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Point of Sale',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Search products, complete transactions, or refresh after inventory changes',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleContent,
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _isRefreshing
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: _isLoading
                                ? null
                                : () => _loadData(showLoading: false),
                            icon: const Icon(Icons.refresh_rounded),
                            color: AppColors.primary,
                            tooltip: 'Refresh POS products',
                          ),
                    _buildModeToggle(),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: titleContent),
                _isRefreshing
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => _loadData(showLoading: false),
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.primary,
                        tooltip: 'Refresh POS products',
                      ),
                _buildModeToggle(),
              ],
            ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeChip(
            label: 'Sale',
            icon: Icons.shopping_bag_rounded,
            isSelected: !_isReturnMode,
            color: AppColors.primary,
            onTap: () => _toggleMode(false),
          ),
          const SizedBox(width: 4),
          _modeChip(
            label: 'Return',
            icon: Icons.replay_rounded,
            isSelected: _isReturnMode,
            color: AppColors.danger,
            onTap: () => _toggleMode(true),
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withAlpha(210)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndList(bool isMobile) {
    if (_isReturnMode) {
      if (_selectedReturnOrder != null) {
        return _buildReturnOrderItems();
      }
      return _buildReturnOrderSearch(isMobile);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Products',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredProducts.length} found',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _onSearchChanged(),
                decoration: InputDecoration(
                  hintText: 'Search by name, SKU, category, brand…',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.textSecondary,
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ),
          Expanded(child: _buildProductListBody()),
        ],
      ),
    );
  }

  Widget _buildProductListBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, color: AppColors.border, size: 48),
            const SizedBox(height: 10),
            const Text(
              'Type to search products by name, SKU, category, brand…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: AppColors.border, size: 48),
            const SizedBox(height: 10),
            const Text(
              'No products found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_filteredProducts[index]);
      },
    );
  }

  Widget _buildReturnOrderSearch(bool isMobile) {
    final currency = PlatformSettingsService.instance.settings.currencySymbol;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.purple,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Select Order to Return',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onSubmitted: (val) async {
                  if (val.trim().isEmpty) return;
                  setState(() => _isFetchingSales = true);
                  try {
                    final order = await SaleService.instance.getByReference(
                      val.trim(),
                    );
                    if (order != null) {
                      final fullOrder = await SaleService.instance.getById(
                        order.id!,
                      );
                      setState(() => _selectedReturnOrder = fullOrder);
                    } else {
                      if (mounted) {
                        _showSnack('Sale order not found', AppColors.warning);
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      _showSnack('Error finding order', AppColors.danger);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isFetchingSales = false);
                    }
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Scan or enter Sale Reference No (e.g. SAL-0001)',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isFetchingSales
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _recentSales.length,
                    itemBuilder: (ctx, i) {
                      final sale = _recentSales[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.receipt_rounded,
                          color: AppColors.purple,
                        ),
                        title: Text(
                          sale.referenceNo,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Total: $currency${sale.grandTotal.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          setState(() => _isFetchingSales = true);
                          try {
                            final fullOrder = await SaleService.instance
                                .getById(sale.id!);
                            if (mounted) {
                              setState(() => _selectedReturnOrder = fullOrder);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isFetchingSales = false);
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnOrderItems() {
    final order = _selectedReturnOrder!;
    final currency = PlatformSettingsService.instance.settings.currencySymbol;
    final orderDate = order.purchaseDate;
    final formattedDate =
        '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';

    int availableReturnQty(PurchaseItem item) {
      return item.quantity - _currentReturnQuantity(item.productId);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _selectedReturnOrder = null),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return Order ${order.referenceNo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Date: $formattedDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Items: ${order.items.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$currency${order.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              'Tap an item to choose return quantity and add it to the refund cart.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final item = order.items[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product?.name ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Purchased Qty: ${item.quantity} • $currency${item.unitCost.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Returnable: ${availableReturnQty(item)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: availableReturnQty(item) > 0
                                    ? AppColors.primary
                                    : AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: availableReturnQty(item) > 0
                            ? () {
                                if (item.product != null) {
                                  _showReturnQuantityDialog(item);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Return',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReturnQuantityDialog(PurchaseItem item) async {
    final availableQty = item.quantity - _currentReturnQuantity(item.productId);
    if (availableQty <= 0) {
      _showSnack(
        'All units for this item are already added to the return cart.',
        AppColors.warning,
      );
      return;
    }

    int selectedQty = 1;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select return quantity'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Returnable quantity: $availableQty'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded),
                        onPressed: selectedQty > 1
                            ? () => setState(() => selectedQty -= 1)
                            : null,
                      ),
                      Container(
                        width: 56,
                        alignment: Alignment.center,
                        child: Text(
                          '$selectedQty',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: selectedQty < availableQty
                            ? () => setState(() => selectedQty += 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addToCart(
                  item.product!,
                  maxReturnQty: item.quantity,
                  quantity: selectedQty,
                  unitPrice: item.unitCost,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Add to return'),
            ),
          ],
        );
      },
    );
  }
}
