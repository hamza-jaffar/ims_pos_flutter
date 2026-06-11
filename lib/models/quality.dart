class Quality {
  final int? id;
  final String name;
  final String code; // auto-generated
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quality({
    this.id,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Quality.fromMap(Map<String, dynamic> map) {
    return Quality(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Quality(id: $id, name: $name, code: $code)';
  }
}
