import 'package:ims_pos_system/models/product.dart';

class PurchaseItem {
  final int? id;
  final int? purchaseId;
  final int productId;
  final int quantity;
  final double unitCost;
  final double subtotal;
  final double costPrice;
  final int returnQty;

  // Optional related data
  final Product? product;

  PurchaseItem({
    this.id,
    this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.unitCost,
    required this.subtotal,
    this.costPrice = 0.0,
    this.returnQty = 0,
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
      'cost_price': costPrice,
      'return_qty': returnQty,
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
      costPrice: map['cost_price'] != null
          ? (map['cost_price'] as num).toDouble()
          : 0.0,
      returnQty: (map['return_qty'] as num?)?.toInt() ?? 0,
      product: product,
    );
  }

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    double? costPrice,
    int? quantity,
    double? unitCost,
    double? subtotal,
    int? returnQty,
    Product? product,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      subtotal: subtotal ?? this.subtotal,
      costPrice: costPrice ?? this.costPrice,
      returnQty: returnQty ?? this.returnQty,
      product: product ?? this.product,
    );
  }
}
