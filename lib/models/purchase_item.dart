import 'package:ims_pos_system/models/product.dart';

class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int productId;
  final int quantity;
  final double unitCost;
  final double subtotal;
  
  // Optional related data
  final Product? product;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    this.product,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'subtotal': subtotal,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map, {Product? product}) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitCost: (map['unit_cost'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      product: product,
    );
  }

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    int? quantity,
    double? unitCost,
    double? subtotal,
    Product? product,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      subtotal: subtotal ?? this.subtotal,
      product: product ?? this.product,
    );
  }
}
