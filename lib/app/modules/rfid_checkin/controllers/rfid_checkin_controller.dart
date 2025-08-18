import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/rfid_reader_service.dart';
import '../../../data/services/audio_service.dart';
import '../../../data/config/rfid_config.dart';

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
    
    // Inicializar el controlador de animación con configuración óptima para visibilidad
    animationController = AnimationController(
      vsync: this,
      // Duración más corta para ondas más dinámicas y visibles
      duration: const Duration(milliseconds: 2000),
      // Empezar con un valor seguro
      value: 0.0,
    );
    
    // Añadimos un pequeño retraso para asegurar que la UI esté completamente cargada
    Future.delayed(const Duration(milliseconds: 100), () {
      // Iniciar animación con forward y repeat para evitar problemas de inicialización
      animationController.forward(from: 0.0);
      animationController.repeat();
    });
    
    // Iniciar verificación periódica de RFID
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
      
      String membershipStatus;
      
      if (user == null) {
        // Usuario no encontrado
        membershipStatus = RfidConfig.membershipNotFound;
        errorMessage.value = 'Tarjeta RFID no registrada';
        AudioService.playErrorSound();
      } else if (!user.isActive || user.daysRemaining <= 0) {
        // Membresía expirada o inactiva
        membershipStatus = RfidConfig.membershipExpired;
        errorMessage.value = user.daysRemaining <= 0 ? 'Membresía vencida' : 'Membresía inactiva';
        AudioService.playErrorSound();
      } else if (user.daysRemaining <= RfidConfig.expiringWarningDays) {
        // Membresía por vencer
        membershipStatus = RfidConfig.membershipExpiring;
        
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
        
        successMessage.value = '¡Bienvenido(a)! Tu membresía vence pronto';
        AudioService.playWelcomeSound();
        isShowingDialog.value = true;
      } else {
        // Membresía activa
        membershipStatus = RfidConfig.membershipActive;
        
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
        
        successMessage.value = '¡Bienvenido(a)!';
        AudioService.playWelcomeSound();
        isShowingDialog.value = true;
      }
      
      // Enviar estado de membresía al ESP32 para control de LEDs
      await RfidReaderService.sendMembershipStatus(rfidCode, membershipStatus);
      
      // Si el acceso fue exitoso, mostrar diálogo y cerrarlo después de 3 segundos
      if (membershipStatus == RfidConfig.membershipActive || membershipStatus == RfidConfig.membershipExpiring) {
        // Limpiar el campo de RFID después de un acceso exitoso
        rfidTextController.clear();
        rfidInput.value = '';
        
        // Cerrar la pantalla de bienvenida después de 3 segundos
        await Future.delayed(const Duration(seconds: 3));
        isShowingDialog.value = false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error al procesar acceso con RFID: $e');
      }
      errorMessage.value = 'Error al procesar el acceso: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Obtener la dirección IP actual del lector RFID
  String getReaderIpAddress() {
    final baseUrl = RfidConfig.baseUrl;
    // Extraer solo la dirección IP del formato http://192.168.1.x/api
    if (baseUrl.contains('://') && baseUrl.contains('/api')) {
      final parts = baseUrl.split('://');
      if (parts.length > 1) {
        final hostParts = parts[1].split('/');
        return hostParts[0]; // Retorna solo la parte del IP o hostname
      }
    }
    return baseUrl; // Si no se puede extraer, retornar la URL completa
  }
  
  // Actualizar la dirección IP del lector RFID
  void updateReaderIpAddress(String newIp) {
    if (newIp.isEmpty) return;
    
    // Validar y formatear la IP
    String formattedIp = newIp.trim();
    
    // Asegurarse de que tiene el formato correcto (http://IP/api)
    if (!formattedIp.startsWith('http://') && !formattedIp.startsWith('https://')) {
      formattedIp = 'http://$formattedIp';
    }
    
    // Añadir /api si no lo tiene
    if (!formattedIp.endsWith('/api')) {
      // Eliminar barra final si existe
      if (formattedIp.endsWith('/')) {
        formattedIp = formattedIp.substring(0, formattedIp.length - 1);
      }
      formattedIp = '$formattedIp/api';
    }
    
    // Actualizar la configuración
    RfidConfig.updateConfig(newUrl: formattedIp);
    
    if (kDebugMode) {
      print('Dirección IP del lector RFID actualizada a: $formattedIp');
    }
    
    // Reiniciar el timer para usar la nueva IP
    _rfidCheckTimer?.cancel();
    startRfidChecking();
  }
}
