import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/core/utils/snackbar_helper.dart';
import 'package:gymads/app/data/models/promotion_model.dart';
import 'package:gymads/app/data/providers/promotion_provider.dart';

class PromocionesController extends GetxController {
  final PromotionProvider promotionProvider;

  PromocionesController({required this.promotionProvider});

  // Estado observable para la lista de promociones
  final RxList<PromotionModel> promociones = <PromotionModel>[].obs;

  // Estado para búsqueda y filtrado
  final searchQuery = ''.obs;
  final showOnlyActive = true.obs;
  final showOnlyValid = false.obs;

  // Estado para indicar carga
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Estado para formulario de promoción
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final selectedDiscountType = 'percentage'.obs;
  final discountValueController = TextEditingController();
  final minMonthsController = TextEditingController();
  final maxUsesController = TextEditingController();
  final selectedAppliesTo = <String>[].obs;
  final selectedMembershipTypes = <String>[].obs;
  final selectedDayOfWeek = Rx<int?>(null);
  final timeStartController = TextEditingController();
  final timeEndController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final isActiveForm = true.obs;
  final conditionsController = TextEditingController();

  // Opciones para dropdowns
  final List<String> discountTypes = [
    'percentage',
    'fixed_amount',
    'free_registration',
    'free_membership'
  ];

  final List<String> appliesToOptions = [
    'registration',
    'membership',
    'both'
  ];

  final List<String> daysOfWeek = [
    'Domingo',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado'
  ];

  // Lista de tipos de membresía disponibles (se puede cargar dinámicamente)
  final membershipTypesOptions = <String>[
    'normal',
    'premium',
    'anual',
    'estudiante'
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPromociones();
    // Inicializar valores por defecto
    discountValueController.text = '0';
    minMonthsController.text = '1';
  }

  @override
  void onClose() {
    // Limpiar controladores
    nombreController.dispose();
    descripcionController.dispose();
    discountValueController.dispose();
    minMonthsController.dispose();
    maxUsesController.dispose();
    timeStartController.dispose();
    timeEndController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    conditionsController.dispose();
    super.onClose();
  }

  /// Lista filtrada de promociones
  List<PromotionModel> get filteredPromociones {
    var filtered = promociones.where((promocion) {
      // Filtro por texto de búsqueda
      final matchesSearch = searchQuery.value.isEmpty ||
          promocion.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (promocion.description?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false);

      // Filtro por estado activo
      final matchesActive = !showOnlyActive.value || promocion.isActive;

      // Filtro por validez actual
      final matchesValid = !showOnlyValid.value || promocion.isCurrentlyValid;

      return matchesSearch && matchesActive && matchesValid;
    }).toList();

    // Ordenar por estado (activas primero) y luego por fecha de creación
    filtered.sort((a, b) {
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      final aDate = a.createdAt ?? DateTime.now();
      final bDate = b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  /// Obtiene todas las promociones
  Future<void> fetchPromociones() async {
    // Evitar múltiples llamadas concurrentes
    if (isLoading.value) {
      print('⚠️ Ya hay una carga en progreso, evitando duplicación');
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      print('🔄 Obteniendo promociones...');

      final result = await promotionProvider.getPromotions();
      
      // Limpiar la lista y agregar los nuevos elementos
      promociones.clear();
      promociones.addAll(result);
      
      print('✅ Promociones obtenidas: ${result.length}');
      print('📋 Lista actualizada. Total en memoria: ${promociones.length}');

      if (result.isEmpty) {
        errorMessage.value = 'No hay promociones disponibles';
      }
    } catch (e) {
      print('❌ Error al obtener promociones: $e');
      errorMessage.value = 'Error al cargar promociones: $e';
      SnackbarHelper.error('Error', 'Error al cargar promociones: $e');
    } finally {
      isLoading.value = false;
      print('🏁 Carga de promociones completada');
    }
  }

  /// Método centralizado para actualizar la lista después de operaciones CRUD
  Future<void> _refreshPromociones() async {
    // Solo actualizar si no hay una carga en progreso
    if (!isLoading.value) {
      await Future.delayed(const Duration(milliseconds: 300)); // Delay más corto
      await fetchPromociones();
    } else {
      print('⚠️ Carga en progreso, posponiendo actualización');
      // Intentar de nuevo después de un delay más largo
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!isLoading.value) {
          fetchPromociones();
        }
      });
    }
  }

