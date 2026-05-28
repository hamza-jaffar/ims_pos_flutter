import 'package:ims_pos_system/core/database/database_helper.dart';
import 'package:ims_pos_system/core/database/tables/stock_adjustment_table.dart';
import 'package:ims_pos_system/models/stock_adjustment.dart';

class StockAdjustmentService {
  StockAdjustmentService._();
  static final StockAdjustmentService instance = StockAdjustmentService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  static const String _table = StockAdjustmentTable.tableName;

  Future<int> create(StockAdjustment adjustment) async {
    final db = await _db.database;
    final map = adjustment.toMap()..remove('id');
    return await db.insert(_table, map);
  }

  Future<List<StockAdjustment>> getAll() async {
    final db = await _db.database;
    final sql =
        '''
      SELECT a.*, p.name AS product_name
      FROM $_table a
      LEFT JOIN ${DatabaseHelper.productTable} p ON a.product_id = p.id
      ORDER BY a.created_at DESC
    ''';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => StockAdjustment.fromMap(m)).toList();
  }

  Future<List<StockAdjustment>> getByProductId(int productId) async {
    final db = await _db.database;
    final sql =
        '''
      SELECT a.*, p.name AS product_name
      FROM $_table a
      LEFT JOIN ${DatabaseHelper.productTable} p ON a.product_id = p.id
      WHERE a.product_id = ?
      ORDER BY a.created_at DESC
    ''';
    final maps = await db.rawQuery(sql, [productId]);
    return maps.map((m) => StockAdjustment.fromMap(m)).toList();
  }
}
