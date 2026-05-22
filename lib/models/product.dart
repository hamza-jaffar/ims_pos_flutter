class Product {
  final int? id;
  final String name;
  final String code; // SKU (auto-generated)
  final String? barcode;
  final int? brandId;
  final int? categoryId;
  final int? supplierId;
  final int quantity;
  final int minStockQuantity;
  final double purchasePrice;
  final double sellingPrice;
  final double? discountPrice;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined entity names for display convenience
  final String? brandName;
  final String? categoryName;
  final String? supplierName;

  Product({
    this.id,
    required this.name,
    required this.code,
    this.barcode,
    this.brandId,
    this.categoryId,
    this.supplierId,
    this.quantity = 0,
    this.minStockQuantity = 5,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.discountPrice,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.brandName,
    this.categoryName,
    this.supplierName,
  });

  bool get isLowStock => quantity <= minStockQuantity;

  bool get hasDiscount =>
      discountPrice != null &&
      discountPrice! > 0.0 &&
      discountPrice! < sellingPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'barcode': barcode,
      'brand_id': brandId,
      'category_id': categoryId,
      'supplier_id': supplierId,
      'quantity': quantity,
      'min_stock_quantity': minStockQuantity,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'discount_price': discountPrice,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String,
      barcode: map['barcode'] as String?,
      brandId: map['brand_id'] as int?,
      categoryId: map['category_id'] as int?,
      supplierId: map['supplier_id'] as int?,
      quantity: map['quantity'] as int,
      minStockQuantity: map['min_stock_quantity'] as int,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      discountPrice: map['discount_price'] != null
          ? (map['discount_price'] as num).toDouble()
          : null,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      brandName: map['brand_name'] as String?,
      categoryName: map['category_name'] as String?,
      supplierName: map['supplier_name'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? code,
    String? barcode,
    int? brandId,
    int? categoryId,
    int? supplierId,
    int? quantity,
    int? minStockQuantity,
    double? purchasePrice,
    double? sellingPrice,
    double? discountPrice,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brandName,
    String? categoryName,
    String? supplierName,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      barcode: barcode ?? this.barcode,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      quantity: quantity ?? this.quantity,
      minStockQuantity: minStockQuantity ?? this.minStockQuantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brandName: brandName ?? this.brandName,
      categoryName: categoryName ?? this.categoryName,
      supplierName: supplierName ?? this.supplierName,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, code: $code, quantity: $quantity, price: $sellingPrice)';
  }
}
