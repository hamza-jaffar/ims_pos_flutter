import 'package:sqflite/sqflite.dart';

class SupplierTable {
  static const String tableName = 'suppliers';

  static const String createTableSql =
      '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      code TEXT,
      email TEXT,
      phone TEXT,
      address TEXT,
      city TEXT,
      state TEXT,
      country TEXT,
      zip_code TEXT,
      contact_person TEXT,
      payment_terms TEXT,
      tax_id TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
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
        code TEXT,
        email TEXT,
        phone TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        country TEXT,
        zip_code TEXT,
        contact_person TEXT,
        payment_terms TEXT,
        tax_id TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }
}
