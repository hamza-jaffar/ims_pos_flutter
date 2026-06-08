import 'dart:math';
import 'package:ims_pos_system/core/database/database_helper.dart';

class DbSeederService {
  DbSeederService._privateConstructor();
  static final DbSeederService instance = DbSeederService._privateConstructor();

  final _random = Random();

  /// Generates a random alphanumeric barcode
  String _generateBarcode() {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return List.generate(10, (index) => chars[_random.nextInt(chars.length)])
        .join();
  }

  /// Seeds the database with thousands of products using batched transactions.
  Future<void> seedMassiveInventory({int count = 50000}) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure we have a default category and brand
    await db.insert(
      DatabaseHelper.categoryTable,
      {'name': 'Seeded Category', 'description': 'Auto-generated'},
    );
    final catMaps = await db.query(DatabaseHelper.categoryTable, limit: 1);
    final int categoryId = catMaps.first['id'] as int;

    await db.insert(
      DatabaseHelper.brandTable,
      {'name': 'Seeded Brand', 'description': 'Auto-generated'},
    );
    final brandMaps = await db.query(DatabaseHelper.brandTable, limit: 1);
    final int brandId = brandMaps.first['id'] as int;

    // We will use batches of 5000 inserts to avoid memory overflow
    final int batchSize = 5000;
    for (int i = 0; i < count; i += batchSize) {
      final batch = db.batch();
      final end = (i + batchSize < count) ? (i + batchSize) : count;

      for (int j = i; j < end; j++) {
        final barcode = _generateBarcode();
        batch.insert(DatabaseHelper.productTable, {
          'name': 'Stress Product $j',
          'code': 'SP-$j',
          'barcode': barcode,
          'category_id': categoryId,
          'brand_id': brandId,
          'purchase_price': (_random.nextDouble() * 50) + 5,
          'selling_price': (_random.nextDouble() * 100) + 15,
          'quantity': _random.nextInt(500) + 10,
          'min_stock_quantity': 5,
          'tax_type': 'Exclusive',
          'description': 'A product generated specifically for stress testing the database.',
        });
      }
      
      // Execute the batch without accumulating results to save memory
      await batch.commit(noResult: true);
    }
  }

  /// Seeds the database with thousands of sales (transactions).
  Future<void> seedMassiveTransactions({int count = 100000}) async {
    final db = await DatabaseHelper.instance.database;

    // Ensure we have a default customer
    await db.insert(
      DatabaseHelper.customerTable,
      {'name': 'Walk-in Customer', 'email': 'walkin@example.com', 'phone': '0000000000', 'address': 'Local'},
    );
    final cusMaps = await db.query(DatabaseHelper.customerTable, limit: 1);
    final int customerId = cusMaps.first['id'] as int;

    // Fetch up to 100 product IDs to link items to
    final prodMaps = await db.query(DatabaseHelper.productTable, columns: ['id', 'purchase_price', 'selling_price'], limit: 100);
    if (prodMaps.isEmpty) {
      throw Exception('Must seed products before seeding transactions.');
    }

    final int batchSize = 2500; // 1 sale + ~2 items = 3 operations per sale -> 7500 ops per batch
    for (int i = 0; i < count; i += batchSize) {
      final batch = db.batch();
      final end = (i + batchSize < count) ? (i + batchSize) : count;

      for (int j = i; j < end; j++) {
        final now = DateTime.now().subtract(Duration(minutes: j));
        
        // 1. Insert Sale
        batch.insert(DatabaseHelper.saleTable, {
          'reference_no': 'QA-SAL-${now.millisecondsSinceEpoch}-$j',
          'customer_id': customerId,
          'sale_date': now.toIso8601String(),
          'tax_rate': 0.0,
          'tax_amount': 0.0,
          'discount': 0.0,
          'shipping': 0.0,
          'grand_total': 150.0,
          'paid_amount': 150.0,
          'payment_status': 'Paid',
          'status': 'Completed',
          'payment_method': 'Cash',
          'note': 'Seeded QA transaction',
          'created_at': now.toIso8601String(),
          'type': 'Sale',
        });
        
        // Note: SQLite batch doesn't easily return the last inserted row ID in raw mode across loops unless executed.
        // For purely stress-testing the DB weight, we don't necessarily need perfect foreign keys, but to be clean,
        // we'll execute the batch for each sale IF we need the sale ID.
        // However, executing per sale is too slow for 100k. 
        // Instead, we will generate raw queries or just let them exist in the DB without line items for sheer row-count testing.
        // Actually, let's just insert sales. 
      }
      
      await batch.commit(noResult: true);
    }
  }

  /// Clear the database (Danger zone)
  Future<void> truncateAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('DELETE FROM ${DatabaseHelper.productTable}');
    await db.execute('DELETE FROM ${DatabaseHelper.saleTable}');
    await db.execute('DELETE FROM ${DatabaseHelper.purchaseTable}');
    await db.execute('DELETE FROM ${DatabaseHelper.saleItemTable}');
    await db.execute('DELETE FROM ${DatabaseHelper.purchaseItemTable}');
  }
}
