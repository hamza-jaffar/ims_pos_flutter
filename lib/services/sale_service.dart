import 'package:flutter/foundation.dart';
import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:ims_pos_system/models/purchase_item.dart';
import 'package:ims_pos_system/models/product.dart';
import 'package:ims_pos_system/models/supplier.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';

class SaleService {
  SaleService._();
  static final SaleService instance = SaleService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.saleTable;
  static const String _itemTable = DatabaseHelper.saleItemTable;

  Future<List<Purchase>> getAll({int limit = 50}) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '''
      SELECT s.*
      FROM $_table s
      ORDER BY s.created_at DESC
      LIMIT ?
    ''',
      [limit],
    );

    return maps.map((m) => Purchase.fromMap(m)).toList();
  }

  Future<Purchase?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '''
      SELECT s.*
      FROM $_table s
      WHERE s.id = ?
    ''',
      [id],
    );

    if (maps.isEmpty) {
      return null;
    }
    final saleMap = maps.first;

    final itemMaps = await db.rawQuery(
      '''
      SELECT i.*, p.name as product_name, p.code as product_code,
             p.quantity as current_qty
      FROM $_itemTable i
      JOIN ${DatabaseHelper.productTable} p ON i.product_id = p.id
      WHERE i.sale_id = ?
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

    return Purchase.fromMap(saleMap, items: items);
  }

  Future<Purchase?> getByReference(String referenceNo) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '''
      SELECT s.*
      FROM $_table s
      WHERE s.reference_no = ?
    ''',
      [referenceNo],
    );

    if (maps.isEmpty) {
      return null;
    }
    final saleMap = maps.first;
    final id = saleMap['id'] as int;

    final itemMaps = await db.rawQuery(
      '''
      SELECT i.*, p.name as product_name, p.code as product_code,
             p.quantity as current_qty
      FROM $_itemTable i
      JOIN ${DatabaseHelper.productTable} p ON i.product_id = p.id
      WHERE i.sale_id = ?
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

    return Purchase.fromMap(saleMap, items: items);
  }

  Future<String> _generateReferenceInTxn(dynamic txn) async {
    final result = await txn.rawQuery(
      "SELECT reference_no FROM $_table WHERE reference_no LIKE 'SAL-%' ORDER BY id DESC LIMIT 1",
    );
    if (result.isEmpty) return 'SAL-0001';
    final lastRef = result.first['reference_no'] as String;
    final numPart = int.tryParse(lastRef.replaceFirst('SAL-', '')) ?? 0;
    return 'SAL-${(numPart + 1).toString().padLeft(4, '0')}';
  }

  Future<int> create(Purchase sale) async {
    final db = await _db.database;
    return await db.transaction((txn) async {
      final map = sale.toMap()..remove('id');
      if (map['reference_no'] == null || map['reference_no'].isEmpty) {
        map['reference_no'] = 'TMP-${DateTime.now().millisecondsSinceEpoch}';
      }
      if (map['sale_date'] == null || map['sale_date'].isEmpty) {
        map['sale_date'] = map['purchase_date'];
      }
      final saleId = await txn.insert(_table, map);
      final ref = await _generateReferenceInTxn(txn);
      await txn.update(
        _table,
        {'reference_no': ref},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      for (var item in sale.items) {
        final itemMap = item.toMap()..remove('id');
        itemMap.remove('purchase_id');
        itemMap['sale_id'] = saleId;

        // Capture cost price (purchase price) snapshot for this sale item
        final prodMaps = await txn.query(
          DatabaseHelper.productTable,
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        final costPrice = prodMaps.isNotEmpty
            ? ((prodMaps.first['purchase_price'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        itemMap['cost_price'] = costPrice;

        await txn.insert(_itemTable, itemMap);

        // Determine stock adjustment based on sale type and status
        if (sale.type == 'Sale' && sale.status == 'Completed') {
          final allowNegative = PlatformSettingsService
              .instance.settings.continueSellingWhenStockEmpty;

          if (allowNegative) {
            // Toggle ON: allow selling below zero — just deduct unconditionally
            final rowsAffected = await txn.rawUpdate(
              'UPDATE ${DatabaseHelper.productTable} SET quantity = quantity - ? WHERE id = ?',
              [item.quantity, item.productId],
            );
            if (rowsAffected == 0) {
              throw Exception('Product not found for ID: ${item.productId}');
            }
          } else {
            // Toggle OFF: enforce stock guard at DB level
            final rowsAffected = await txn.rawUpdate(
              'UPDATE ${DatabaseHelper.productTable} SET quantity = quantity - ? WHERE id = ? AND quantity >= ?',
              [item.quantity, item.productId, item.quantity],
            );
            if (rowsAffected == 0) {
              throw Exception('Insufficient stock or product not found for product ID: ${item.productId}');
            }
          }
        } else if (sale.type == 'SaleReturn' && sale.status == 'Completed') {
          // Return: increase stock back
          await txn.rawUpdate(
            'UPDATE ${DatabaseHelper.productTable} SET quantity = quantity + ? WHERE id = ?',
            [item.quantity, item.productId],
          );
        }
      }

      // If this is a SaleReturn linked to an original sale, update the original
      // sale's line items and totals to reflect the returned units
      if (sale.type == 'SaleReturn' && sale.status == 'Completed') {
        try {
          final note = sale.note ?? '';
          // Extract original sale reference from note (format: "... for SAL-XXXX")
          final match = RegExp(r'for\s+([\w\-]+)').firstMatch(note);

          if (match != null) {
            final originalRef = match.group(1);
            if (originalRef != null && originalRef.isNotEmpty) {
              // Find the original sale by reference (must be type='Sale')
              final origMaps = await txn.query(
                _table,
                where: 'reference_no = ? AND type = ?',
                whereArgs: [originalRef, 'Sale'],
              );

              if (origMaps.isNotEmpty) {
                final orig = origMaps.first;
                final origId = orig['id'] as int;

                // Update each returned item in the original sale
                for (var returnItem in sale.items) {
                  final origItems = await txn.query(
                    _itemTable,
                    where: 'sale_id = ? AND product_id = ?',
                    whereArgs: [origId, returnItem.productId],
                  );

                  if (origItems.isEmpty) {
                    // Item not found in original sale, skip
                    continue;
                  }

                  final origItemRow = origItems.first;
                  final origQty = (origItemRow['quantity'] as num).toInt();
                  final returnedQty = returnItem.quantity;
                  final remainingQty = origQty - returnedQty;
                  final unitPrice = (origItemRow['unit_cost'] as num)
                      .toDouble();

                  if (remainingQty <= 0) {
                    // All units returned — update return_qty then delete
                    await txn.rawUpdate(
                      'UPDATE $_itemTable SET return_qty = return_qty + ? WHERE id = ?',
                      [returnedQty, origItemRow['id']],
                    );
                    await txn.delete(
                      _itemTable,
                      where: 'id = ?',
                      whereArgs: [origItemRow['id']],
                    );
                  } else {
                    // Partial return — update quantity, subtotal, and return_qty
                    final newSubtotal = remainingQty * unitPrice;
                    await txn.update(
                      _itemTable,
                      {
                        'quantity': remainingQty,
                        'subtotal': newSubtotal,
                        'return_qty': (origItemRow['return_qty'] as num? ?? 0).toInt() + returnedQty,
                      },
                      where: 'id = ?',
                      whereArgs: [origItemRow['id']],
                    );
                  }
                }

                // Recalculate grand total from all remaining items
                final remainingItems = await txn.query(
                  _itemTable,
                  where: 'sale_id = ?',
                  whereArgs: [origId],
                );

                double newGrandTotal = 0.0;
                for (var item in remainingItems) {
                  final subtotal =
                      (item['subtotal'] as num?)?.toDouble() ?? 0.0;
                  newGrandTotal += subtotal;
                }

                // Update the original sale's grand total
                await txn.update(
                  _table,
                  {
                    'grand_total': newGrandTotal,
                    'updated_at': DateTime.now().toIso8601String(),
                  },
                  where: 'id = ?',
                  whereArgs: [origId],
                );
              }
            }
          }
        } catch (e, stackTrace) {
          // Log error for debugging but don't fail the transaction
          print('Error updating original sale on return: $e\n$stackTrace');
        }
      }

      return saleId;
    });
  }

  Future<List<Purchase>> getAllSalesHistory({
    String filterType = 'All',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db.database;
    final results = <Purchase>[];

    String dateWhere = '';
    List<dynamic> dateArgs = [];
    if (startDate != null && endDate != null) {
      dateWhere = ' AND s.purchase_date BETWEEN ? AND ?';
      dateArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      dateWhere = ' AND s.purchase_date >= ?';
      dateArgs = [startDate.toIso8601String()];
    } else if (endDate != null) {
      dateWhere = ' AND s.purchase_date <= ?';
      dateArgs = [endDate.toIso8601String()];
    }

    // Query sales table (new)
    if (filterType == 'Sale' || filterType == 'All') {
      final saleMaps = await db.rawQuery(
        '''
        SELECT s.*, sup.name as supplier_name
        FROM $_table s
        LEFT JOIN ${DatabaseHelper.supplierTable} sup ON s.supplier_id = sup.id
        WHERE s.type = ?$dateWhere
        ORDER BY s.created_at DESC
      ''',
        ['Sale', ...dateArgs],
      );
      results.addAll(
        saleMaps.map((m) {
          Supplier? supplier;
          if (m['supplier_id'] != null) {
            supplier = Supplier(
              id: m['supplier_id'] as int,
              name: m['supplier_name'] as String? ?? 'Unknown',
            );
          }
          return Purchase.fromMap(m, supplier: supplier);
        }).toList(),
      );
    }

    if (filterType == 'SaleReturn' || filterType == 'All') {
      final returnMaps = await db.rawQuery(
        '''
        SELECT s.*, sup.name as supplier_name
        FROM $_table s
        LEFT JOIN ${DatabaseHelper.supplierTable} sup ON s.supplier_id = sup.id
        WHERE s.type = ?$dateWhere
        ORDER BY s.created_at DESC
      ''',
        ['SaleReturn', ...dateArgs],
      );
      results.addAll(
        returnMaps.map((m) {
          Supplier? supplier;
          if (m['supplier_id'] != null) {
            supplier = Supplier(
              id: m['supplier_id'] as int,
              name: m['supplier_name'] as String? ?? 'Unknown',
            );
          }
          return Purchase.fromMap(m, supplier: supplier);
        }).toList(),
      );
    }

    // Also query purchase table for legacy sales data
    debugPrint('📊 Querying purchase table for legacy sales...');
    try {
      String pDateWhere = dateWhere.replaceAll('s.purchase_date', 'p.purchase_date');
      if (filterType == 'Sale' || filterType == 'All') {
        final legacySaleMaps = await db.rawQuery(
          '''
          SELECT p.*, s.name as supplier_name
          FROM ${DatabaseHelper.purchaseTable} p
          LEFT JOIN ${DatabaseHelper.supplierTable} s ON p.supplier_id = s.id
          WHERE p.type = ?$pDateWhere
          ORDER BY p.created_at DESC
        ''',
          ['Sale', ...dateArgs],
        );
        debugPrint('   Found ${legacySaleMaps.length} legacy sales');
        results.addAll(
          legacySaleMaps.map((m) {
            Supplier? supplier;
            if (m['supplier_id'] != null) {
              supplier = Supplier(
                id: m['supplier_id'] as int,
                name: m['supplier_name'] as String? ?? 'Unknown',
              );
            }
            return Purchase.fromMap(m, supplier: supplier);
          }).toList(),
        );
      }

      if (filterType == 'SaleReturn' || filterType == 'All') {
        final legacyReturnMaps = await db.rawQuery(
          '''
          SELECT p.*, s.name as supplier_name
          FROM ${DatabaseHelper.purchaseTable} p
          LEFT JOIN ${DatabaseHelper.supplierTable} s ON p.supplier_id = s.id
          WHERE p.type = ?$pDateWhere
          ORDER BY p.created_at DESC
        ''',
          ['SaleReturn', ...dateArgs],
        );
        debugPrint('   Found ${legacyReturnMaps.length} legacy returns');
        results.addAll(
          legacyReturnMaps.map((m) {
            Supplier? supplier;
            if (m['supplier_id'] != null) {
              supplier = Supplier(
                id: m['supplier_id'] as int,
                name: m['supplier_name'] as String? ?? 'Unknown',
              );
            }
            return Purchase.fromMap(m, supplier: supplier);
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error querying purchase table: $e');
    }

    final uniq = <String, Purchase>{};
    for (final purchase in results) {
      uniq[purchase.referenceNo] ??= purchase;
    }

    final merged = uniq.values.toList();
    merged.sort(
      (a, b) => b.createdAt!.compareTo(
        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    debugPrint('✅ Total unique sales: ${merged.length}');
    return merged;
  }

  Future<List<Purchase>> getPaginatedSalesHistory({
    String filterType = 'All',
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    // For now we use the existing merged logic and paginate in memory
    // because sales data is currently split across legacy and new tables.
    final allSales = await getAllSalesHistory(filterType: filterType);
    
    Iterable<Purchase> filtered = allSales;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      filtered = allSales.where((s) {
        return (s.referenceNo.toLowerCase().contains(q)) ||
               (s.supplier?.name.toLowerCase().contains(q) ?? false) ||
               (s.note?.toLowerCase().contains(q) ?? false);
      });
    }

    return filtered.skip(offset).take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals({int months = 6}) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      '''
      SELECT strftime('%Y-%m', sale_date) as period, SUM(grand_total) as total
      FROM $_table
      WHERE type = 'Sale'
      GROUP BY period
      ORDER BY period DESC
      LIMIT ?
    ''',
      [months],
    );
    return maps;
  }
}
