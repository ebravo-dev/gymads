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
  final List<dynamic> accessHistory;
  final DateTime? lastPaymentDate;
  final int daysRemaining;

  // Precios de membresías
  static const Map<String, double> membershipPrices = {
    'normal': 480.0,
    'estudiante': 350.0,
    'profesor': 350.0,
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
    required this.userNumber,
    this.accessHistory = const [],
    this.lastPaymentDate,
    this.daysRemaining = 0,
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

    // Parsear las fechas asegurándose de que sean válidas
    final DateTime? expDate = parseDateTime(json['expirationDate']);
    final DateTime joinDate = parseDateTime(json['joinDate']) ?? DateTime.now();
    final DateTime? lastPaymentDate = parseDateTime(json['lastPaymentDate']);

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
          (json['membershipType'] ?? 'normal').toString().toLowerCase(),
      joinDate: joinDate,
      expirationDate: expDate,
      isActive: json['isActive'] == true,
      photoUrl: json['photoUrl']?.toString(),
      qrCode: json['qrCode']?.toString(),
      userNumber: (json['userNumber'] ?? '').toString().trim(),
      accessHistory: List<dynamic>.from(json['accessHistory'] ?? []),
      lastPaymentDate: lastPaymentDate,
      daysRemaining: daysLeft,
    );
  }

  Map<String, dynamic> toJson() {
    if (kDebugMode) {
      print('Convirtiendo a JSON con fecha de expiración: $expirationDate');
    }
    return {
      'name': name,
      'phone': phone,
      'membershipType': membershipType,
      'joinDate': joinDate.toUtc().toIso8601String(),
      'expirationDate': expirationDate?.toUtc().toIso8601String(),
      'isActive': isActive,
      'photoUrl': photoUrl,
      'qrCode': qrCode,
      'userNumber': userNumber,
      'accessHistory': accessHistory,
      'lastPaymentDate': lastPaymentDate?.toUtc().toIso8601String(),
    };
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
    String? userNumber, // Cambiado de int? a String?
    List<dynamic>? accessHistory,
    DateTime? lastPaymentDate,
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
      userNumber: userNumber ?? this.userNumber,
      accessHistory: accessHistory ?? this.accessHistory,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    );
  }

  // Método para registrar un nuevo acceso
  UserModel addAccessRecord() {
    final now = DateTime.now();
    final newHistory = List<dynamic>.from(accessHistory);
    newHistory.add(now.toIso8601String());

    return copyWith(accessHistory: newHistory);
  }

  // Método para verificar si la membresía necesita renovación (5 días o menos)
  bool get needsRenewal => daysRemaining <= 5 && daysRemaining > 0;

  // Método para obtener el precio de la membresía actual
  double get membershipPrice =>
      membershipPrices[membershipType] ?? membershipPrices['normal']!;

  // Método para verificar si es un registro nuevo (expiró hace más de 3 meses)
  bool isNewRegistration() {
    if (expirationDate == null) return true;

    final now = DateTime.now();
    final daysSinceExpiration = now.difference(expirationDate!).inDays;
    return daysSinceExpiration > 90; // Más de 3 meses
  }

  // Método para calcular el monto total a pagar (incluyendo tarifa de registro si aplica)
  double calculateTotalPayment() {
    double total = membershipPrice;

    // Si es registro nuevo, añadir tarifa de registro
    if (isNewRegistration()) {
      total += registrationFee;
    }

    return total;
  }
}
