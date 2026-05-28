import 'package:sqflite/sqflite.dart';

class StockAdjustmentTable {
  static const String tableName = 'stock_adjustments';

  static const String createTableSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      old_quantity INTEGER NOT NULL,
      new_quantity INTEGER NOT NULL,
      adjustment_type TEXT NOT NULL,
      reason TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
    )
  ''';

  static Future<void> createTable(Database db) async {
    await db.execute(createTableSql);
  }

  static Future<void> ensureTable(Database db) async {
    await db.execute(createTableSql);
  }
}
