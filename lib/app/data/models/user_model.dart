import 'package:flutter/foundation.dart';

class UserModel {
  final String? id;
  final String name;
  final String phone;
  final String membershipType; // normal, estudiante, profesor
  final DateTime joinDate;
  final DateTime? expirationDate;
  final bool isActive;
  final String? photoUrl;
  final String? qrCode;
  final String userNumber; // Cambiado de int a String
  final String? rfidCard; // Identificador de tarjeta RFID
  final List<dynamic> accessHistory;
  final DateTime? lastPaymentDate;
  final int daysRemaining;
  final double membershipPrice; // Precio dinámico desde base de datos
  
  // Campos de promociones
  final String? currentPromotionId;
  final String? currentPromotionName;
  final double promotionDiscountAmount;
  final DateTime? promotionAppliedDate;
  final DateTime? promotionExpiresDate;

  // Precios de membresías
  static const Map<String, double> membershipPrices = {
    'normal': 480.0,
    'estudiante': 350.0,
    'profesor': 350.0,
    'anual': 4800.0,    // Agregado precio anual
  };
  // Duración de membresías (días)
  static const Map<String, int> membershipDurations = {
    'normal': 30,
    'estudiante': 30,
    'profesor': 30,
    'anual': 365,       // Agregado duración anual
  };

  // Precio de registro nuevo
  static const double registrationFee = 250.0;

