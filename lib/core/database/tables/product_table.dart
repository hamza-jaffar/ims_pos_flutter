import 'package:sqflite/sqflite.dart';

class ProductTable {
  static const String tableName = 'products';

  static const String createTableSql = '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      code TEXT NOT NULL UNIQUE,
      barcode TEXT,
      brand_id INTEGER,
      category_id INTEGER,
      supplier_id INTEGER,
      quantity INTEGER NOT NULL DEFAULT 0,
      min_stock_quantity INTEGER NOT NULL DEFAULT 5,
      purchase_price REAL NOT NULL DEFAULT 0.0,
      selling_price REAL NOT NULL DEFAULT 0.0,
      discount_price REAL,
      description TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY(brand_id) REFERENCES brands(id) ON DELETE SET NULL,
      FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
      FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
    )
  ''';

  static Future<void> createTable(Database db) async {
    await db.execute(createTableSql);
  }

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        barcode TEXT,
        brand_id INTEGER,
        category_id INTEGER,
        supplier_id INTEGER,
        quantity INTEGER NOT NULL DEFAULT 0,
        min_stock_quantity INTEGER NOT NULL DEFAULT 5,
        purchase_price REAL NOT NULL DEFAULT 0.0,
        selling_price REAL NOT NULL DEFAULT 0.0,
        discount_price REAL,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(brand_id) REFERENCES brands(id) ON DELETE SET NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
      )
    ''');
  }

  /// Runs migration for v5 → v6: adds barcode column if missing.
  static Future<void> migrateV6(Database db) async {
    final info = await db.rawQuery("PRAGMA table_info($tableName)");
    final columns = info.map((c) => c['name'] as String).toList();
    if (!columns.contains('barcode')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN barcode TEXT');
    }
  }
}