  /// Crea una nueva promoción
  Future<bool> createPromocion(PromotionModel promocion) async {
    try {
      print('🔄 Creando promoción: ${promocion.name}');
      
      final success = await promotionProvider.createPromotion(promocion);
      
      if (success) {
        print('✅ Promoción creada exitosamente');
        
        SnackbarHelper.success('Éxito', 'Promoción creada correctamente');
        
        // Actualizar la lista en background después del éxito
        _refreshPromociones();
        
        return true;
      } else {
        print('❌ Error al crear promoción en el provider');
        SnackbarHelper.error('Error', 'No se pudo crear la promoción');
        return false;
      }
    } catch (e) {
      print('❌ Excepción al crear promoción: $e');
      SnackbarHelper.error('Error', 'Error al crear promoción: $e');
      return false;
    }
  }

  /// Actualiza una promoción existente
  Future<bool> updatePromocion(String id, PromotionModel promocion) async {
    try {
      print('🔄 Actualizando promoción: ${promocion.name}');
      
      final success = await promotionProvider.updatePromotion(id, promocion);
      
      if (success) {
        print('✅ Promoción actualizada exitosamente');
        
        SnackbarHelper.success('Éxito', 'Promoción actualizada correctamente');
        
        // Actualizar la lista en background después del éxito
        _refreshPromociones();
        
        return true;
      } else {
        SnackbarHelper.error('Error', 'No se pudo actualizar la promoción');
        return false;
      }
    } catch (e) {
      SnackbarHelper.error('Error', 'Error al actualizar promoción: $e');
      return false;
    }
  }

  /// Elimina una promoción
  Future<bool> deletePromocion(String id) async {
    try {
      print('🔄 Eliminando promoción con ID: $id');
      
      final success = await promotionProvider.deletePromotion(id);
      
      if (success) {
        print('✅ Promoción eliminada exitosamente');
        
        SnackbarHelper.success('Éxito', 'Promoción eliminada correctamente');
        
        // Actualizar la lista en background después del éxito
        _refreshPromociones();
        
        return true;
      } else {
        SnackbarHelper.error('Error', 'No se pudo eliminar la promoción');
        return false;
      }
    } catch (e) {
      SnackbarHelper.error('Error', 'Error al eliminar promoción: $e');
      return false;
    }
  }

  /// Cambia el estado activo/inactivo de una promoción
  Future<void> togglePromotionStatus(String id, bool isActive) async {
    try {
      print('🔄 Cambiando estado de promoción: $id a $isActive');
      
      final success = await promotionProvider.togglePromotionStatus(id, isActive);
      
      if (success) {
        print('✅ Estado cambiado exitosamente');
        
        // Actualizar solo el elemento específico en la lista
        final index = promociones.indexWhere((p) => p.id == id);
        if (index != -1) {
          final updatedPromotion = promociones[index].copyWith(isActive: isActive);
          promociones[index] = updatedPromotion;
          print('📝 Elemento actualizado en la lista local');
        }
        
        SnackbarHelper.success('Éxito', 'Estado de promoción ${isActive ? "activado" : "desactivado"}');
      } else {
        SnackbarHelper.error('Error', 'No se pudo cambiar el estado de la promoción');
      }
    } catch (e) {
      print('❌ Error al cambiar estado: $e');
      SnackbarHelper.error('Error', 'Error al cambiar estado de promoción: $e');
    }
  }

  /// Configura el formulario para editar una promoción
  void setupFormForEdit(PromotionModel promocion) {
    nombreController.text = promocion.name;
    descripcionController.text = promocion.description ?? '';
    selectedDiscountType.value = promocion.discountType;
    discountValueController.text = promocion.discountValue.toString();
    minMonthsController.text = promocion.minMonths?.toString() ?? '1';
    maxUsesController.text = promocion.maxUses?.toString() ?? '';
    selectedAppliesTo.assignAll(promocion.appliesTo);
    selectedMembershipTypes.assignAll(promocion.membershipTypes);
    selectedDayOfWeek.value = promocion.dayOfWeek;
    timeStartController.text = promocion.timeStart ?? '';
    timeEndController.text = promocion.timeEnd ?? '';
    isActiveForm.value = promocion.isActive;
    conditionsController.text = promocion.conditions.isNotEmpty 
        ? jsonEncode(promocion.conditions) 
        : '';

    // Formatear fechas
    if (promocion.startDate != null) {
      startDateController.text = 
          '${promocion.startDate!.day.toString().padLeft(2, '0')}/'
          '${promocion.startDate!.month.toString().padLeft(2, '0')}/'
          '${promocion.startDate!.year}';
    } else {
      startDateController.clear();
    }

    if (promocion.endDate != null) {
      endDateController.text = 
          '${promocion.endDate!.day.toString().padLeft(2, '0')}/'
          '${promocion.endDate!.month.toString().padLeft(2, '0')}/'
          '${promocion.endDate!.year}';
    } else {
      endDateController.clear();
    }
  }

