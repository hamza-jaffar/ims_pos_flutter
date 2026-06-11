import 'package:sqflite/sqflite.dart';

class ProductTable {
  static const String tableName = 'products';

  static const String createTableSql =
      '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      code TEXT NOT NULL UNIQUE,
      barcode TEXT,
      brand_id INTEGER,
      category_id INTEGER,
      supplier_id INTEGER,
      room_id INTEGER,
      model_id INTEGER,
      quality_id INTEGER,
      quality TEXT,
      location TEXT,
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
      FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
      FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE SET NULL
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
        room_id INTEGER,
        model_id INTEGER,
        quality_id INTEGER,
        quality TEXT,
        location TEXT,
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
        FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
        FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE SET NULL
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

  /// Runs migration for v8 → v9: adds room_id column if missing.
  static Future<void> migrateV9(Database db) async {
    final info = await db.rawQuery("PRAGMA table_info($tableName)");
    final columns = info.map((c) => c['name'] as String).toList();
    if (!columns.contains('room_id')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN room_id INTEGER');
    }
  }

  /// Runs migration for v14 → v15: adds model_id column if missing.
  static Future<void> migrateV15(Database db) async {
    final info = await db.rawQuery("PRAGMA table_info($tableName)");
    final columns = info.map((c) => c['name'] as String).toList();
    if (!columns.contains('model_id')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN model_id INTEGER');
    }
  }

  /// Runs migration for v15 → v16: adds quality and location columns if missing.
  static Future<void> migrateV16(Database db) async {
    final info = await db.rawQuery("PRAGMA table_info($tableName)");
    final columns = info.map((c) => c['name'] as String).toList();
    if (!columns.contains('quality')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN quality TEXT');
    }
    if (!columns.contains('location')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN location TEXT');
    }
  }

  /// Runs migration for v16 → v17: adds quality_id column if missing.
  static Future<void> migrateV17(Database db) async {
    final info = await db.rawQuery("PRAGMA table_info($tableName)");
    final columns = info.map((c) => c['name'] as String).toList();
    if (!columns.contains('quality_id')) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN quality_id INTEGER');
    }
  }
}
