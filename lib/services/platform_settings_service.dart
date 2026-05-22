import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/platform_settings.dart';
import 'package:ims_pos_system/core/database/tables/platform_settings_table.dart';

class PlatformSettingsService {
  PlatformSettingsService._privateConstructor();
  static final PlatformSettingsService instance =
      PlatformSettingsService._privateConstructor();

  final _dbHelper = DatabaseHelper.instance;

  // Cached settings for synchronous access across the app
  PlatformSettings _settings = PlatformSettings(
    platformName: 'IMS POS',
    currencyCode: 'USD',
    currencySymbol: '\$',
    taxRate: 0.0,
    taxName: 'VAT',
    invoicePrefix: 'INV-',
    timezone: 'UTC',
    dateFormat: 'dd/MM/yyyy',
  );

  /// Synchronous access to settings
  PlatformSettings get settings => _settings;

  /// Loads the initial settings from the database (should be called at app startup)
  Future<void> init() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      PlatformSettingsTable.tableName,
      where: 'id = 1',
    );
    if (maps.isNotEmpty) {
      _settings = PlatformSettings.fromMap(maps.first);
    }
  }

  /// Updates the platform settings
  Future<void> updateSettings(PlatformSettings newSettings) async {
    final db = await _dbHelper.database;
    await db.update(
      PlatformSettingsTable.tableName,
      newSettings.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
    // Update cache
    _settings = newSettings;
  }
}
