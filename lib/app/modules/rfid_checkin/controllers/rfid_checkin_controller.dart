import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';

class RfidCheckinController extends GetxController {
  final UserRepository userRepository;

  RfidCheckinController({required this.userRepository});

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;
  final rfidInput = ''.obs;
  
  // Datos del usuario
  final isShowingDialog = false.obs;
  final userName = ''.obs;
  final daysLeft = 0.obs;
  final userPhotoUrl = ''.obs;
  final membershipType = ''.obs;

  // Controlador para el campo de entrada RFID
  final TextEditingController rfidTextController = TextEditingController();
  
  @override
  void onClose() {
    rfidTextController.dispose();
    super.onClose();
  }

  // Método para verificar el acceso mediante RFID
  Future<void> checkAccessByRfid(String rfidCode) async {
    if (isLoading.value || rfidCode.isEmpty) return;
    
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    
    try {
      if (kDebugMode) {
        print('Verificando acceso con RFID: $rfidCode');
      }
      
      // Obtener todos los usuarios y filtrar por RFID
      final List<UserModel> allUsers = await userRepository.getAllUsers();
      final UserModel? user = allUsers.firstWhereOrNull(
        (user) => user.rfidCard == rfidCode
      );
      
      if (user == null) {
        errorMessage.value = 'Tarjeta RFID no registrada';
        isLoading.value = false;
        return;
      }
      
      // Verificar si la membresía está activa
      if (!user.isActive) {
        errorMessage.value = 'Membresía inactiva';
        isLoading.value = false;
        return;
      }
      
      // Verificar si la membresía no ha expirado
      if (user.daysRemaining <= 0) {
        errorMessage.value = 'Membresía vencida';
        isLoading.value = false;
        return;
      }
      
      // Actualizar datos para mostrar
      userName.value = user.name;
      daysLeft.value = user.daysRemaining;
      userPhotoUrl.value = user.photoUrl ?? '';
      membershipType.value = user.membershipType;
      
      // Registrar el acceso
      final updatedUser = user.addAccessRecord();
      if (user.id != null) {
        await userRepository.updateUser(user.id!, updatedUser);
      }
      
      // Mostrar mensaje de éxito
      successMessage.value = '¡Acceso registrado!';
      isShowingDialog.value = true;
      
      // Limpiar el campo de RFID después de un acceso exitoso
      rfidTextController.clear();
      rfidInput.value = '';
      
      // Cerrar el diálogo después de 4 segundos
      await Future.delayed(const Duration(seconds: 4));
      isShowingDialog.value = false;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error al procesar acceso con RFID: $e');
      }
      errorMessage.value = 'Error al procesar el acceso: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
