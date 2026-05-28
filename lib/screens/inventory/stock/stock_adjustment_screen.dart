import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/stock_adjustment.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/stock_adjustment_service.dart';

class StockAdjustmentScreen extends StatefulWidget {
  final ValueChanged<String> onRouteSelected;
  final int productId;

  const StockAdjustmentScreen({
    super.key,
    required this.onRouteSelected,
    required this.productId,
  });

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  Product? _product;
  bool _isLoading = true;
  String _adjustmentType = 'increase';

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await ProductService.instance.getById(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load product: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveAdjustment() async {
    if (!_formKey.currentState!.validate() || _product == null) return;
    final amount = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (amount <= 0) {
      return;
    }

    final currentQty = _product!.quantity;
    final nextQty = _adjustmentType == 'increase'
        ? currentQty + amount
        : currentQty - amount;

    if (nextQty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity cannot be reduced below zero.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    await ProductService.instance.updateStock(_product!.id!, nextQty);
    await StockAdjustmentService.instance.create(
      StockAdjustment(
        productId: _product!.id!,
        oldQuantity: currentQty,
        newQuantity: nextQty,
        adjustmentType: _adjustmentType,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock updated to $nextQty for ${_product!.name}.'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onRouteSelected(AppRoutes.stocks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Adjustment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Product: ${_product?.name ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => widget.onRouteSelected(AppRoutes.stocks),
                    child: const Text('Back to Stock Management'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_product == null)
                const Center(
                  child: Text(
                    'Product not found.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoTile(
                                'Current stock',
                                '${_product!.quantity} pcs',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoTile(
                                'Low stock threshold',
                                '${_product!.minStockQuantity} pcs',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Adjustment type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildAdjustmentOption('Increase', 'increase'),
                            const SizedBox(width: 12),
                            _buildAdjustmentOption('Decrease', 'decrease'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            hintText: 'Enter quantity to adjust',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter an adjustment quantity.';
                            }
                            final number = int.tryParse(value.trim());
                            if (number == null || number <= 0) {
                              return 'Quantity must be a positive whole number.';
                            }
                            if (_adjustmentType == 'decrease' &&
                                number > _product!.quantity) {
                              return 'Cannot remove more than current stock.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Reason (optional)',
                            hintText:
                                'E.g. Received goods, damaged items, correction',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _saveAdjustment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Apply Adjustment'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  widget.onRouteSelected(AppRoutes.stocks),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textMain,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentOption(String label, String value) {
    final selected = _adjustmentType == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _adjustmentType = value);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
