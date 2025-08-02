import 'package:flutter/foundation.dart';
import 'package:gymads/app/data/models/promotion_model.dart';
import 'package:gymads/app/data/providers/api_provider.dart';

/// Provider para gestionar las promociones en la base de datos
class PromotionProvider {
  final ApiProvider _apiProvider;

  PromotionProvider(this._apiProvider);

  /// Obtiene todas las promociones con filtros opcionales
  Future<List<PromotionModel>> getPromotions({
    bool onlyActive = false,
    bool onlyValid = false,
  }) async {
    try {
      final response = await _apiProvider.getAll();
      
      if (response['error'] || response['data'] == null) {
        if (kDebugMode) {
          print('Error al obtener promociones: ${response['message']}');
        }
        return [];
      }

      final data = response['data'];
      if (data is! List) {
        if (kDebugMode) {
          print('Error: Los datos de promociones no son una lista');
        }
        return [];
      }

      List<PromotionModel> promotions = [];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          try {
            final promotion = PromotionModel.fromJson(item);
            
            // Aplicar filtros
            if (onlyActive && !promotion.isActive) continue;
            if (onlyValid && !promotion.isCurrentlyValid) continue;
            
            promotions.add(promotion);
          } catch (e) {
            if (kDebugMode) {
              print('Error al procesar promoción: $e');
              print('Datos de la promoción: $item');
            }
          }
        }
      }

      // Ordenar por fecha de creación (más recientes primero)
      promotions.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      return promotions;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener promociones: $e');
      }
      return [];
    }
  }

  /// Obtiene una promoción específica por ID
  Future<PromotionModel?> getPromotionById(String id) async {
    try {
      final response = await _apiProvider.get(id);
      
      if (response['error'] || response['data'] == null) {
        if (kDebugMode) {
          print('Error al obtener promoción por ID: ${response['message']}');
        }
        return null;
      }

      return PromotionModel.fromJson(response['data']);
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener promoción: $e');
      }
      return null;
    }
  }

  /// Obtiene promociones válidas para un contexto específico
  Future<List<PromotionModel>> getValidPromotions({
    String? appliesTo, // 'registration', 'membership', 'both'
    String? membershipType,
    DateTime? dateTime,
  }) async {
    try {
      final allPromotions = await getPromotions(onlyActive: true);
      
      return allPromotions.where((promotion) {
        // Verificar si está activa y dentro del período válido
        if (!promotion.isCurrentlyValid) return false;
        
        // Verificar a qué aplica
        if (appliesTo != null && !promotion.appliesTo_(appliesTo)) return false;
        
        // Verificar tipo de membresía
        if (membershipType != null && !promotion.appliesToMembership(membershipType)) return false;
        
        return true;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener promociones válidas: $e');
      }
      return [];
    }
  }

  /// Crea una nueva promoción
  Future<bool> createPromotion(PromotionModel promotion) async {
    try {
      final response = await _apiProvider.add(promotion.toJson());
      
      if (!response['error']) {
        if (kDebugMode) {
          print('✅ Promoción creada correctamente');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Error al crear promoción: ${response['message']}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al crear promoción: $e');
      }
      return false;
    }
  }

  /// Actualiza una promoción existente
  Future<bool> updatePromotion(String id, PromotionModel promotion) async {
    try {
      final response = await _apiProvider.update(id, promotion.toJson());
      
      if (!response['error']) {
        if (kDebugMode) {
          print('✅ Promoción actualizada correctamente');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Error al actualizar promoción: ${response['message']}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al actualizar promoción: $e');
      }
      return false;
    }
  }

  /// Elimina una promoción
  Future<bool> deletePromotion(String id) async {
    try {
      final response = await _apiProvider.delete(id);
      
      if (!response['error']) {
        if (kDebugMode) {
          print('✅ Promoción eliminada correctamente');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Error al eliminar promoción: ${response['message']}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al eliminar promoción: $e');
      }
      return false;
    }
  }

  /// Activa o desactiva una promoción
  Future<bool> togglePromotionStatus(String id, bool isActive) async {
    try {
      final response = await _apiProvider.update(id, {
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      if (!response['error']) {
        if (kDebugMode) {
          print('✅ Estado de promoción actualizado: ${isActive ? 'activada' : 'desactivada'}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Error al cambiar estado de promoción: ${response['message']}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cambiar estado de promoción: $e');
      }
      return false;
    }
  }

  /// Incrementa el contador de usos de una promoción
  Future<bool> incrementPromotionUsage(String id) async {
    try {
      // Primero obtener la promoción actual
      final promotion = await getPromotionById(id);
      if (promotion == null) return false;
      
      // Incrementar el contador
      final updatedPromotion = promotion.copyWith(
        currentUses: promotion.currentUses + 1,
        updatedAt: DateTime.now(),
      );
      
      return await updatePromotion(id, updatedPromotion);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al incrementar uso de promoción: $e');
      }
      return false;
    }
  }

  /// Calcula el mejor descuento disponible para un caso específico
  Future<Map<String, dynamic>> calculateBestDiscount({
    required String appliesTo,
    required double amount,
    String? membershipType,
    DateTime? dateTime,
  }) async {
    try {
      final validPromotions = await getValidPromotions(
        appliesTo: appliesTo,
        membershipType: membershipType,
        dateTime: dateTime,
      );

      if (validPromotions.isEmpty) {
        return {
          'promotion': null,
          'discount': 0.0,
          'finalAmount': amount,
        };
      }

      // Encontrar la promoción con mayor descuento
      PromotionModel? bestPromotion;
      double bestDiscount = 0.0;

      for (final promotion in validPromotions) {
        final discount = promotion.calculateDiscount(amount);
        if (discount > bestDiscount) {
          bestDiscount = discount;
          bestPromotion = promotion;
        }
      }

      return {
        'promotion': bestPromotion,
        'discount': bestDiscount,
        'finalAmount': (amount - bestDiscount).clamp(0.0, double.infinity),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al calcular mejor descuento: $e');
      }
      return {
        'promotion': null,
        'discount': 0.0,
        'finalAmount': amount,
      };
    }
  }
}
