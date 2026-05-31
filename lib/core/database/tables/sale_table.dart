import 'package:sqflite/sqflite.dart';

class SaleTable {
  static const String tableName = 'sales';

  static const String createTableSql =
      '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      reference_no TEXT NOT NULL UNIQUE,
      supplier_id INTEGER,
      customer_id INTEGER,
      sale_date TEXT NOT NULL,
      purchase_date TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'Sale',
      status TEXT NOT NULL DEFAULT 'Completed', -- Completed, Pending
      payment_status TEXT NOT NULL DEFAULT 'Paid', -- Paid, Unpaid, Partial
      grand_total REAL NOT NULL DEFAULT 0.0,
      paid_amount REAL NOT NULL DEFAULT 0.0,
      due_amount REAL NOT NULL DEFAULT 0.0,
      payment_method TEXT,
      note TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
      FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE SET NULL
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
        customer_id INTEGER,
        sale_date TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'Sale',
        status TEXT NOT NULL DEFAULT 'Completed',
        payment_status TEXT NOT NULL DEFAULT 'Paid',
        grand_total REAL NOT NULL DEFAULT 0.0,
        paid_amount REAL NOT NULL DEFAULT 0.0,
        due_amount REAL NOT NULL DEFAULT 0.0,
        payment_method TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');
  }

  static Future<void> migrateV14(Database db) async {
    final columns = await db.rawQuery("PRAGMA table_info('$tableName')");
    final hasSupplierId = columns.any(
      (column) => column['name'] == 'supplier_id',
    );
    if (!hasSupplierId) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN supplier_id INTEGER');
    }

    final hasPurchaseDate = columns.any(
      (column) => column['name'] == 'purchase_date',
    );
    if (!hasPurchaseDate) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN purchase_date TEXT');
      final hasSaleDate = columns.any(
        (column) => column['name'] == 'sale_date',
      );
      if (hasSaleDate) {
        await db.execute(
          "UPDATE $tableName SET purchase_date = sale_date WHERE purchase_date IS NULL",
        );
      } else {
        await db.execute(
          "UPDATE $tableName SET purchase_date = created_at WHERE purchase_date IS NULL",
        );
      }
    }

    final hasSaleDate = columns.any((column) => column['name'] == 'sale_date');
    if (!hasSaleDate) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN sale_date TEXT');
      await db.execute(
        "UPDATE $tableName SET sale_date = purchase_date WHERE sale_date IS NULL",
      );
    }

    final hasType = columns.any((column) => column['name'] == 'type');
    if (!hasType) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN type TEXT NOT NULL DEFAULT \'Sale\'',
      );
    }
  }
}
