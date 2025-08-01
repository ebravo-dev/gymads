class MembershipTypeModel {
  final String? id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MembershipTypeModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.durationDays = 30,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'duration_days': durationDays,
      'is_active': isActive,
    };
  }

  factory MembershipTypeModel.fromMap(Map<String, dynamic> map, String id) {
    return MembershipTypeModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] is int) ? (map['price'] as int).toDouble() : (map['price'] ?? 0.0),
      durationDays: map['duration_days'] ?? 30,
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  MembershipTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationDays,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}