class ProductModel {
  final int? id;
  final int? brandId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? brandName; // For joining

  ProductModel({
    this.id,
    this.brandId,
    required this.name,
    this.code,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.brandName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand_id': brandId,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      brandId: map['brand_id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      brandName: map['brand_name'] as String?,
    );
  }

  ProductModel copyWith({
    int? id,
    int? brandId,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? brandName,
  }) {
    return ProductModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      brandName: brandName ?? this.brandName,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, brandId: $brandId, name: $name)';
  }
}
