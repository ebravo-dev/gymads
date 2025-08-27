import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/audio_service.dart';
import 'package:flutter/foundation.dart';

class ChecadorController extends GetxController {
  final UserRepository userRepository;

  ChecadorController({required this.userRepository});

  final isShowingDialog = false.obs;
  final userName = ''.obs;
  final daysLeft = 0.obs;
  final userPhotoUrl = ''.obs;
  final membershipType = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> onDetect(BarcodeCapture capture) async {
    if (isShowingDialog.value || isLoading.value) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      String? userNumber = barcode.rawValue?.trim();
      if (userNumber == null || userNumber.isEmpty) continue;

      if (kDebugMode) {
        print('🔍 Escaneando userNumber: |$userNumber|');
      }

      isLoading.value = true;
      errorMessage.value = '';

      try {
        if (kDebugMode) {
          print('🔍 Buscando usuario en la base de datos...');
        }

        final UserModel? user = await userRepository.getUserByNumber(
          userNumber,
        );

        if (user == null) {
          if (kDebugMode) {
            print('❌ Usuario no encontrado para el número: $userNumber');
          }
          errorMessage.value = 'Usuario no registrado con número: $userNumber';
          // Reproducir sonido de error
          AudioService.playErrorSound();
          
          // Mantener el mensaje de error visible por 3 segundos
          await Future.delayed(const Duration(seconds: 3));
          errorMessage.value = '';
          continue;
        }

        if (kDebugMode) {
          print('✅ Usuario encontrado: ${user.name}');
          print('ℹ️ Estado activo: ${user.isActive}');
          print('ℹ️ Días restantes: ${user.daysRemaining}');
        }

        // Verificar si la membresía está activa
        if (!user.isActive) {
          if (kDebugMode) {
            print('⚠️ Membresía inactiva para usuario: ${user.name}');
          }
          errorMessage.value = 'Membresía inactiva para ${user.name}';
          // Reproducir sonido de error
          AudioService.playErrorSound();
          
          // Mantener el mensaje de error visible por 3 segundos
          await Future.delayed(const Duration(seconds: 3));
          errorMessage.value = '';
          continue;
        }

        // Verificar si la membresía no ha expirado
        if (user.daysRemaining <= 0) {
          if (kDebugMode) {
            print('⚠️ Membresía vencida para usuario: ${user.name}');
          }
          errorMessage.value = 'Membresía vencida para ${user.name}';
          // Reproducir sonido de error
          AudioService.playErrorSound();
          
          // Mantener el mensaje de error visible por 3 segundos
          await Future.delayed(const Duration(seconds: 3));
          errorMessage.value = '';
          continue;
        }

        if (kDebugMode) {
          print('✅ Acceso autorizado para: ${user.name}');
        }

        // Actualizar datos para mostrar
        userName.value = user.name;
        daysLeft.value = user.daysRemaining;
        userPhotoUrl.value = user.photoUrl ?? '';
        membershipType.value = user.membershipType;

        // Registrar el acceso
        try {
          final updatedUser = user.addAccessRecord();
          if (user.id != null) {
            await userRepository.updateUser(user.id!, updatedUser);
            if (kDebugMode) {
              print('✅ Registro de acceso guardado para: ${user.name}');
            }
          }
        } catch (accessError) {
          if (kDebugMode) {
            print('⚠️ Error al registrar el acceso: $accessError');
          }
          // No bloqueamos el acceso por un error de registro
        }

        // Reproducir sonido de bienvenida
        AudioService.playWelcomeSound();

        // Mostrar el diálogo
        isShowingDialog.value = true;

        // Cerrar el diálogo después de 4 segundos
        await Future.delayed(const Duration(seconds: 4));
        isShowingDialog.value = false;
        
        // Limpiar mensaje de error al completar exitosamente
        errorMessage.value = '';
        
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error al procesar el acceso: $e');
          print('❌ Stack trace: ${StackTrace.current}');
        }
        errorMessage.value = 'Error de conexión. Intenta de nuevo.';
        
        // Mantener el mensaje de error visible por 3 segundos
        await Future.delayed(const Duration(seconds: 3));
        errorMessage.value = '';
      } finally {
        isLoading.value = false;
      }
    }
  }
}
