class StockAdjustment {
  final int? id;
  final int productId;
  final int oldQuantity;
  final int newQuantity;
  final String adjustmentType;
  final String? reason;
  final String createdAt;
  final String? productName;

  StockAdjustment({
    this.id,
    required this.productId,
    required this.oldQuantity,
    required this.newQuantity,
    required this.adjustmentType,
    this.reason,
    required this.createdAt,
    this.productName,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'old_quantity': oldQuantity,
      'new_quantity': newQuantity,
      'adjustment_type': adjustmentType,
      'reason': reason,
      'created_at': createdAt,
    };
  }

  factory StockAdjustment.fromMap(Map<String, Object?> map) {
    return StockAdjustment(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      oldQuantity: map['old_quantity'] as int,
      newQuantity: map['new_quantity'] as int,
      adjustmentType: map['adjustment_type'] as String,
      reason: map['reason'] as String?,
      createdAt: map['created_at'] as String,
      productName: map['product_name'] as String?,
    );
  }

  int get quantityDiff => newQuantity - oldQuantity;
}
