class Supplier {
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
  final String? contactPerson;
  final String? paymentTerms;
  final String? taxId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Supplier({
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
    this.contactPerson,
    this.paymentTerms,
    this.taxId,
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
      'contact_person': contactPerson,
      'payment_terms': paymentTerms,
      'tax_id': taxId,
      'is_active': isActive ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
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
      contactPerson: map['contact_person'] as String?,
      paymentTerms: map['payment_terms'] as String?,
      taxId: map['tax_id'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Supplier copyWith({
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
    String? contactPerson,
    String? paymentTerms,
    String? taxId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
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
      contactPerson: contactPerson ?? this.contactPerson,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      taxId: taxId ?? this.taxId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Supplier(id: $id, name: $name, email: $email, phone: $phone)';
  }
}
