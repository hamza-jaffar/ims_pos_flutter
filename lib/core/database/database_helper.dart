import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ims_pos_system/core/database/tables/brand_table.dart';
import 'package:ims_pos_system/core/database/tables/category_table.dart';
import 'package:ims_pos_system/core/database/tables/product_table.dart';
import 'package:ims_pos_system/core/database/tables/room_table.dart';
import 'package:ims_pos_system/core/database/tables/stock_adjustment_table.dart';
import 'package:ims_pos_system/core/database/tables/user_table.dart';
import 'package:ims_pos_system/core/database/tables/customer_table.dart';
import 'package:ims_pos_system/core/database/tables/supplier_table.dart';
import 'package:ims_pos_system/core/database/tables/purchase_table.dart';
import 'package:ims_pos_system/core/database/tables/purchase_item_table.dart';
import 'package:ims_pos_system/core/database/tables/sale_table.dart';
import 'package:ims_pos_system/core/database/tables/sale_item_table.dart';
import 'package:ims_pos_system/core/database/tables/platform_settings_table.dart';
import 'package:ims_pos_system/models/user.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static const String _databaseName = 'ims_pos_system.db';
  static const int _databaseVersion = 14;

  static const String userTable = UserTable.tableName;
  static const String categoryTable = CategoryTable.tableName;
  static const String brandTable = BrandTable.tableName;
  static const String supplierTable = SupplierTable.tableName;
  static const String productTable = ProductTable.tableName;
  static const String roomTable = RoomTable.tableName;
  static const String stockAdjustmentsTable = StockAdjustmentTable.tableName;
  static const String platformSettingsTable = PlatformSettingsTable.tableName;
  static const String customerTable = CustomerTable.tableName;
  static const String purchaseTable = PurchaseTable.tableName;
  static const String purchaseItemTable = PurchaseItemTable.tableName;
  static const String saleTable = SaleTable.tableName;
  static const String saleItemTable = SaleItemTable.tableName;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _createDb,
          onUpgrade: _onUpgrade,
          onOpen: (db) async {
            await _ensureTables(db);
          },
        ),
      );
      await _ensureTables(db);
      return db;
    }

    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureTables(db);
      },
    );

    await _ensureTables(db);
    return db;
  }

  Future<void> _createDb(Database db, int version) async {
    await UserTable.createTable(db);
    await CategoryTable.createTable(db);
    await BrandTable.createTable(db);
    await SupplierTable.createTable(db);
    await RoomTable.createTable(db);
    await ProductTable.createTable(db);
    await StockAdjustmentTable.createTable(db);
    await PlatformSettingsTable.createTable(db);
    await CustomerTable.createTable(db);
    await PurchaseTable.createTable(db);
    await PurchaseItemTable.createTable(db);
    await SaleTable.createTable(db);
    await SaleItemTable.createTable(db);
    await _ensureDefaultAdmin(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await CategoryTable.ensureTable(db);
    }
    if (oldVersion < 3) {
      await BrandTable.ensureTable(db);
    }
    if (oldVersion < 4) {
      await SupplierTable.ensureTable(db);
    }
    if (oldVersion < 5) {
      await ProductTable.ensureTable(db);
    }
    if (oldVersion < 6) {
      await ProductTable.migrateV6(db);
    }
    if (oldVersion < 7) {
      await PlatformSettingsTable.ensureTable(db);
    }
    if (oldVersion < 8) {
      await PlatformSettingsTable.migrateV8(db);
    }
    if (oldVersion < 9) {
      await RoomTable.ensureTable(db);
      await ProductTable.migrateV9(db);
    }
    if (oldVersion < 10) {
      await CustomerTable.ensureTable(db);
    }
    if (oldVersion < 11) {
      await PurchaseTable.ensureTable(db);
      await PurchaseItemTable.ensureTable(db);
      await SaleTable.ensureTable(db);
      await SaleItemTable.ensureTable(db);
    }
    if (oldVersion < 12) {
      await PurchaseTable.migrateV12(db);
    }
    if (oldVersion < 13) {
      await PurchaseTable.migrateV13(db);
    }
    if (oldVersion < 14) {
      await SaleTable.migrateV14(db);
    }
  }

  Future<void> _ensureDefaultAdmin(Database db) async {
    const defaultEmail = 'admin@example.com';
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $userTable WHERE email = ?', [
        defaultEmail,
      ]),
    );

    if (count == 0) {
      final adminUser = User(
        name: 'Administrator',
        email: defaultEmail,
        password: User.hashPassword('password123'),
      );
      await db.insert(userTable, adminUser.toMap());
    }
  }

  Future<void> _ensureTables(Database db) async {
    await CategoryTable.ensureTable(db);
    await BrandTable.ensureTable(db);
    await SupplierTable.ensureTable(db);
    await RoomTable.ensureTable(db);
    await UserTable.ensureTable(db);
    await ProductTable.ensureTable(db);
    await StockAdjustmentTable.ensureTable(db);
    await PlatformSettingsTable.ensureTable(db);
    await CustomerTable.ensureTable(db);
    await PurchaseTable.ensureTable(db);
    await PurchaseItemTable.ensureTable(db);
    await SaleTable.ensureTable(db);
    await SaleTable.migrateV14(db);
    await SaleItemTable.ensureTable(db);
    await _ensureDefaultAdmin(db);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      userTable,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(userTable, user.toMap());
  }
}
