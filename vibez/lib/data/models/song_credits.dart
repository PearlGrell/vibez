class CreditEntity {
  final String id;
  final String name;

  const CreditEntity({
    required this.id,
    required this.name,
  });

  factory CreditEntity.fromJson(Map<String, dynamic> json) {
    return CreditEntity(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Credit {
  final String role;
  final List<CreditEntity> entities;

  const Credit({
    required this.role,
    required this.entities,
  });

  factory Credit.fromJson(Map<String, dynamic> json) {
    return Credit(
      role: json['role'] as String? ?? '',
      entities: (json['entities'] as List?)
              ?.map((e) => CreditEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'entities': entities.map((e) => e.toJson()).toList(),
    };
  }
}
