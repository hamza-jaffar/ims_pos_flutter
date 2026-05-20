import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/category.dart';

class CategoryService {
  CategoryService._();
  static final CategoryService instance = CategoryService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.categoryTable;

  Future<int> create(Category category) async {
    final db = await _db.database;
    return await db.insert(_table, category.toMap()..remove('id'));
  }

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(_table, orderBy: 'created_at DESC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<List<Category>> search(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> update(Category category) async {
    final db = await _db.database;
    return await db.update(
      _table,
      category.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> nameExists(String name, {int? excludeId}) async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: excludeId != null ? 'name = ? AND id != ?' : 'name = ?',
      whereArgs: excludeId != null ? [name.trim(), excludeId] : [name.trim()],
    );
    return maps.isNotEmpty;
  }
}
