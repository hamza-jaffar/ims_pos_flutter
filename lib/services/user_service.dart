import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/user.dart';

class UserService {
  UserService._privateConstructor();
  static final UserService instance = UserService._privateConstructor();

  final _db = DatabaseHelper.instance;

  /// Returns all users ordered by name
  Future<List<User>> getAllUsers() async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.userTable,
      orderBy: 'name ASC',
    );
    return maps.map(User.fromMap).toList();
  }

  /// Creates a new user. Throws if email already exists.
  Future<int> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await _db.database;
    final user = User(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: User.hashPassword(password),
    );
    return await db.insert(DatabaseHelper.userTable, user.toMap());
  }

  /// Updates an existing user's name and/or email.
  Future<void> updateUser(User user) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.userTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Resets a user's password.
  Future<void> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    final db = await _db.database;
    await db.update(
      DatabaseHelper.userTable,
      {'password': User.hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Deletes a user by id. Throws if trying to delete id = 1 (default admin).
  Future<void> deleteUser(int id) async {
    if (id == 1) {
      throw Exception('The default admin account cannot be deleted.');
    }
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Checks if an email is already taken (excluding a given userId for edits)
  Future<bool> emailExists(String email, {int? excludeId}) async {
    final db = await _db.database;
    final maps = await db.query(
      DatabaseHelper.userTable,
      where: excludeId != null ? 'email = ? AND id != ?' : 'email = ?',
      whereArgs:
          excludeId != null ? [email.trim().toLowerCase(), excludeId] : [email.trim().toLowerCase()],
    );
    return maps.isNotEmpty;
  }
}
