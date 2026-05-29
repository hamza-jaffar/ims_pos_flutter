import 'package:sqflite/sqflite.dart';

class PurchaseTable {
  static const String tableName = 'purchases';

  static const String createTableSql = '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      reference_no TEXT NOT NULL UNIQUE,
      supplier_id INTEGER,
      purchase_date TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'Purchase', -- Purchase, Order, Return
      status TEXT NOT NULL DEFAULT 'Received', -- Received, Pending, Ordered, Returned
      payment_status TEXT NOT NULL DEFAULT 'Unpaid', -- Paid, Unpaid, Partial
      grand_total REAL NOT NULL DEFAULT 0.0,
      paid_amount REAL NOT NULL DEFAULT 0.0,
      due_amount REAL NOT NULL DEFAULT 0.0,
      payment_method TEXT,
      note TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
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
        reference_no TEXT NOT NULL UNIQUE,
        supplier_id INTEGER,
        purchase_date TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'Purchase',
        status TEXT NOT NULL DEFAULT 'Received',
        payment_status TEXT NOT NULL DEFAULT 'Unpaid',
        grand_total REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        due_amount REAL NOT NULL DEFAULT 0.0,
        payment_method TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
      )
    ''');
  }
}
