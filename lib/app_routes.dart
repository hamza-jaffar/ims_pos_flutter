import 'package:flutter/cupertino.dart';
import 'package:ims_pos_system/screens/inventory/product/create_product_screen.dart';
import 'package:ims_pos_system/screens/inventory/product/product_screen.dart';

class AppRoutes {
  static const String products = '/products';
  static const String createProduct = '/products/create';

  static Widget? getContent(String route) {
    switch (route) {
      case products:
        return const ProductScreen();
      case createProduct:
        return const CreateProductScreen();
      default:
        return null;
    }
  }

  static Map<String, WidgetBuilder> routes = {
    products: (context) => const ProductScreen(),
    createProduct: (context) => const CreateProductScreen(),
  };
}
