/// Modelo para las promociones del gimnasio
class PromotionModel {
  final String? id;
  final String name;
  final String? description;
  final String discountType; // 'percentage', 'fixed_amount', 'free_registration', 'free_membership'
  final double discountValue;
  final int? minMonths;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<String> appliesTo; // ['registration', 'membership', 'both']
  final int? dayOfWeek; // 0=domingo, 6=sábado
  final String? timeStart; // HH:mm formato
  final String? timeEnd; // HH:mm formato
  final List<String> membershipTypes; // Tipos de membresía que aplican
  final int? maxUses; // Máximo número de usos
  final int currentUses; // Usos actuales
  final Map<String, dynamic> conditions; // Condiciones adicionales
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PromotionModel({
    this.id,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minMonths = 1,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.appliesTo = const [],
    this.dayOfWeek,
    this.timeStart,
    this.timeEnd,
    this.membershipTypes = const [],
    this.maxUses,
    this.currentUses = 0,
    this.conditions = const {},
    this.createdAt,
    this.updatedAt,
  });

  /// Factory para crear desde JSON
  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0.0,
      minMonths: json['min_months'],
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : null,
      isActive: json['is_active'] ?? true,
      appliesTo: json['applies_to'] != null 
          ? List<String>.from(json['applies_to']) 
          : [],
      dayOfWeek: json['day_of_week'],
      timeStart: json['time_start'],
      timeEnd: json['time_end'],
      membershipTypes: json['membership_types'] != null 
          ? List<String>.from(json['membership_types']) 
          : [],
      maxUses: json['max_uses'],
      currentUses: json['current_uses'] ?? 0,
      conditions: json['conditions'] != null 
          ? Map<String, dynamic>.from(json['conditions']) 
          : {},
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      if (minMonths != null) 'min_months': minMonths,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'is_active': isActive,
      'applies_to': appliesTo,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (timeStart != null) 'time_start': timeStart,
      if (timeEnd != null) 'time_end': timeEnd,
      'membership_types': membershipTypes,
      if (maxUses != null) 'max_uses': maxUses,
      'current_uses': currentUses,
      'conditions': conditions,
    };
  }

  /// Crear copia con campos modificados
  PromotionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? discountType,
    double? discountValue,
    int? minMonths,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<String>? appliesTo,
    int? dayOfWeek,
    String? timeStart,
    String? timeEnd,
    List<String>? membershipTypes,
    int? maxUses,
    int? currentUses,
    Map<String, dynamic>? conditions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minMonths: minMonths ?? this.minMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      appliesTo: appliesTo ?? this.appliesTo,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      membershipTypes: membershipTypes ?? this.membershipTypes,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica si la promoción está activa y dentro del período válido
  bool get isCurrentlyValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    // Verificar fechas de inicio y fin
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    // Verificar día de la semana
    if (dayOfWeek != null && now.weekday % 7 != dayOfWeek!) return false;
    
    // Verificar horario
    if (timeStart != null && timeEnd != null) {
      final nowTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      if (nowTime.compareTo(timeStart!) < 0 || nowTime.compareTo(timeEnd!) > 0) {
        return false;
      }
    }
    
    // Verificar máximo de usos
    if (maxUses != null && currentUses >= maxUses!) return false;
    
    return true;
  }

  /// Verifica si la promoción aplica a un tipo específico
  bool appliesTo_(String type) {
    return appliesTo.contains(type) || appliesTo.contains('both');
  }

  /// Verifica si la promoción aplica a un tipo de membresía específico
  bool appliesToMembership(String membershipType) {
    return membershipTypes.isEmpty || membershipTypes.contains(membershipType);
  }

  /// Calcula el descuento para un monto dado
  double calculateDiscount(double amount) {
    if (!isCurrentlyValid) return 0.0;
    
    switch (discountType) {
      case 'percentage':
        return amount * (discountValue / 100);
      case 'fixed_amount':
        return discountValue.clamp(0.0, amount);
      case 'free_registration':
      case 'free_membership':
        return amount; // El monto completo es el descuento
      default:
        return 0.0;
    }
  }

  /// Obtiene el nombre del día de la semana
  String? get dayOfWeekName {
    if (dayOfWeek == null) return null;
    const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return days[dayOfWeek!];
  }

  /// Descripción legible del tipo de descuento
  String get discountDescription {
    switch (discountType) {
      case 'percentage':
        return '${discountValue.toStringAsFixed(0)}% de descuento';
      case 'fixed_amount':
        return '\$${discountValue.toStringAsFixed(0)} de descuento';
      case 'free_registration':
        return 'Registro gratuito';
      case 'free_membership':
        return 'Membresía gratuita';
      default:
        return 'Descuento especial';
    }
  }

  @override
  String toString() {
    return 'PromotionModel(id: $id, name: $name, discountType: $discountType, discountValue: $discountValue, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromotionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
