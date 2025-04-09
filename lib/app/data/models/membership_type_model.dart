class MembershipTypeModel {
  final String? id;
  final String name;
  final String description;
  final double price;
  final bool isActive;

  MembershipTypeModel({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'fields': {
        'name': {'stringValue': name},
        'description': {'stringValue': description},
        'price': {'doubleValue': price},
        'isActive': {'booleanValue': isActive},
      }
    };
  }

  factory MembershipTypeModel.fromMap(Map<String, dynamic> map, String id) {
    final fields = map['fields'] as Map<String, dynamic>;
    return MembershipTypeModel(
      id: id,
      name: fields['name']?['stringValue'] ?? '',
      description: fields['description']?['stringValue'] ?? '',
      price: fields['price']?['doubleValue'] ?? 0.0,
      isActive: fields['isActive']?['booleanValue'] ?? true,
    );
  }

  MembershipTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? isActive,
  }) {
    return MembershipTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
    );
  }
}