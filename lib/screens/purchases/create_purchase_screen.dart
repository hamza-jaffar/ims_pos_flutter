import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/models/purchase_item.dart';
import 'package:ims_pos_system/models/supplier.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/purchase_service.dart';
import 'package:ims_pos_system/services/supplier_service.dart';
import 'package:ims_pos_system/widgets/searchable_dropdown.dart';
import 'package:ims_pos_system/screens/purchases/widgets/inline_create_dialogs.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';

class CreatePurchaseScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  final String purchaseType; // Purchase, Order, Return

  const CreatePurchaseScreen({
    super.key,
    required this.onRouteSelected,
    this.purchaseType = 'Purchase',
  });

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Supplier> _suppliers = [];
  int? _selectedSupplierId;

  List<Product> _products = [];
  int? _selectedProductId;

  final List<PurchaseItem> _cartItems = [];

  String _status = 'Received'; // or 'Ordered', 'Pending', 'Returned'
  String _paymentStatus = 'Unpaid';
  String _paymentMethod = 'Cash';
  final _noteController = TextEditingController();
  final _paidAmountController = TextEditingController();
  double _paidAmount = 0.0;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseType == 'Order') _status = 'Ordered';
    if (widget.purchaseType == 'Return') _status = 'Returned';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sups = await SupplierService.instance.getActiveSuppliers();
      final prods = await ProductService.instance.getActiveProducts();
      if (mounted) {
        setState(() {
          _suppliers = sups;
          _products = prods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (_selectedProductId == null) return;

    final product = _products.firstWhere((p) => p.id == _selectedProductId);

    // Check if already in cart
    final existingIndex = _cartItems.indexWhere(
      (i) => i.productId == product.id,
    );
    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      setState(() {
        _cartItems[existingIndex] = existing.copyWith(
          quantity: existing.quantity + 1,
          subtotal: (existing.quantity + 1) * existing.unitCost,
        );
        _selectedProductId = null;
      });
    } else {
      setState(() {
        _cartItems.add(
          PurchaseItem(
            productId: product.id!,
            quantity: 1,
            unitCost: product.purchasePrice,
            subtotal: product.purchasePrice,
            product: product,
          ),
        );
        _selectedProductId = null;
      });
    }
  }

  double get _grandTotal {
    return _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      double paidAmount = 0.0;
      double dueAmount = 0.0;

      if (_paymentStatus == 'Paid') {
        paidAmount = _grandTotal;
        dueAmount = 0.0;
      } else if (_paymentStatus == 'Unpaid') {
        paidAmount = 0.0;
        dueAmount = _grandTotal;
      } else if (_paymentStatus == 'Partial') {
        paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
        if (paidAmount <= 0 || paidAmount >= _grandTotal) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid partial paid amount.'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
        dueAmount = _grandTotal - paidAmount;
      }

      final purchase = Purchase(
        referenceNo: '', // Auto-generated
        supplierId: _selectedSupplierId,
        purchaseDate: DateTime.now(),
        type: widget.purchaseType,
        status: _status,
        paymentStatus: _paymentStatus,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim(),
        grandTotal: _grandTotal,
        dueAmount: dueAmount,
        paidAmount: paidAmount,
        items: _cartItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await PurchaseService.instance.create(purchase);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.purchaseType} created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        if (widget.purchaseType == 'Order') {
          widget.onRouteSelected(AppRoutes.purchaseOrders);
        } else if (widget.purchaseType == 'Return') {
          widget.onRouteSelected(AppRoutes.purchaseReturns);
        } else {
          widget.onRouteSelected(AppRoutes.purchases);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _getListRoute() {
    if (widget.purchaseType == 'Order') return AppRoutes.purchaseOrders;
    if (widget.purchaseType == 'Return') return AppRoutes.purchaseReturns;
    return AppRoutes.purchases;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => widget.onRouteSelected(_getListRoute()),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Back to ${widget.purchaseType}s',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Create ${widget.purchaseType}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                // Top section (Supplier, Status)
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SearchableDropdown<int>(
                              label: 'Supplier',
                              hint: 'Select Supplier',
                              items: _suppliers
                                  .map(
                                    (s) => SearchableDropdownItem(
                                      value: s.id!,
                                      label: s.name,
                                    ),
                                  )
                                  .toList(),
                              selectedValue: _selectedSupplierId,
                              onChanged: (v) {
                                setState(() {
                                  _selectedSupplierId = v;
                                  if (v != null && _selectedProductId != null) {
                                    final currentProd = _products.firstWhere(
                                      (p) => p.id == _selectedProductId,
                                    );
                                    if (currentProd.supplierId != v) {
                                      _selectedProductId = null;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Add New Supplier',
                            child: InkWell(
                              onTap: () async {
                                final sup =
                                    await InlineCreateDialogs.showCreateSupplierDialog(
                                      context,
                                    );
                                if (sup != null) {
                                  setState(() {
                                    _suppliers.add(sup);
                                    _selectedSupplierId = sup.id;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Status'),
                              initialValue: _status,
                              items:
                                  ['Received', 'Pending', 'Ordered', 'Returned']
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Products section
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
                        'Add Products',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: SearchableDropdown<int>(
                              label: 'Product',
                              hint: 'Select Product',
                              items: _products
                                  .where(
                                    (p) =>
                                        _selectedSupplierId == null ||
                                        p.supplierId == _selectedSupplierId,
                                  )
                                  .map(
                                    (p) => SearchableDropdownItem(
                                      value: p.id!,
                                      label: '${p.name} (${p.code})',
                                    ),
                                  )
                                  .toList(),
                              selectedValue: _selectedProductId,
                              onChanged: (v) {
                                setState(() {
                                  _selectedProductId = v;
                                  if (v != null) {
                                    final product = _products.firstWhere(
                                      (p) => p.id == v,
                                    );
                                    if (product.supplierId != null) {
                                      _selectedSupplierId = product.supplierId;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Add New Product',
                            child: InkWell(
                              onTap: () async {
                                final prod =
                                    await InlineCreateDialogs.showCreateProductDialog(
                                      context,
                                    );
                                if (prod != null) {
                                  setState(() {
                                    _products.add(prod);
                                    _selectedProductId = prod.id;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Add to List',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildCartTable(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Grand Total: ',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${PlatformSettingsService.instance.settings.currencySymbol}${_grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment & Submit
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Payment Status'),
                              initialValue: _paymentStatus,
                              items: ['Paid', 'Unpaid', 'Partial']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _paymentStatus = v!;
                                if (_paymentStatus != 'Partial') {
                                  _paidAmountController.text = '';
                                  _paidAmount = 0.0;
                                }
                              }),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: _inputDecoration('Payment Method'),
                              initialValue: _paymentMethod,
                              items: ['Cash', 'Card', 'Bank Transfer']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v!),
                            ),
                          ),
                        ],
                      ),
                      if (_paymentStatus == 'Partial') ...[
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _paidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration('Partial Paid Amount'),
                          validator: (value) {
                            if (_paymentStatus != 'Partial') return null;
                            final amount =
                                double.tryParse(value?.trim() ?? '') ?? -1;
                            if (amount <= 0 || amount >= _grandTotal) {
                              return 'Enter a valid partial amount less than total';
                            }
                            return null;
                          },
                          onChanged: (value) => setState(
                            () => _paidAmount = double.tryParse(value) ?? 0.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Remaining Due: ${PlatformSettingsService.instance.settings.currencySymbol}${(_grandTotal - _paidAmount).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Purchase Note (Optional)',
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => widget.onRouteSelected(_getListRoute()),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(color: Colors.white),
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
        ],
      ),
    );
  }

  Widget _buildCartTable() {
    if (_cartItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No products added yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
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
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Product',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Unit Cost',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Subtotal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 40, child: Text('')),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cartItems.length,
          itemBuilder: (ctx, index) {
            final item = _cartItems[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.product?.name ?? '')),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TextFormField(
                        initialValue: item.unitCost.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(8),
                        ),
                        onChanged: (val) {
                          final cost = double.tryParse(val) ?? 0.0;
                          setState(() {
                            _cartItems[index] = item.copyWith(
                              unitCost: cost,
                              subtotal: cost * item.quantity,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () {
                              if (item.quantity > 1) {
                                setState(() {
                                  _cartItems[index] = item.copyWith(
                                    quantity: item.quantity - 1,
                                    subtotal:
                                        (item.quantity - 1) * item.unitCost,
                                  );
                                });
                              }
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: '${item.quantity}',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.all(4),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                final qty = int.tryParse(val) ?? item.quantity;
                                if (qty > 0) {
                                  setState(() {
                                    _cartItems[index] = item.copyWith(
                                      quantity: qty,
                                      subtotal: qty * item.unitCost,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              setState(() {
                                _cartItems[index] = item.copyWith(
                                  quantity: item.quantity + 1,
                                  subtotal: (item.quantity + 1) * item.unitCost,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${PlatformSettingsService.instance.settings.currencySymbol}${item.subtotal.toStringAsFixed(2)}',
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _cartItems.removeAt(index)),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
