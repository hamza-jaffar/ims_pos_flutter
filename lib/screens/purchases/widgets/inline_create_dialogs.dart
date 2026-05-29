import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/supplier.dart';
import 'package:ims_pos_system/services/supplier_service.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/services/product_service.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';

class InlineCreateDialogs {
  
  static Future<Supplier?> showCreateSupplierDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    bool isSaving = false;

    return await showDialog<Supplier>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add New Supplier'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Supplier Name *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isSaving = true);
                      try {
                        final supplier = Supplier(
                          name: nameController.text.trim(),
                          email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                        );
                        final id = await SupplierService.instance.create(supplier);
                        final created = await SupplierService.instance.getById(id);
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(created);
                        }
                      } catch (e) {
                        setState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  static Future<Product?> showCreateProductDialog(BuildContext context, {String? initialName}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final codeController = TextEditingController();
    final purchasePriceController = TextEditingController(text: '0');
    final sellingPriceController = TextEditingController(text: '0');
    bool isSaving = false;

    return await showDialog<Product>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Product Name *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Product Code *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: purchasePriceController,
                        decoration: InputDecoration(labelText: 'Purchase Price (${PlatformSettingsService.instance.settings.currencySymbol})'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: sellingPriceController,
                        decoration: InputDecoration(labelText: 'Selling Price (${PlatformSettingsService.instance.settings.currencySymbol})'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isSaving = true);
                      try {
                        final product = Product(
                          name: nameController.text.trim(),
                          code: codeController.text.trim(),
                          purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
                          sellingPrice: double.tryParse(sellingPriceController.text) ?? 0.0,
                          quantity: 0,
                        );
                        final id = await ProductService.instance.create(product);
                        final created = await ProductService.instance.getById(id);
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop(created);
                        }
                      } catch (e) {
                        setState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
