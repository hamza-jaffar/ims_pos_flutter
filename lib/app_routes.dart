import 'package:flutter/material.dart';
import 'package:ims_pos_system/models/brand.dart';
import 'package:ims_pos_system/models/category.dart';
import 'package:ims_pos_system/screens/inventory/brand/brand_screen.dart';
import 'package:ims_pos_system/screens/inventory/brand/create_brand_screen.dart';
import 'package:ims_pos_system/screens/inventory/brand/edit_brand_screen.dart';
import 'package:ims_pos_system/screens/inventory/category/category_screen.dart';
import 'package:ims_pos_system/screens/inventory/category/create_category_screen.dart';
import 'package:ims_pos_system/screens/inventory/category/edit_category_screen.dart';
import 'package:ims_pos_system/screens/inventory/product/create_product_screen.dart';
import 'package:ims_pos_system/screens/inventory/product/product_screen.dart';

class AppRoutes {
  static const String products = '/products';
  static const String createProduct = '/products/create';
  static const String categories = '/categories';
  static const String createCategory = '/category/create';
  static const String editCategory =
      '/category/edit'; // used as prefix: /category/edit/:id
  static const String brands = '/brands';
  static const String createBrand = '/brand/create';
  static const String editBrand =
      '/brand/edit'; // used as prefix: /brand/edit/:id

  /// Parses a route string and returns the matching widget.
  /// Accepts an [onRouteSelected] callback for seamless in-layout navigation.
  /// Accepts optional [args] map for passing data like a category to edit.
  static Widget? getContent(
    String route, {
    ValueChanged<String>? onRouteSelected,
    Map<String, dynamic>? args,
  }) {
    final callback = onRouteSelected ?? (r) {};

    // Exact matches
    switch (route) {
      case products:
        return const ProductScreen();
      case createProduct:
        return const CreateProductScreen();
      case categories:
        return CategoryScreen(onRouteSelected: callback);
      case createCategory:
        return CreateCategoryScreen(onRouteSelected: callback);
      case brands:
        return BrandScreen(onRouteSelected: callback);
      case createBrand:
        return CreateBrandScreen(onRouteSelected: callback);
    }

    // Parameterized: /category/edit/:id
    if (route.startsWith('$editCategory/')) {
      final idStr = route.substring('$editCategory/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        // If args already carries the category (passed from list), use it directly.
        // Otherwise, EditCategoryScreen will load it by ID.
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

    return null;
  }

  static Map<String, WidgetBuilder> routes = {
    products: (context) => const ProductScreen(),
    createProduct: (context) => const CreateProductScreen(),
    categories: (context) => CategoryScreen(onRouteSelected: (r) {}),
    createCategory: (context) => CreateCategoryScreen(onRouteSelected: (r) {}),
    brands: (context) => BrandScreen(onRouteSelected: (r) {}),
    createBrand: (context) => CreateBrandScreen(onRouteSelected: (r) {}),
  };
}
