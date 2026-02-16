/// Model for Staff Profile (Staff user linked to a branch)
class StaffProfileModel {
  final String id;
  final String userId;
  final String gymId;
  final String branchId;
  final String role; // 'owner_admin' | 'branch_staff'
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffProfileModel({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.branchId,
    required this.role,
    this.firstName,
    this.lastName,
    this.displayName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffProfileModel.fromJson(Map<String, dynamic> json) {
    return StaffProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      gymId: json['gym_id'] as String,
      branchId: json['branch_id'] as String,
      role: json['role'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      displayName: json['display_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'gym_id': gymId,
      'branch_id': branchId,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get full name composed from parts
  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isNotEmpty ? parts.join(' ') : (displayName ?? '');
  }

  /// Check if user is owner_admin
  bool get isOwnerAdmin => role == 'owner_admin';

  /// Check if user is branch_staff
  bool get isBranchStaff => role == 'branch_staff';

  StaffProfileModel copyWith({
    String? id,
    String? userId,
    String? gymId,
    String? branchId,
    String? role,
    String? firstName,
    String? lastName,
    String? displayName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gymId: gymId ?? this.gymId,
      branchId: branchId ?? this.branchId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'StaffProfileModel(id: $id, userId: $userId, role: $role, branchId: $branchId)';
}
