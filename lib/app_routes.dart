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
import 'package:ims_pos_system/screens/inventory/stock/stock_adjustment_screen.dart';
import 'package:ims_pos_system/screens/inventory/stock/stock_history_screen.dart';
import 'package:ims_pos_system/screens/inventory/stock/stock_management_screen.dart';
import 'package:ims_pos_system/screens/inventory/room/room_screen.dart';
import 'package:ims_pos_system/screens/inventory/room/create_room_screen.dart';
import 'package:ims_pos_system/screens/inventory/room/edit_room_screen.dart';
import 'package:ims_pos_system/screens/settings/platform_settings_screen.dart';
import 'package:ims_pos_system/screens/settings/user_management_screen.dart';
import 'package:ims_pos_system/models/customer.dart';
import 'package:ims_pos_system/screens/peoples/customer/customer_screen.dart';
import 'package:ims_pos_system/screens/peoples/customer/create_customer_screen.dart';
import 'package:ims_pos_system/screens/peoples/customer/edit_customer_screen.dart';
import 'package:ims_pos_system/screens/purchases/purchase_list_screen.dart';
import 'package:ims_pos_system/screens/purchases/create_purchase_screen.dart';
import 'package:ims_pos_system/screens/reports/purchase_report_screen.dart';
import 'package:ims_pos_system/screens/reports/sales_report_screen.dart';
import 'package:ims_pos_system/screens/pos/sales_history_screen.dart';
import 'package:ims_pos_system/pos/index.dart';
import 'package:ims_pos_system/screens/dashboard/dashboard_screen.dart';
import 'package:ims_pos_system/screens/invoices/invoice_screen.dart';
import 'package:ims_pos_system/screens/search_results_screen.dart';

