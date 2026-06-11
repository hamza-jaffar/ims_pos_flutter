import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/quality.dart';

class QualityService {
  QualityService._();
  static final QualityService instance = QualityService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.qualityTable;

  Future<String> generateCode() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT code FROM $_table WHERE code LIKE 'QTY-%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'QTY-001';
    final lastCode = result.first['code'] as String;
    final numPart = int.tryParse(lastCode.replaceFirst('QTY-', '')) ?? 0;
    return 'QTY-${(numPart + 1).toString().padLeft(3, '0')}';
  }

  Future<int> create(Quality quality) async {
    final db = await _db.database;
    final code = await generateCode();
    final map = quality.toMap()..remove('id');
    map['code'] = code;
    return await db.insert(_table, map);
  }

  Future<List<Quality>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(_table, orderBy: 'name ASC');
    return maps.map((m) => Quality.fromMap(m)).toList();
  }

  Future<List<Quality>> getActive() async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Quality.fromMap(m)).toList();
  }

  Future<Quality?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Quality.fromMap(maps.first);
  }

  Future<int> update(Quality quality) async {
    final db = await _db.database;
    final map = quality.toMap()..remove('id');
    map['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [quality.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
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
