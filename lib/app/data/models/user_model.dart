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
    // Calcular días restantes de membresía
    int calculateDaysRemaining(DateTime? expDate) {
      if (expDate == null) return 0;
      final now = DateTime.now();
      final difference = expDate.difference(now).inDays;
      return difference > 0 ? difference : 0;
    }

    DateTime? expDate =
        json['expirationDate'] != null
            ? json['expirationDate'] is DateTime
                ? json['expirationDate']
                : DateTime.parse(json['expirationDate'])
            : null;

    int daysLeft = calculateDaysRemaining(expDate);

    return UserModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'] ?? '',
      membershipType: json['membershipType'] ?? 'normal',
      joinDate:
          json['joinDate'] != null
              ? json['joinDate'] is DateTime
                  ? json['joinDate']
                  : DateTime.parse(json['joinDate'])
              : DateTime.now(),
      expirationDate: expDate,
      isActive: json['isActive'] ?? true,
      photoUrl: json['photoUrl'],
      qrCode: json['qrCode'],
      userNumber: (json['userNumber'] ?? '').toString(), // Convertir a String
      accessHistory: json['accessHistory'] ?? [],
      lastPaymentDate:
          json['lastPaymentDate'] != null
              ? json['lastPaymentDate'] is DateTime
                  ? json['lastPaymentDate']
                  : DateTime.parse(json['lastPaymentDate'])
              : null,
      daysRemaining: daysLeft,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'membershipType': membershipType,
      'joinDate': joinDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'isActive': isActive,
      'photoUrl': photoUrl,
      'qrCode': qrCode,
      'userNumber': userNumber,
      'accessHistory': accessHistory,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
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