class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String invoices = '/invoices';
  static const String products = '/products';
  static const String createProduct = '/products/create';
  static const String editProduct = '/products/edit';
  static const String lowStocks = '/products/low-stock';
  static const String stocks = '/stocks';
  static const String stockAdjustment = '/stock/adjust';
  static const String stockHistory = '/stocks/history';
  static const String categories = '/categories';
  static const String createCategory = '/category/create';
  static const String editCategory = '/category/edit';
  static const String brands = '/brands';
  static const String createBrand = '/brand/create';
  static const String editBrand = '/brand/edit';
  static const String suppliers = '/suppliers';
  static const String createSupplier = '/supplier/create';
  static const String editSupplier = '/supplier/edit';
  static const String customers = '/customers';
  static const String createCustomer = '/customer/create';
  static const String editCustomer = '/customer/edit';
  static const String purchases = '/purchases';
  static const String createPurchase = '/purchase/create';
  static const String purchaseOrders = '/purchase-orders';
  static const String createPurchaseOrder = '/purchase-order/create';
  static const String purchaseReturns = '/purchase-returns';
  static const String createPurchaseReturn = '/purchase-return/create';
  static const String rooms = '/rooms';
  static const String createRoom = '/room/create';
  static const String editRoom = '/room/edit';
  static const String platformSettings = '/settings/platform';
  static const String userManagement = '/settings/users';
  static const String purchaseReport = '/reports/purchase';
  static const String salesReport = '/reports/sales';
  static const String salesHistory = '/sales/history';
  static const String pos = '/pos';

  /// Parses a route string and returns the matching widget.
  static Widget? getContent(
    String route, {
    ValueChanged<String>? onRouteSelected,
    Map<String, dynamic>? args,
  }) {
    final callback = onRouteSelected ?? (r) {};

    switch (route) {
      case dashboard:
        return DashboardScreen(onRouteSelected: callback);
      case invoices:
        return InvoiceScreen(onRouteSelected: callback);
      case products:
        return ProductScreen(onRouteSelected: callback);
      case createProduct:
        return CreateProductScreen(onRouteSelected: callback);
      case lowStocks:
        return LowStocksScreen(onRouteSelected: callback);
      case stocks:
        return StockManagementScreen(onRouteSelected: callback);
      case stockHistory:
        return StockHistoryScreen(onRouteSelected: callback);
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
      case customers:
        return CustomerScreen(onRouteSelected: callback);
      case createCustomer:
        return CreateCustomerScreen(onRouteSelected: callback);
      case purchases:
        return PurchaseListScreen(
          onRouteSelected: callback,
          purchaseType: 'Purchase',
        );
      case createPurchase:
        return CreatePurchaseScreen(
          onRouteSelected: callback,
          purchaseType: 'Purchase',
        );
      case purchaseOrders:
        return PurchaseListScreen(
          onRouteSelected: callback,
          purchaseType: 'Order',
        );
      case createPurchaseOrder:
        return CreatePurchaseScreen(
          onRouteSelected: callback,
          purchaseType: 'Order',
        );
      case purchaseReturns:
        return PurchaseListScreen(
          onRouteSelected: callback,
          purchaseType: 'Return',
        );
      case createPurchaseReturn:
        return CreatePurchaseScreen(
          onRouteSelected: callback,
          purchaseType: 'Return',
        );
      case rooms:
        return RoomScreen(onRouteSelected: callback);
      case createRoom:
        return CreateRoomScreen(onRouteSelected: callback);
      case platformSettings:
        return PlatformSettingsScreen(onRouteSelected: callback);
      case userManagement:
        return UserManagementScreen(onRouteSelected: callback);
      case purchaseReport:
        return PurchaseReportScreen(onRouteSelected: callback);
      case salesReport:
        return SalesReportScreen(onRouteSelected: callback);
      case salesHistory:
        return SalesHistoryScreen(onRouteSelected: callback);
      case pos:
        return const POSWindow();
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

    // Parameterized: /stock/adjust/:id
    if (route.startsWith('$stockAdjustment/')) {
      final idStr = route.substring('$stockAdjustment/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        return StockAdjustmentScreen(onRouteSelected: callback, productId: id);
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

    // Parameterized: /customer/edit/:id
    if (route.startsWith('$editCustomer/')) {
      final idStr = route.substring('$editCustomer/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        final customer = args?['customer'] as Customer?;
        return EditCustomerScreen(
          onRouteSelected: callback,
          customerId: id,
          initialCustomer: customer,
        );
      }
    }

    // Parameterized: /room/edit/:id
    if (route.startsWith('$editRoom/')) {
      final idStr = route.substring('$editRoom/'.length);
      final id = int.tryParse(idStr);
      if (id != null) {
        final room = args?['room'];
        return EditRoomScreen(
          onRouteSelected: callback,
          roomId: id,
          initialRoom: room,
        );
      }
    }

    // Parameterized: /search/:query
    if (route.startsWith('/search/')) {
      final query = Uri.decodeComponent(route.substring('/search/'.length));
      return SearchResultsScreen(
        query: query,
        onRouteSelected: callback,
      );
    }

    return null;
  }

  static Map<String, WidgetBuilder> routes = {
    dashboard: (context) => DashboardScreen(onRouteSelected: (r) {}),
    invoices: (context) => InvoiceScreen(onRouteSelected: (r) {}),
    products: (context) => ProductScreen(onRouteSelected: (r) {}),
    createProduct: (context) => CreateProductScreen(onRouteSelected: (r) {}),
    lowStocks: (context) => LowStocksScreen(onRouteSelected: (r) {}),
    stocks: (context) => StockManagementScreen(onRouteSelected: (r) {}),
    stockHistory: (context) => StockHistoryScreen(onRouteSelected: (r) {}),
    categories: (context) => CategoryScreen(onRouteSelected: (r) {}),
    createCategory: (context) => CreateCategoryScreen(onRouteSelected: (r) {}),
    brands: (context) => BrandScreen(onRouteSelected: (r) {}),
    createBrand: (context) => CreateBrandScreen(onRouteSelected: (r) {}),
    suppliers: (context) => SupplierScreen(onRouteSelected: (r) {}),
    createSupplier: (context) => CreateSupplierScreen(onRouteSelected: (r) {}),
    customers: (context) => CustomerScreen(onRouteSelected: (r) {}),
    createCustomer: (context) => CreateCustomerScreen(onRouteSelected: (r) {}),
    purchases: (context) =>
        PurchaseListScreen(onRouteSelected: (r) {}, purchaseType: 'Purchase'),
    createPurchase: (context) =>
        CreatePurchaseScreen(onRouteSelected: (r) {}, purchaseType: 'Purchase'),
    purchaseOrders: (context) =>
        PurchaseListScreen(onRouteSelected: (r) {}, purchaseType: 'Order'),
    createPurchaseOrder: (context) =>
        CreatePurchaseScreen(onRouteSelected: (r) {}, purchaseType: 'Order'),
    purchaseReturns: (context) =>
        PurchaseListScreen(onRouteSelected: (r) {}, purchaseType: 'Return'),
    createPurchaseReturn: (context) =>
        CreatePurchaseScreen(onRouteSelected: (r) {}, purchaseType: 'Return'),
    rooms: (context) => RoomScreen(onRouteSelected: (r) {}),
    createRoom: (context) => CreateRoomScreen(onRouteSelected: (r) {}),
    platformSettings: (context) =>
        PlatformSettingsScreen(onRouteSelected: (r) {}),
    userManagement: (context) => UserManagementScreen(onRouteSelected: (r) {}),
    purchaseReport: (context) => PurchaseReportScreen(onRouteSelected: (r) {}),
    salesReport: (context) => SalesReportScreen(onRouteSelected: (r) {}),
    salesHistory: (context) => SalesHistoryScreen(onRouteSelected: (r) {}),
    pos: (context) => const POSWindow(),
  };
}
