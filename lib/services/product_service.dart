import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/product.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.productTable;

  Future<String> generateCode() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT code FROM $_table WHERE code LIKE 'PRD-%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'PRD-001';
    final lastCode = result.first['code'] as String;
    final numPart = int.tryParse(lastCode.replaceFirst('PRD-', '')) ?? 0;
    return 'PRD-${(numPart + 1).toString().padLeft(3, '0')}';
  }

  Future<int> create(Product product) async {
    final db = await _db.database;
    final code = await generateCode();
    final map = product.toMap()..remove('id');
    map['code'] = code;
    return await db.insert(_table, map);
  }

  Future<List<Product>> getAll() async {
    final db = await _db.database;
    const sql = '''
      SELECT p.*, 
             c.name AS category_name, 
             b.name AS brand_name, 
             s.name AS supplier_name,
             r.name AS room_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN rooms r ON p.room_id = r.id
      ORDER BY p.created_at DESC
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<Product?> getById(int id) async {
    final db = await _db.database;
    const sql = '''
      SELECT p.*, 
             c.name AS category_name, 
             b.name AS brand_name, 
             s.name AS supplier_name,
             r.name AS room_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN rooms r ON p.room_id = r.id
      WHERE p.id = ?
    ''';
    final maps = await db.rawQuery(sql, [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> search(String query) async {
    final db = await _db.database;
    const sql = '''
      SELECT p.*, 
             c.name AS category_name, 
             b.name AS brand_name, 
             s.name AS supplier_name,
             r.name AS room_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN rooms r ON p.room_id = r.id
      WHERE p.name LIKE ? 
         OR p.code LIKE ? 
         OR p.barcode LIKE ?
         OR c.name LIKE ? 
         OR b.name LIKE ? 
         OR s.name LIKE ?
         OR r.name LIKE ?
      ORDER BY p.created_at DESC
    ''';
    final searchVal = '%$query%';
    final maps = await db.rawQuery(sql, [
      searchVal,
      searchVal,
      searchVal,
      searchVal,
      searchVal,
      searchVal,
      searchVal,
    ]);
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> update(Product product) async {
    final db = await _db.database;
    final map = product.toMap()..remove('id');
    map['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> updateStock(int productId, int quantity) async {
    final db = await _db.database;
    return await db.update(
      _table,
      {'quantity': quantity, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
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

  Future<bool> codeExists(String code, {int? excludeId}) async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: excludeId != null ? 'code = ? AND id != ?' : 'code = ?',
      whereArgs: excludeId != null ? [code.trim(), excludeId] : [code.trim()],
    );
    return maps.isNotEmpty;
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await _db.database;
    const sql = '''
      SELECT p.*, 
             c.name AS category_name, 
             b.name AS brand_name, 
             s.name AS supplier_name,
             r.name AS room_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN rooms r ON p.room_id = r.id
      WHERE p.quantity <= p.min_stock_quantity
      ORDER BY p.quantity ASC
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<List<Product>> getActiveProducts() async {
    final db = await _db.database;
    const sql = '''
      SELECT p.*, 
             c.name AS category_name, 
             b.name AS brand_name, 
             s.name AS supplier_name,
             r.name AS room_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN brands b ON p.brand_id = b.id
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN rooms r ON p.room_id = r.id
      WHERE p.is_active = 1
      ORDER BY p.name ASC
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => Product.fromMap(m)).toList();
  }
}
