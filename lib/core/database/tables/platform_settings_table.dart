import 'package:sqflite/sqflite.dart';
import 'package:ims_pos_system/models/platform_settings.dart';

class PlatformSettingsTable {
  static const String tableName = 'platform_settings';

  static const String createTableSql = '''
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY,
      platform_name TEXT NOT NULL,
      currency_code TEXT NOT NULL,
      currency_symbol TEXT NOT NULL,
      contact_email TEXT,
      contact_phone TEXT,
      address TEXT,
      logo_path TEXT,
      tax_rate REAL NOT NULL DEFAULT 0.0,
      tax_name TEXT NOT NULL DEFAULT 'VAT',
      invoice_prefix TEXT NOT NULL DEFAULT 'INV-',
      timezone TEXT NOT NULL DEFAULT 'UTC',
      date_format TEXT NOT NULL DEFAULT 'dd/MM/yyyy'
    )
  ''';

  static Future<void> createTable(Database db) async {
    await db.execute(createTableSql);
    await _seedDefaultSettings(db);
  }

  static Future<void> ensureTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        id INTEGER PRIMARY KEY,
        platform_name TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        contact_email TEXT,
        contact_phone TEXT,
        address TEXT,
        logo_path TEXT,
        tax_rate REAL NOT NULL DEFAULT 0.0,
        tax_name TEXT NOT NULL DEFAULT 'VAT',
        invoice_prefix TEXT NOT NULL DEFAULT 'INV-',
        timezone TEXT NOT NULL DEFAULT 'UTC',
        date_format TEXT NOT NULL DEFAULT 'dd/MM/yyyy'
      )
    ''');

    // Ensure the default settings row exists
    await _seedDefaultSettings(db);
  }

  /// Adds new columns for databases upgrading from v7 → v8
  static Future<void> migrateV8(Database db) async {
    // Ensure table exists first
    await ensureTable(db);

    final columns = [
      "ALTER TABLE $tableName ADD COLUMN logo_path TEXT",
      "ALTER TABLE $tableName ADD COLUMN tax_rate REAL NOT NULL DEFAULT 0.0",
      "ALTER TABLE $tableName ADD COLUMN tax_name TEXT NOT NULL DEFAULT 'VAT'",
      "ALTER TABLE $tableName ADD COLUMN invoice_prefix TEXT NOT NULL DEFAULT 'INV-'",
      "ALTER TABLE $tableName ADD COLUMN timezone TEXT NOT NULL DEFAULT 'UTC'",
      "ALTER TABLE $tableName ADD COLUMN date_format TEXT NOT NULL DEFAULT 'dd/MM/yyyy'",
    ];

    for (final sql in columns) {
      try {
        await db.execute(sql);
      } catch (_) {
        // Column may already exist – safe to ignore
      }
    }

    await _seedDefaultSettings(db);
  }

  static Future<void> _seedDefaultSettings(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableName WHERE id = 1'),
    );

    if (count == 0) {
      final defaultSettings = PlatformSettings(
        id: 1,
        platformName: 'IMS POS',
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
      await db.insert(tableName, defaultSettings.toMap());
    }
  }
}
