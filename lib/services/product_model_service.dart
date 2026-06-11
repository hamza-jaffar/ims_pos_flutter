import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/product_model.dart';

class ProductModelService {
  ProductModelService._();
  static final ProductModelService instance = ProductModelService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.productModelTable;
  static const String _brandTable = DatabaseHelper.brandTable;

  Future<String> generateCode() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT code FROM $_table WHERE code LIKE 'MDL-%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'MDL-001';
    final lastCode = result.first['code'] as String;
    final numPart = int.tryParse(lastCode.replaceFirst('MDL-', '')) ?? 0;
    return 'MDL-${(numPart + 1).toString().padLeft(3, '0')}';
  }

  Future<int> create(ProductModel model) async {
    final db = await _db.database;
    final code = await generateCode();
    final map = model.toMap()..remove('id')..remove('brand_name');
    map['code'] = code;
    return await db.insert(_table, map);
  }

  Future<List<ProductModel>> getAll() async {
    final db = await _db.database;
    final query = '''
      SELECT m.*, b.name AS brand_name 
      FROM $_table m
      LEFT JOIN $_brandTable b ON m.brand_id = b.id
      ORDER BY m.created_at DESC
    ''';
    final maps = await db.rawQuery(query);
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<ProductModel?> getById(int id) async {
    final db = await _db.database;
    final query = '''
      SELECT m.*, b.name AS brand_name 
      FROM $_table m
      LEFT JOIN $_brandTable b ON m.brand_id = b.id
      WHERE m.id = ?
    ''';
    final maps = await db.rawQuery(query, [id]);
    if (maps.isEmpty) return null;
    return ProductModel.fromMap(maps.first);
  }

  Future<List<ProductModel>> search(String query) async {
    final db = await _db.database;
    final sqlQuery = '''
      SELECT m.*, b.name AS brand_name 
      FROM $_table m
      LEFT JOIN $_brandTable b ON m.brand_id = b.id
      WHERE m.name LIKE ? OR m.code LIKE ?
      ORDER BY m.created_at DESC
    ''';
    final maps = await db.rawQuery(sqlQuery, ['%$query%', '%$query%']);
    return maps.map((m) => ProductModel.fromMap(m)).toList();
  }

  Future<int> update(ProductModel model) async {
    final db = await _db.database;
    return await db.update(
      _table,
      model.toMap()..remove('id')..remove('brand_name'),
      where: 'id = ?',
      whereArgs: [model.id],
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
