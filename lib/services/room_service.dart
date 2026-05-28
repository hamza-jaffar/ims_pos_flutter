import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/room.dart';

class RoomService {
  RoomService._();
  static final RoomService instance = RoomService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.roomTable;

  Future<String> generateCode() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT code FROM $_table WHERE code LIKE 'ROM-%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'ROM-001';
    final lastCode = result.first['code'] as String;
    final numPart = int.tryParse(lastCode.replaceFirst('ROM-', '')) ?? 0;
    return 'ROM-${(numPart + 1).toString().padLeft(3, '0')}';
  }

  Future<int> create(Room room) async {
    final db = await _db.database;
    final code = await generateCode();
    final map = room.toMap()..remove('id');
    map['code'] = code;
    return await db.insert(_table, map);
  }

  Future<List<Room>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(_table, orderBy: 'created_at DESC');
    return maps.map((m) => Room.fromMap(m)).toList();
  }

  Future<Room?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Room.fromMap(maps.first);
  }

  Future<List<Room>> search(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'name LIKE ? OR code LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Room.fromMap(m)).toList();
  }

  Future<int> update(Room room) async {
    final db = await _db.database;
    return await db.update(
      _table,
      room.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [room.id],
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

  Future<List<Room>> getActiveRooms() async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Room.fromMap(m)).toList();
  }
}
