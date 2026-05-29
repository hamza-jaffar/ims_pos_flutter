import 'package:sqflite/sqflite.dart';

class PurchaseItemTable {
  static const String tableName = 'purchase_items';

  static const String createTableSql = '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      purchase_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      unit_cost REAL NOT NULL DEFAULT 0.0,
      subtotal REAL NOT NULL DEFAULT 0.0,
      FOREIGN KEY(purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
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
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_cost REAL NOT NULL DEFAULT 0.0,
        subtotal REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY(purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
  }
}
