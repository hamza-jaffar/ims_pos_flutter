import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:ims_pos_system/models/user.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static const String _databaseName = 'ims_pos_system.db';
  static const int _databaseVersion = 1;

  static const String userTable = 'users';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDb,
      onOpen: (db) async {
        await _ensureDefaultAdmin(db);
      },
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $userTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
    await _ensureDefaultAdmin(db);
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

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      userTable,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (maps.isEmpty) {
      return null;
    }
    return User.fromMap(maps.first);
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(userTable, user.toMap());
  }
}
