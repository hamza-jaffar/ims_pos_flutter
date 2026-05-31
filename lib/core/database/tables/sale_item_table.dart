import 'package:sqflite/sqflite.dart';

class SaleItemTable {
  static const String tableName = 'sale_items';

  static const String createTableSql =
      '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      unit_cost REAL NOT NULL DEFAULT 0.0,
      cost_price REAL NOT NULL DEFAULT 0.0,
      subtotal REAL NOT NULL DEFAULT 0.0,
      FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE,
      FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
    )
  ''';

  static Future<void> createTable(Database db) async {
    await db.execute(createTableSql);
  }

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_cost REAL NOT NULL DEFAULT 0.0,
        cost_price REAL NOT NULL DEFAULT 0.0,
        subtotal REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY(sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');

    // Migration: add cost_price column if missing
    final columns = await db.rawQuery("PRAGMA table_info('$tableName')");
    final hasCost = columns.any((c) => c['name'] == 'cost_price');
    if (!hasCost) {
      await db.execute(
        "ALTER TABLE $tableName ADD COLUMN cost_price REAL NOT NULL DEFAULT 0.0",
      );
    }
  }
}
