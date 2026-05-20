import 'package:flutter/material.dart';
import 'package:ims_pos_system/models/category.dart';
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
  static const String editCategory = '/category/edit'; // used as prefix: /category/edit/:id

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

    return null;
  }

  static Map<String, WidgetBuilder> routes = {
    products: (context) => const ProductScreen(),
    createProduct: (context) => const CreateProductScreen(),
    categories: (context) => CategoryScreen(onRouteSelected: (r) {}),
    createCategory: (context) => CreateCategoryScreen(onRouteSelected: (r) {}),
  };
}
