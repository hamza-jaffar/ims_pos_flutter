class Customer {
  final int? id;
  final String name;
  final String? code;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final int loyaltyPoints;
  final double totalPurchases;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    this.code,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.loyaltyPoints = 0,
    this.totalPurchases = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'loyalty_points': loyaltyPoints,
      'total_purchases': totalPurchases,
      'is_active': isActive ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      zipCode: map['zip_code'] as String?,
      loyaltyPoints: map['loyalty_points'] as int? ?? 0,
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0.0,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Customer copyWith({
    int? id,
    String? name,
    String? code,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    int? loyaltyPoints,
    double? totalPurchases,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone, loyaltyPoints: $loyaltyPoints)';
  }
}
