import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/membership_type_model.dart';
import '../../../data/providers/membership_type_provider.dart';

class MembresiasController extends GetxController {
  final MembershipTypeProvider membershipProvider;
  
  MembresiasController({required this.membershipProvider});
  
  // Estados observables
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxList<MembershipTypeModel> memberships = <MembershipTypeModel>[].obs;
  final RxString errorMessage = ''.obs;
  final RxBool showInactive = false.obs;
  
  // Controladores para el formulario
  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController durationDaysController = TextEditingController();
  final RxBool isActiveChecked = true.obs;
  
  // Membresía seleccionada actualmente (para editar)
  final Rx<MembershipTypeModel?> selectedMembership = Rx<MembershipTypeModel?>(null);
  
  @override
  void onInit() {
    super.onInit();
    fetchMemberships();
  }
  
  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    durationDaysController.dispose();
    super.onClose();
  }
  
  // Obtener todos los tipos de membresía
  Future<void> fetchMemberships() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final List<MembershipTypeModel> result = await membershipProvider.getMembershipTypes();
      memberships.value = result;
    } catch (e) {
      errorMessage.value = 'Error al cargar tipos de membresía: $e';
      print(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }
  
  // Filtrar membresías según showInactive
  List<MembershipTypeModel> get filteredMemberships {
    if (showInactive.value) {
      return memberships;
    } else {
      return memberships.where((m) => m.isActive).toList();
    }
  }
  
  // Limpiar el formulario
  void clearForm() {
    formKey.currentState?.reset();
    nameController.clear();
    descriptionController.clear();
    priceController.clear();
    durationDaysController.text = '30';
    isActiveChecked.value = true;
    selectedMembership.value = null;
    errorMessage.value = '';
  }
  
  // Configurar el formulario para editar
  void setupFormForEdit(MembershipTypeModel membership) {
    nameController.text = membership.name;
    descriptionController.text = membership.description;
    priceController.text = membership.price.toString();
    durationDaysController.text = membership.durationDays.toString();
    isActiveChecked.value = membership.isActive;
    selectedMembership.value = membership;
  }
  
  // Crear un nuevo tipo de membresía
  Future<bool> createMembership() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    
    isSaving.value = true;
    errorMessage.value = '';
    
    try {
      final newMembership = MembershipTypeModel(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text.trim()),
        durationDays: int.parse(durationDaysController.text.trim()),
        isActive: isActiveChecked.value,
      );
      
      final createdMembership = await membershipProvider.createMembershipType(newMembership);
      if (createdMembership != null) {
        memberships.add(createdMembership);
        clearForm();
        Get.back();
        Get.snackbar(
          'Éxito',
          'Tipo de membresía creado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        throw Exception('No se pudo crear el tipo de membresía');
      }
    } catch (e) {
      errorMessage.value = 'Error al crear tipo de membresía: $e';
      print(errorMessage.value);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
  
  // Actualizar un tipo de membresía existente
  Future<bool> updateMembership() async {
    if (selectedMembership.value == null || !formKey.currentState!.validate()) {
      return false;
    }
    
    isSaving.value = true;
    errorMessage.value = '';
    
    try {
      final updatedMembership = selectedMembership.value!.copyWith(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text.trim()),
        durationDays: int.parse(durationDaysController.text.trim()),
        isActive: isActiveChecked.value,
      );
      
      final result = await membershipProvider.updateMembershipType(updatedMembership);
      if (result != null) {
        // Actualizar en la lista local
        final index = memberships.indexWhere((m) => m.id == result.id);
        if (index >= 0) {
          memberships[index] = result;
        }
        
        clearForm();
        Get.back();
        Get.snackbar(
          'Éxito',
          'Tipo de membresía actualizado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        throw Exception('No se pudo actualizar el tipo de membresía');
      }
    } catch (e) {
      errorMessage.value = 'Error al actualizar tipo de membresía: $e';
      print(errorMessage.value);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
  
  // Activar/desactivar un tipo de membresía
  Future<bool> toggleMembershipStatus(MembershipTypeModel membership) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      if (membership.id == null) {
        throw Exception('No se puede cambiar el estado de un tipo de membresía sin ID');
      }
      
      final success = await membershipProvider.toggleMembershipTypeStatus(
        membership.id!,
        !membership.isActive,
      );
      
      if (success) {
        // Actualizar en la lista local
        final index = memberships.indexWhere((m) => m.id == membership.id);
        if (index >= 0) {
          memberships[index] = membership.copyWith(isActive: !membership.isActive);
        }
        
        Get.snackbar(
          'Éxito',
          membership.isActive 
              ? 'Tipo de membresía desactivado correctamente' 
              : 'Tipo de membresía activado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        throw Exception('No se pudo cambiar el estado del tipo de membresía');
      }
    } catch (e) {
      errorMessage.value = 'Error al cambiar estado del tipo de membresía: $e';
      print(errorMessage.value);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Eliminar un tipo de membresía
  Future<bool> deleteMembership(String id) async {
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final success = await membershipProvider.deleteMembershipType(id);
      
      if (success) {
        // Eliminar de la lista local
        memberships.removeWhere((m) => m.id == id);
        
        Get.snackbar(
          'Éxito',
          'Tipo de membresía eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        throw Exception('No se pudo eliminar el tipo de membresía');
      }
    } catch (e) {
      errorMessage.value = 'Error al eliminar tipo de membresía: $e';
      print(errorMessage.value);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Formatear el precio para mostrar
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }
}
