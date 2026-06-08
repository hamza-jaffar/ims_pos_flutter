import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/models/purchase_item.dart';
import 'package:ims_pos_system/models/supplier.dart';
import 'package:ims_pos_system/models/product.dart';

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.purchaseTable;
  static const String _itemTable = DatabaseHelper.purchaseItemTable;
  static const String _supplierTable = DatabaseHelper.supplierTable;
  static const String _productTable = DatabaseHelper.productTable;

  Future<String> generateReference(String type) async {
    final db = await _db.database;
    String prefix = 'PUR';
    if (type == 'Order') prefix = 'PO';
    if (type == 'Return') prefix = 'PR';
    if (type == 'Sale') prefix = 'SAL';
    if (type == 'SaleReturn') prefix = 'SRN';

    final result = await db.rawQuery(
      "SELECT reference_no FROM $_table WHERE reference_no LIKE '$prefix-%' ORDER BY reference_no DESC LIMIT 1",
    );
    if (result.isEmpty) return '$prefix-0001';
    final lastRef = result.first['reference_no'] as String;
    final numPart = int.tryParse(lastRef.replaceFirst('$prefix-', '')) ?? 0;
    return '$prefix-${(numPart + 1).toString().padLeft(4, '0')}';
  }

  Future<int> create(Purchase purchase) async {
    final db = await _db.database;

    return await db.transaction((txn) async {
      final map = purchase.toMap()..remove('id');
      if (map['reference_no'] == null || map['reference_no'].isEmpty) {
        map['reference_no'] =
            'TMP-${DateTime.now().millisecondsSinceEpoch}'; // Will replace immediately
      }

      final purchaseId = await txn.insert(_table, map);

      // Now set actual reference
      final ref = await _generateReferenceInTxn(txn, purchase.type);
      await txn.update(
        _table,
        {'reference_no': ref},
        where: 'id = ?',
        whereArgs: [purchaseId],
      );

      for (var item in purchase.items) {
        final itemMap = item.toMap()..remove('id');
        itemMap['purchase_id'] = purchaseId;
        await txn.insert(_itemTable, itemMap);

        if (purchase.type == 'Purchase' && purchase.status == 'Received') {
          await txn.rawUpdate(
            'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
            [item.quantity, item.productId],
          );
        } else if (purchase.type == 'Return' && purchase.status == 'Returned') {
          final rows = await txn.rawUpdate(
            'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
            [item.quantity, item.productId, item.quantity],
          );
          if (rows == 0) throw Exception('Insufficient stock for product ID: ${item.productId}');
        } else if (purchase.type == 'Sale' && purchase.status == 'Completed') {
          final rows = await txn.rawUpdate(
            'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
            [item.quantity, item.productId, item.quantity],
          );
          if (rows == 0) throw Exception('Insufficient stock for product ID: ${item.productId}');
        } else if (purchase.type == 'SaleReturn' &&
            purchase.status == 'Completed') {
          await txn.rawUpdate(
            'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
            [item.quantity, item.productId],
          );
        }
      }

      return purchaseId;
    });
  }

  Future<String> _generateReferenceInTxn(dynamic txn, String type) async {
    String prefix = 'PUR';
    if (type == 'Order') prefix = 'PO';
    if (type == 'Return') prefix = 'PR';
    if (type == 'Sale') prefix = 'SAL';
    if (type == 'SaleReturn') prefix = 'SRN';

    final result = await txn.rawQuery(
      "SELECT reference_no FROM $_table WHERE reference_no LIKE '$prefix-%' ORDER BY id DESC LIMIT 1",
    );
    if (result.isEmpty) return '$prefix-0001';
    final lastRef = result.first['reference_no'] as String;
    final numPart = int.tryParse(lastRef.replaceFirst('$prefix-', '')) ?? 0;
    return '$prefix-${(numPart + 1).toString().padLeft(4, '0')}';
  }

  Future<List<Purchase>> getAllByType(String type) async {
    final db = await _db.database;

    final maps = await db.rawQuery(
      '''
      SELECT p.*, s.name as supplier_name 
      FROM $_table p 
      LEFT JOIN $_supplierTable s ON p.supplier_id = s.id 
      WHERE p.type = ? 
      ORDER BY p.created_at DESC
    ''',
      [type],
    );

    return maps.map((m) {
      Supplier? supplier;
      if (m['supplier_id'] != null) {
        supplier = Supplier(
          id: m['supplier_id'] as int,
          name: m['supplier_name'] as String? ?? 'Unknown',
        );
      }
      return Purchase.fromMap(m, supplier: supplier);
    }).toList();
  }

  Future<Purchase?> getById(int id) async {
    final db = await _db.database;

    final maps = await db.rawQuery(
      '''
      SELECT p.*, s.name as supplier_name 
      FROM $_table p 
      LEFT JOIN $_supplierTable s ON p.supplier_id = s.id 
      WHERE p.id = ?
    ''',
      [id],
    );

    if (maps.isEmpty) return null;

    final purchaseMap = maps.first;
    Supplier? supplier;
    if (purchaseMap['supplier_id'] != null) {
      supplier = Supplier(
        id: purchaseMap['supplier_id'] as int,
        name: purchaseMap['supplier_name'] as String? ?? 'Unknown',
      );
    }

    final itemMaps = await db.rawQuery(
      '''
      SELECT i.*, p.name as product_name, p.code as product_code,
             p.quantity as current_qty
      FROM $_itemTable i
      JOIN $_productTable p ON i.product_id = p.id
      WHERE i.purchase_id = ?
    ''',
      [id],
    );

    List<PurchaseItem> items = itemMaps.map((im) {
      final productWithPrice = Product(
        id: im['product_id'] as int,
        name: im['product_name'] as String? ?? 'Unknown',
        code: im['product_code'] as String? ?? '',
        sellingPrice: (im['unit_cost'] as num).toDouble(),
        quantity: (im['current_qty'] as num?)?.toInt() ?? 0,
      );
      return PurchaseItem.fromMap(im, product: productWithPrice);
    }).toList();

    return Purchase.fromMap(purchaseMap, supplier: supplier, items: items);
  }

  Future<Purchase?> getByReference(String referenceNo) async {
    final db = await _db.database;

    final maps = await db.rawQuery(
      '''
      SELECT p.*, s.name as supplier_name 
      FROM $_table p 
      LEFT JOIN $_supplierTable s ON p.supplier_id = s.id 
      WHERE p.reference_no = ?
    ''',
      [referenceNo],
    );

    if (maps.isEmpty) return null;

    final purchaseMap = maps.first;
    Supplier? supplier;
    if (purchaseMap['supplier_id'] != null) {
      supplier = Supplier(
        id: purchaseMap['supplier_id'] as int,
        name: purchaseMap['supplier_name'] as String? ?? 'Unknown',
      );
    }

    final id = purchaseMap['id'] as int;
    final itemMaps = await db.rawQuery(
      '''
      SELECT i.*, p.name as product_name, p.code as product_code,
             p.quantity as current_qty
      FROM $_itemTable i
      JOIN $_productTable p ON i.product_id = p.id
      WHERE i.purchase_id = ?
    ''',
      [id],
    );

    List<PurchaseItem> items = itemMaps.map((im) {
      final productWithPrice = Product(
        id: im['product_id'] as int,
        name: im['product_name'] as String? ?? 'Unknown',
        code: im['product_code'] as String? ?? '',
        sellingPrice: (im['unit_cost'] as num).toDouble(),
        quantity: (im['current_qty'] as num?)?.toInt() ?? 0,
      );
      return PurchaseItem.fromMap(im, product: productWithPrice);
    }).toList();

    return Purchase.fromMap(purchaseMap, supplier: supplier, items: items);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final maps = await txn.query(_table, where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        final p = Purchase.fromMap(maps.first);
        final items = await txn.query(
          _itemTable,
          where: 'purchase_id = ?',
          whereArgs: [id],
        );

        if (p.type == 'Purchase' && p.status == 'Received') {
          for (var item in items) {
            final rows = await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [item['quantity'], item['product_id'], item['quantity']],
            );
            if (rows == 0) throw Exception('Insufficient stock for product ID: ${item['product_id']}');
          }
        } else if (p.type == 'Return' && p.status == 'Returned') {
          for (var item in items) {
            await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          }
        } else if (p.type == 'Sale' && p.status == 'Completed') {
          for (var item in items) {
            await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          }
        } else if (p.type == 'SaleReturn' && p.status == 'Completed') {
          for (var item in items) {
            final rows = await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [item['quantity'], item['product_id'], item['quantity']],
            );
            if (rows == 0) throw Exception('Insufficient stock for product ID: ${item['product_id']}');
          }
        }
      }

      await txn.delete(_itemTable, where: 'purchase_id = ?', whereArgs: [id]);
      return await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> updateStatuses(
    int id, {
    String? status,
    String? paymentStatus,
    double? paidAmount,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final maps = await txn.query(_table, where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return;
      final oldPurchase = Purchase.fromMap(maps.first);

      final updatedStatus = status ?? oldPurchase.status;
      final updatedPaymentStatus = paymentStatus ?? oldPurchase.paymentStatus;
      double updatedPaidAmount = oldPurchase.paidAmount;
      double updatedDueAmount = oldPurchase.dueAmount;
      String finalPaymentStatus = updatedPaymentStatus;

      if (paymentStatus != null) {
        if (updatedPaymentStatus == 'Paid') {
          updatedPaidAmount = oldPurchase.grandTotal;
          updatedDueAmount = 0.0;
        } else if (updatedPaymentStatus == 'Unpaid') {
          updatedPaidAmount = 0.0;
          updatedDueAmount = oldPurchase.grandTotal;
        } else if (updatedPaymentStatus == 'Partial') {
          final amount = paidAmount ?? 0.0;
          if (oldPurchase.paymentStatus == 'Partial') {
            updatedPaidAmount = oldPurchase.paidAmount + amount;
          } else {
            updatedPaidAmount = amount;
          }
          if (updatedPaidAmount >= oldPurchase.grandTotal) {
            finalPaymentStatus = 'Paid';
            updatedPaidAmount = oldPurchase.grandTotal;
            updatedDueAmount = 0.0;
          } else {
            finalPaymentStatus = 'Partial';
            updatedDueAmount = oldPurchase.grandTotal - updatedPaidAmount;
          }
        }
      } else if (paidAmount != null && oldPurchase.paymentStatus == 'Partial') {
        updatedPaidAmount = oldPurchase.paidAmount + paidAmount;
        if (updatedPaidAmount >= oldPurchase.grandTotal) {
          finalPaymentStatus = 'Paid';
          updatedPaidAmount = oldPurchase.grandTotal;
          updatedDueAmount = 0.0;
        } else {
          finalPaymentStatus = 'Partial';
          updatedDueAmount = oldPurchase.grandTotal - updatedPaidAmount;
        }
      }

      // Stock adjustment for Purchase/Order
      if (oldPurchase.type == 'Purchase' || oldPurchase.type == 'Order') {
        if (oldPurchase.status != 'Received' && updatedStatus == 'Received') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          }
        } else if (oldPurchase.status == 'Received' &&
            updatedStatus != 'Received') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            final rows = await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [item['quantity'], item['product_id'], item['quantity']],
            );
            if (rows == 0) throw Exception('Insufficient stock for product ID: ${item['product_id']}');
          }
        }
      }
      // Stock adjustment for Return
      else if (oldPurchase.type == 'Return') {
        if (oldPurchase.status != 'Returned' && updatedStatus == 'Returned') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            final rows = await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [item['quantity'], item['product_id'], item['quantity']],
            );
            if (rows == 0) throw Exception('Insufficient stock for product ID: ${item['product_id']}');
          }
        } else if (oldPurchase.status == 'Returned' &&
            updatedStatus != 'Returned') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          }
        }
      }
      // Stock adjustment for Sale
      else if (oldPurchase.type == 'Sale') {
        if (oldPurchase.status != 'Completed' && updatedStatus == 'Completed') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            final rows = await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [item['quantity'], item['product_id'], item['quantity']],
            );
            if (rows == 0) throw Exception('Insufficient stock for product ID: ${item['product_id']}');
          }
        } else if (oldPurchase.status == 'Completed' &&
            updatedStatus != 'Completed') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          }
        }
      }
      // Stock adjustment for SaleReturn
      else if (oldPurchase.type == 'SaleReturn') {
        if (oldPurchase.status != 'Completed' && updatedStatus == 'Completed') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          }
        } else if (oldPurchase.status == 'Completed' &&
            updatedStatus != 'Completed') {
          final items = await txn.query(
            _itemTable,
            where: 'purchase_id = ?',
            whereArgs: [id],
          );
          for (var item in items) {
            final rows = await txn.rawUpdate(
              'UPDATE $_productTable SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [item['quantity'], item['product_id'], item['quantity']],
            );
            if (rows == 0) throw Exception('Insufficient stock for product ID: ${item['product_id']}');
          }
        }
      }

      // Update purchase statuses and payment totals
      await txn.update(
        _table,
        {
          'status': updatedStatus,
          'payment_status': finalPaymentStatus,
          'paid_amount': updatedPaidAmount,
          'due_amount': updatedDueAmount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
