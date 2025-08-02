import 'package:get/get.dart';
import 'package:gymads/app/data/models/promotion_model.dart';
import 'package:gymads/app/data/providers/promotion_provider.dart';

/// Servicio para manejar la lógica de promociones en toda la aplicación
class PromotionService extends GetxService {
  static PromotionService get to => Get.find();
  
  final PromotionProvider _promotionProvider;
  
  PromotionService(this._promotionProvider);

  /// Calcula automáticamente las promociones aplicables a un pago
  Future<Map<String, dynamic>> calculatePromotionsForPayment({
    required String membershipType,
    required double membershipCost,
    required double registrationFee,
    required bool isNewRegistration,
    DateTime? paymentDate,
  }) async {
    final date = paymentDate ?? DateTime.now();
    final promotionsApplied = <PromotionModel>[];
    
    final result = {
      'membershipPromotion': null,
      'registrationPromotion': null,
      'membershipDiscount': 0.0,
      'registrationDiscount': 0.0,
      'finalMembershipCost': membershipCost,
      'finalRegistrationFee': registrationFee,
      'totalDiscount': 0.0,
      'finalTotal': membershipCost + registrationFee,
      'promotionsApplied': promotionsApplied,
    };

    try {
      // Buscar promociones para membresía
      if (membershipCost > 0) {
        final membershipPromotionResult = await _promotionProvider.calculateBestDiscount(
          appliesTo: 'membership',
          amount: membershipCost,
          membershipType: membershipType,
          dateTime: date,
        );
        
        if (membershipPromotionResult['promotion'] != null) {
          result['membershipPromotion'] = membershipPromotionResult['promotion'];
          result['membershipDiscount'] = membershipPromotionResult['discount'];
          result['finalMembershipCost'] = membershipPromotionResult['finalAmount'];
          promotionsApplied.add(membershipPromotionResult['promotion'] as PromotionModel);
        }
      }

      // Buscar promociones para registro (solo si es nuevo registro)
      if (isNewRegistration && registrationFee > 0) {
        final registrationPromotionResult = await _promotionProvider.calculateBestDiscount(
          appliesTo: 'registration',
          amount: registrationFee,
          membershipType: membershipType,
          dateTime: date,
        );
        
        if (registrationPromotionResult['promotion'] != null) {
          result['registrationPromotion'] = registrationPromotionResult['promotion'];
          result['registrationDiscount'] = registrationPromotionResult['discount'];
          result['finalRegistrationFee'] = registrationPromotionResult['finalAmount'];
          promotionsApplied.add(registrationPromotionResult['promotion'] as PromotionModel);
        }
      }

      // Buscar promociones que apliquen a ambos
      final bothPromotionResult = await _promotionProvider.calculateBestDiscount(
        appliesTo: 'both',
        amount: membershipCost + registrationFee,
        membershipType: membershipType,
        dateTime: date,
      );

      // Comparar si la promoción "both" es mejor que las individuales
      final membershipDiscount = result['membershipDiscount'] as double;
      final registrationDiscount = result['registrationDiscount'] as double;
      final individualDiscount = membershipDiscount + registrationDiscount;
      
      if (bothPromotionResult['discount'] > individualDiscount) {
        // La promoción "both" es mejor, reemplazar las individuales
        result['membershipPromotion'] = bothPromotionResult['promotion'];
        result['registrationPromotion'] = null;
        result['membershipDiscount'] = bothPromotionResult['discount'];
        result['registrationDiscount'] = 0.0;
        result['finalMembershipCost'] = membershipCost;
        result['finalRegistrationFee'] = registrationFee;
        promotionsApplied.clear();
        promotionsApplied.add(bothPromotionResult['promotion'] as PromotionModel);
      }

      // Calcular totales finales
      final finalMembershipDiscount = result['membershipDiscount'] as double;
      final finalRegistrationDiscount = result['registrationDiscount'] as double;
      final finalMembershipCost = result['finalMembershipCost'] as double;
      final finalRegistrationFee = result['finalRegistrationFee'] as double;
      
      result['totalDiscount'] = finalMembershipDiscount + finalRegistrationDiscount;
      result['finalTotal'] = finalMembershipCost + finalRegistrationFee;

      return result;
    } catch (e) {
      print('Error al calcular promociones: $e');
      return result;
    }
  }

  /// Obtiene las promociones válidas actualmente
  Future<List<PromotionModel>> getCurrentValidPromotions({
    String? appliesTo,
    String? membershipType,
  }) async {
    try {
      return await _promotionProvider.getValidPromotions(
        appliesTo: appliesTo,
        membershipType: membershipType,
      );
    } catch (e) {
      print('Error al obtener promociones válidas: $e');
      return [];
    }
  }

  /// Registra el uso de una promoción
  Future<bool> registerPromotionUsage(String promotionId) async {
    try {
      return await _promotionProvider.incrementPromotionUsage(promotionId);
    } catch (e) {
      print('Error al registrar uso de promoción: $e');
      return false;
    }
  }

  /// Verifica si hay promociones especiales para el día actual
  Future<List<PromotionModel>> getTodaysSpecialPromotions() async {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday % 7; // Convertir a formato 0=domingo
      
      final allPromotions = await _promotionProvider.getPromotions(onlyActive: true);
      
      return allPromotions.where((promotion) {
        return promotion.isCurrentlyValid && 
               (promotion.dayOfWeek == dayOfWeek || promotion.dayOfWeek == null);
      }).toList();
    } catch (e) {
      print('Error al obtener promociones del día: $e');
      return [];
    }
  }

  /// Genera un resumen legible de las promociones aplicadas
  String generatePromotionSummary(Map<String, dynamic> promotionResult) {
    final promotionsApplied = promotionResult['promotionsApplied'] as List<PromotionModel>;
    
    if (promotionsApplied.isEmpty) {
      return 'No se aplicaron promociones';
    }

    final summaryParts = <String>[];
    
    for (final promotion in promotionsApplied) {
      String description = promotion.name;
      
      if (promotion.appliesTo_('registration')) {
        description += ' (registro)';
      } else if (promotion.appliesTo_('membership')) {
        description += ' (membresía)';
      } else if (promotion.appliesTo_('both')) {
        description += ' (total)';
      }
      
      summaryParts.add(description);
    }
    
    final totalDiscount = promotionResult['totalDiscount'] as double;
    return '${summaryParts.join(", ")} - Descuento total: \$${totalDiscount.toStringAsFixed(2)}';
  }

  /// Verifica si es un día especial con promociones
  bool isSpecialPromotionDay(DateTime date) {
    final dayOfWeek = date.weekday % 7;
    // Ejemplo: sábados (6) tienen promociones especiales
    return dayOfWeek == 6;
  }

  /// Obtiene el mensaje de promoción para mostrar en la UI
  String getPromotionMessage(DateTime date) {
    if (isSpecialPromotionDay(date)) {
      final dayName = _getDayName(date.weekday % 7);
      return '¡Hoy es $dayName! Pueden aplicar promociones especiales.';
    }
    return '';
  }

  String _getDayName(int dayOfWeek) {
    const days = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    return days[dayOfWeek];
  }
}
