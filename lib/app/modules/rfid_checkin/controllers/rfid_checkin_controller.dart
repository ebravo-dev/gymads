import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/rfid_reader_service.dart';

class RfidCheckinController extends GetxController with GetSingleTickerProviderStateMixin {
  final UserRepository userRepository;

  RfidCheckinController({required this.userRepository});
  
  // Controlador para las animaciones de onda
  late AnimationController animationController;

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
  
  // Timer para verificar periódicamente la tarjeta RFID
  Timer? _rfidCheckTimer;
  
  @override
  void onInit() {
    super.onInit();
    // Inicializar el controlador de animación
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    startRfidChecking();
  }
  
  void startRfidChecking() {
    _rfidCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!isShowingDialog.value && !isLoading.value) {
        final uid = await RfidReaderService.checkForCard();
        if (uid != null) {
          checkAccessByRfid(uid);
        }
      }
    });
  }

  // Controlador para el campo de entrada RFID
  final TextEditingController rfidTextController = TextEditingController();
  
  @override
  void onClose() {
    rfidTextController.dispose();
    _rfidCheckTimer?.cancel();
    animationController.dispose();
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
      
      // Mostrar mensaje de bienvenida personalizado
      successMessage.value = '¡Bienvenido(a)!';
      isShowingDialog.value = true;
      
      // Limpiar el campo de RFID después de un acceso exitoso
      rfidTextController.clear();
      rfidInput.value = '';
      
      // Reproducir sonido de bienvenida si lo deseas aquí
      
      // Cerrar la pantalla de bienvenida después de 3 segundos
      await Future.delayed(const Duration(seconds: 3));
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
