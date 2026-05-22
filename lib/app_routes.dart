import 'package:flutter/material.dart';
import 'package:ims_pos_system/models/brand.dart';
import 'package:ims_pos_system/models/category.dart';
import 'package:ims_pos_system/models/supplier.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/screens/inventory/brand/brand_screen.dart';
import 'package:ims_pos_system/screens/inventory/brand/create_brand_screen.dart';
import 'package:ims_pos_system/screens/inventory/brand/edit_brand_screen.dart';
import 'package:ims_pos_system/screens/inventory/supplier/supplier_screen.dart';
import 'package:ims_pos_system/screens/inventory/supplier/create_supplier_screen.dart';
import 'package:ims_pos_system/screens/inventory/supplier/edit_supplier_screen.dart';
import 'package:ims_pos_system/screens/inventory/category/category_screen.dart';
import 'package:ims_pos_system/screens/inventory/category/create_category_screen.dart';
import 'package:ims_pos_system/screens/inventory/category/edit_category_screen.dart';
import 'package:ims_pos_system/screens/inventory/product/create_product_screen.dart';
import 'package:ims_pos_system/screens/inventory/product/product_screen.dart';
import 'package:ims_pos_system/screens/inventory/product/edit_product_screen.dart';
import 'package:ims_pos_system/screens/inventory/product/low_stocks_screen.dart';
import 'package:ims_pos_system/screens/settings/platform_settings_screen.dart';
import 'package:ims_pos_system/screens/settings/user_management_screen.dart';

class AppRoutes {
  static const String products = '/products';
  static const String createProduct = '/products/create';
  static const String editProduct = '/products/edit';
  static const String lowStocks = '/products/low-stock';
  static const String categories = '/categories';
  static const String createCategory = '/category/create';
  static const String editCategory = '/category/edit';
  static const String brands = '/brands';
  static const String createBrand = '/brand/create';
  static const String editBrand = '/brand/edit';
  static const String suppliers = '/suppliers';
  static const String createSupplier = '/supplier/create';
  static const String editSupplier = '/supplier/edit';
  static const String platformSettings = '/settings/platform';
  static const String userManagement = '/settings/users';

  /// Parses a route string and returns the matching widget.
  static Widget? getContent(
    String route, {
    ValueChanged<String>? onRouteSelected,
    Map<String, dynamic>? args,
  }) {
    final callback = onRouteSelected ?? (r) {};

    switch (route) {
      case products:
        return ProductScreen(onRouteSelected: callback);
      case createProduct:
        return CreateProductScreen(onRouteSelected: callback);
      case lowStocks:
        return LowStocksScreen(onRouteSelected: callback);
      case categories:
        return CategoryScreen(onRouteSelected: callback);
      case createCategory:
        return CreateCategoryScreen(onRouteSelected: callback);
      case brands:
        return BrandScreen(onRouteSelected: callback);
      case createBrand:
        return CreateBrandScreen(onRouteSelected: callback);
      case suppliers:
        return SupplierScreen(onRouteSelected: callback);
      case createSupplier:
        return CreateSupplierScreen(onRouteSelected: callback);
      case platformSettings:
        return PlatformSettingsScreen(onRouteSelected: callback);
      case userManagement:
        return UserManagementScreen(onRouteSelected: callback);
    }

    // Parameterized: /products/edit/:id
    if (route.startsWith('$editProduct/')) {
      final idStr = route.substring('$editProduct/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        final product = args?['product'] as Product?;
        return EditProductScreen(
          onRouteSelected: callback,
          productId: id,
          initialProduct: product,
        );
      }
    }

    // Parameterized: /category/edit/:id
    if (route.startsWith('$editCategory/')) {
      final idStr = route.substring('$editCategory/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        final category = args?['category'] as Category?;
        return EditCategoryScreen(
          onRouteSelected: callback,
          categoryId: id,
          initialCategory: category,
        );
      }
    }

    // Parameterized: /brand/edit/:id
    if (route.startsWith('$editBrand/')) {
      final idStr = route.substring('$editBrand/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        final brand = args?['brand'] as Brand?;
        return EditBrandScreen(
          onRouteSelected: callback,
          brandId: id,
          initialBrand: brand,
        );
      }
    }

    // Parameterized: /supplier/edit/:id
    if (route.startsWith('$editSupplier/')) {
      final idStr = route.substring('$editSupplier/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        final supplier = args?['supplier'] as Supplier?;
        return EditSupplierScreen(
          onRouteSelected: callback,
          supplierId: id,
          initialSupplier: supplier,
        );
      }
    }

    return null;
  }

  static Map<String, WidgetBuilder> routes = {
    products: (context) => ProductScreen(onRouteSelected: (r) {}),
    createProduct: (context) => CreateProductScreen(onRouteSelected: (r) {}),
    lowStocks: (context) => LowStocksScreen(onRouteSelected: (r) {}),
    categories: (context) => CategoryScreen(onRouteSelected: (r) {}),
    createCategory: (context) =>
        CreateCategoryScreen(onRouteSelected: (r) {}),
    brands: (context) => BrandScreen(onRouteSelected: (r) {}),
    createBrand: (context) => CreateBrandScreen(onRouteSelected: (r) {}),
    suppliers: (context) => SupplierScreen(onRouteSelected: (r) {}),
    createSupplier: (context) =>
        CreateSupplierScreen(onRouteSelected: (r) {}),
    platformSettings: (context) =>
        PlatformSettingsScreen(onRouteSelected: (r) {}),
    userManagement: (context) =>
        UserManagementScreen(onRouteSelected: (r) {}),
  };
}
