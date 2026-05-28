class Room {
  final int? id;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  Room({
    this.id,
    required this.name,
    this.code,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      name: map['name'] as String,
      code: map['code'] as String?,
      description: map['description'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Room copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
