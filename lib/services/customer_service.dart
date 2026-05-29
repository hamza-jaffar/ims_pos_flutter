import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/models/customer.dart';

class CustomerService {
  CustomerService._();
  static final CustomerService instance = CustomerService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = DatabaseHelper.customerTable;

  Future<String> generateCode() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT code FROM $_table WHERE code LIKE 'CUST-%' ORDER BY code DESC LIMIT 1",
    );
    if (result.isEmpty) return 'CUST-001';
    final lastCode = result.first['code'] as String;
    final numPart = int.tryParse(lastCode.replaceFirst('CUST-', '')) ?? 0;
    return 'CUST-${(numPart + 1).toString().padLeft(3, '0')}';
  }

  Future<int> create(Customer customer) async {
    final db = await _db.database;
    final code = await generateCode();
    final map = customer.toMap()..remove('id');
    map['code'] = code;
    return await db.insert(_table, map);
  }

  Future<List<Customer>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(_table, orderBy: 'created_at DESC');
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<Customer?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<List<Customer>> search(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'name LIKE ? OR code LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<int> update(Customer customer) async {
    final db = await _db.database;
    return await db.update(
      _table,
      customer.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [customer.id],
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

  Future<List<Customer>> getActiveCustomers() async {
    final db = await _db.database;
    final maps = await db.query(
      _table,
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }
}