  /// Limpia el formulario
  void clearForm() {
    nombreController.clear();
    descripcionController.clear();
    selectedDiscountType.value = 'percentage';
    discountValueController.text = '0';
    minMonthsController.text = '1';
    maxUsesController.clear();
    selectedAppliesTo.clear();
    selectedMembershipTypes.clear();
    selectedDayOfWeek.value = null;
    timeStartController.clear();
    timeEndController.clear();
    startDateController.clear();
    endDateController.clear();
    isActiveForm.value = true;
    conditionsController.clear();
  }

  /// Valida el formulario
  bool validateForm() {
    if (nombreController.text.trim().isEmpty) {
      SnackbarHelper.error('Error', 'El nombre de la promoción es requerido');
      return false;
    }

    if (double.tryParse(discountValueController.text) == null) {
      SnackbarHelper.error('Error', 'El valor del descuento debe ser un número válido');
      return false;
    }

    if (selectedAppliesTo.isEmpty) {
      SnackbarHelper.error('Error', 'Debe seleccionar a qué aplica la promoción');
      return false;
    }

    return true;
  }

  /// Crea un modelo de promoción desde el formulario
  PromotionModel createPromotionFromForm() {
    // Parsear fechas
    DateTime? startDate;
    DateTime? endDate;

    if (startDateController.text.isNotEmpty) {
      final parts = startDateController.text.split('/');
      if (parts.length == 3) {
        startDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    }

    if (endDateController.text.isNotEmpty) {
      final parts = endDateController.text.split('/');
      if (parts.length == 3) {
        endDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    }

    // Parsear condiciones JSON
    Map<String, dynamic> conditions = {};
    if (conditionsController.text.isNotEmpty) {
      try {
        conditions = jsonDecode(conditionsController.text);
      } catch (e) {
        // Si falla el JSON, guardar como texto simple
        conditions = {'text': conditionsController.text};
      }
    }

    return PromotionModel(
      name: nombreController.text.trim(),
      description: descripcionController.text.trim().isEmpty 
          ? null 
          : descripcionController.text.trim(),
      discountType: selectedDiscountType.value,
      discountValue: double.parse(discountValueController.text),
      minMonths: int.tryParse(minMonthsController.text),
      startDate: startDate,
      endDate: endDate,
      isActive: isActiveForm.value,
      appliesTo: List<String>.from(selectedAppliesTo),
      dayOfWeek: selectedDayOfWeek.value,
      timeStart: timeStartController.text.isEmpty ? null : timeStartController.text,
      timeEnd: timeEndController.text.isEmpty ? null : timeEndController.text,
      membershipTypes: List<String>.from(selectedMembershipTypes),
      maxUses: int.tryParse(maxUsesController.text),
      conditions: conditions,
    );
  }

  /// Obtiene la descripción del tipo de descuento
  String getDiscountTypeDescription(String type) {
    switch (type) {
      case 'percentage':
        return 'Porcentaje';
      case 'fixed_amount':
        return 'Cantidad fija';
      case 'free_registration':
        return 'Registro gratuito';
      case 'free_membership':
        return 'Membresía gratuita';
      default:
        return 'Desconocido';
    }
  }

  /// Obtiene promociones válidas para un contexto específico
  Future<List<PromotionModel>> getValidPromotionsFor({
    required String appliesTo,
    String? membershipType,
  }) async {
    try {
      return await promotionProvider.getValidPromotions(
        appliesTo: appliesTo,
        membershipType: membershipType,
      );
    } catch (e) {
      return [];
    }
  }

  /// Calcula el mejor descuento disponible
  Future<Map<String, dynamic>> calculateBestDiscount({
    required String appliesTo,
    required double amount,
    String? membershipType,
  }) async {
    try {
      return await promotionProvider.calculateBestDiscount(
        appliesTo: appliesTo,
        amount: amount,
        membershipType: membershipType,
      );
    } catch (e) {
      return {
        'promotion': null,
        'discount': 0.0,
        'finalAmount': amount,
      };
    }
  }
}