  UserModel({
    this.id,
    required this.name,
    required this.phone,
    required this.membershipType,
    required this.joinDate,
    this.expirationDate,
    this.isActive = true,
    this.photoUrl,
    this.qrCode,
    this.rfidCard,
    required this.userNumber,
    this.accessHistory = const [],
    this.lastPaymentDate,
    this.daysRemaining = 0,
    this.membershipPrice = 0.0, // Precio dinámico con valor por defecto
    
    // Campos de promociones
    this.currentPromotionId,
    this.currentPromotionName,
    this.promotionDiscountAmount = 0.0,
    this.promotionAppliedDate,
    this.promotionExpiresDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('Datos recibidos en fromJson: $json');
    }

    // Función para parsear fechas
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value);
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando fecha: $value - Error: $e');
        }
        return null;
      }
    }

    // Parsear las fechas asegurándose de que sean válidas (manejando snake_case y camelCase)
    final DateTime? expDate = parseDateTime(json['expiration_date'] ?? json['expirationDate']);
    final DateTime joinDate = parseDateTime(json['join_date'] ?? json['joinDate']) ?? DateTime.now();
    final DateTime? lastPaymentDate = parseDateTime(json['last_payment_date'] ?? json['lastPaymentDate']);

    if (kDebugMode) {
      print('DEBUG! Fecha de registro: $joinDate');
      print('DEBUG! Fecha de expiración: $expDate');
      print('DEBUG! Fecha último pago: $lastPaymentDate');
    }

    // Calcular días restantes considerando también las horas
    int daysLeft = 0;
    if (expDate != null) {
      final now = DateTime.now();
      final difference = expDate.difference(now);
      daysLeft = difference.inHours > 0 ? (difference.inHours / 24).ceil() : 0;

      if (kDebugMode) {
        print('Días restantes calculados: $daysLeft');
      }
    }

    return UserModel(
      id: json['id']?.toString(),
      name: (json['name'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
      membershipType:
          (json['membership_type'] ?? json['membershipType'] ?? 'normal').toString().toLowerCase(),
      joinDate: joinDate,
      expirationDate: expDate,
      isActive: json['is_active'] ?? json['isActive'] == true,
      photoUrl: (json['photo_url'] ?? json['photoUrl'])?.toString(),
      qrCode: (json['qr_code'] ?? json['qrCode'])?.toString(),
      rfidCard: (json['rfid_card'] ?? json['rfidCard'])?.toString(),
      userNumber: ((json['user_number'] ?? json['userNumber'] ?? '')).toString().trim(),
      accessHistory: List<dynamic>.from(json['accessHistory'] ?? []),
      lastPaymentDate: lastPaymentDate,
      daysRemaining: daysLeft,
      membershipPrice: (json['membership_price'] ?? 0.0).toDouble(), // Precio desde BD
      
      // Campos de promociones
      currentPromotionId: (json['current_promotion_id'] ?? json['currentPromotionId'])?.toString(),
      currentPromotionName: (json['current_promotion_name'] ?? json['currentPromotionName'])?.toString(),
      promotionDiscountAmount: (json['promotion_discount_amount'] ?? json['promotionDiscountAmount'] ?? 0.0).toDouble(),
      promotionAppliedDate: parseDateTime(json['promotion_applied_date'] ?? json['promotionAppliedDate']),
      promotionExpiresDate: parseDateTime(json['promotion_expires_date'] ?? json['promotionExpiresDate']),
    );
  }

  Map<String, dynamic> toJson() {
    if (kDebugMode) {
      print('Convirtiendo a JSON con fecha de expiración: $expirationDate');
    }
    
    // Adaptamos los nombres de las columnas a la estructura real de la base de datos
    // y omitimos accessHistory que no existe en la tabla
    final Map<String, dynamic> jsonMap = {
      'name': name,
      'phone': phone,
      'membership_type': membershipType, // snake_case para la base de datos
      'join_date': joinDate.toUtc().toIso8601String(), // snake_case
      'expiration_date': expirationDate?.toUtc().toIso8601String(), // snake_case
      'is_active': isActive, // snake_case
      'photo_url': photoUrl, // snake_case
      'qr_code': qrCode, // snake_case
      'rfid_card': rfidCard, // snake_case
      'user_number': userNumber, // snake_case
      'last_payment_date': lastPaymentDate?.toUtc().toIso8601String(), // snake_case
      
      // Campos de promociones
      'current_promotion_id': currentPromotionId,
      'current_promotion_name': currentPromotionName,
      'promotion_discount_amount': promotionDiscountAmount,
      'promotion_applied_date': promotionAppliedDate?.toUtc().toIso8601String(),
      'promotion_expires_date': promotionExpiresDate?.toUtc().toIso8601String(),
    };
    
    return jsonMap;
  }

  // Método para copiar el modelo con algunos cambios
  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? membershipType,
    DateTime? joinDate,
    DateTime? expirationDate,
    bool? isActive,
    String? photoUrl,
    String? qrCode,
    String? rfidCard,
    String? userNumber, // Cambiado de int? a String?
    List<dynamic>? accessHistory,
    DateTime? lastPaymentDate,
    double? membershipPrice, // Agregado precio de membresía
    
    // Campos de promociones
    String? currentPromotionId,
    String? currentPromotionName,
    double? promotionDiscountAmount,
    DateTime? promotionAppliedDate,
    DateTime? promotionExpiresDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      membershipType: membershipType ?? this.membershipType,
      joinDate: joinDate ?? this.joinDate,
      expirationDate: expirationDate ?? this.expirationDate,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      qrCode: qrCode ?? this.qrCode,
      rfidCard: rfidCard ?? this.rfidCard,
      userNumber: userNumber ?? this.userNumber,
      accessHistory: accessHistory ?? this.accessHistory,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      membershipPrice: membershipPrice ?? this.membershipPrice, // Precio dinámico
      
      // Campos de promociones
      currentPromotionId: currentPromotionId ?? this.currentPromotionId,
      currentPromotionName: currentPromotionName ?? this.currentPromotionName,
      promotionDiscountAmount: promotionDiscountAmount ?? this.promotionDiscountAmount,
      promotionAppliedDate: promotionAppliedDate ?? this.promotionAppliedDate,
      promotionExpiresDate: promotionExpiresDate ?? this.promotionExpiresDate,
    );
  }

  // Método para registrar un nuevo acceso
  UserModel addAccessRecord() {
    // Actualizamos el modelo en memoria, aunque el acceso no se guardará en Supabase
    // Debido a que hemos eliminado accessHistory del toJson
    final now = DateTime.now();
    final newHistory = List<dynamic>.from(accessHistory);
    newHistory.add(now.toIso8601String());

    return copyWith(accessHistory: newHistory);
  }

  // Método para verificar si la membresía necesita renovación (5 días o menos)
  bool get needsRenewal => daysRemaining <= 5 && daysRemaining > 0;

  // Método para verificar si es un registro nuevo (expiró hace más de 3 meses)
  bool isNewRegistration() {
    if (expirationDate == null) return true;

    final now = DateTime.now();
    final daysSinceExpiration = now.difference(expirationDate!).inDays;
    return daysSinceExpiration > 90; // Más de 3 meses
  }

  // Método para calcular el monto total a pagar (incluyendo tarifa de registro si aplica)
  double calculateTotalPayment() {
    double total = membershipPrice; // Usar el precio dinámico

    // Si es registro nuevo, añadir tarifa de registro
    if (isNewRegistration()) {
      total += registrationFee;
    }

    return total;
  }
  
  // Métodos relacionados con promociones
  
  /// Verifica si el usuario tiene una promoción activa
  bool get hasActivePromotion {
    if (currentPromotionId == null) return false;
    if (promotionExpiresDate == null) return true; // Sin fecha de expiración
    return DateTime.now().isBefore(promotionExpiresDate!);
  }
  
  /// Obtiene el texto descriptivo de la promoción activa
  String get promotionDisplayText {
    if (!hasActivePromotion) return '';
    
    String text = currentPromotionName ?? 'Promoción activa';
    if (promotionDiscountAmount > 0) {
      text += ' (-\$${promotionDiscountAmount.toStringAsFixed(2)})';
    }
    return text;
  }
  
  /// Verifica si la promoción está por expirar (próximos 7 días)
  bool get promotionExpiringSoon {
    if (!hasActivePromotion || promotionExpiresDate == null) return false;
    final daysUntilExpiration = promotionExpiresDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration > 0;
  }
  
  /// Calcula el monto total considerando la promoción activa
  double calculateTotalWithPromotion() {
    double total = calculateTotalPayment();
    
    if (hasActivePromotion && promotionDiscountAmount > 0) {
      total -= promotionDiscountAmount;
      // Asegurar que el total no sea negativo
      total = total < 0 ? 0 : total;
    }
    
    return total;
  }
}
