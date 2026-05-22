import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/brand.dart';

class BrandService {
  BrandService._();
  static final BrandService instance = BrandService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.brandTable;

  Future<int> create(Brand brand) async {
    final db = await _db.database;
    return await db.insert(_table, brand.toMap()..remove('id'));
  }

  Future<List<Brand>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(_table, orderBy: 'created_at DESC');
    return maps.map((m) => Brand.fromMap(m)).toList();
  }

  Future<Brand?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Brand.fromMap(maps.first);
  }

  Future<List<Brand>> search(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'name LIKE ? OR code LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Brand.fromMap(m)).toList();
  }

  Future<int> update(Brand brand) async {
    final db = await _db.database;
    return await db.update(
      _table,
      brand.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [brand.id],
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
