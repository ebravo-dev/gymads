import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import 'package:flutter/foundation.dart';

class ChecadorController extends GetxController {
  final UserRepository userRepository;

  ChecadorController({required this.userRepository});

  final isShowingDialog = false.obs;
  final userName = ''.obs;
  final daysLeft = 0.obs;
  final userPhotoUrl = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<void> onDetect(BarcodeCapture capture) async {
    if (isShowingDialog.value || isLoading.value) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      String? userNumber = barcode.rawValue?.trim();
      if (userNumber == null || userNumber.isEmpty) continue;

      if (kDebugMode) {
        print('Escaneando userNumber: |$userNumber|');
      }

      isLoading.value = true;
      errorMessage.value = '';

      try {
        final UserModel? user = await userRepository.getUserByNumber(
          userNumber,
        );

        if (user == null) {
          errorMessage.value = 'Usuario no encontrado';
          continue;
        }

        // Verificar si la membresía está activa
        if (!user.isActive) {
          errorMessage.value = 'Membresía inactiva';
          continue;
        }

        // Verificar si la membresía no ha expirado
        if (user.daysRemaining <= 0) {
          errorMessage.value = 'Membresía vencida';
          continue;
        }

        // Actualizar datos para mostrar
        userName.value = user.name;
        daysLeft.value = user.daysRemaining;
        userPhotoUrl.value = user.photoUrl ?? '';

        // Registrar el acceso
        final updatedUser = user.addAccessRecord();
        if (user.id != null) {
          await userRepository.updateUser(user.id!, updatedUser);
        }

        // Mostrar el diálogo
        isShowingDialog.value = true;

        // Cerrar el diálogo después de 4 segundos
        await Future.delayed(const Duration(seconds: 4));
        isShowingDialog.value = false;
      } catch (e) {
        if (kDebugMode) {
          print('Error al procesar el acceso: $e');
        }
        errorMessage.value = 'Error al procesar el acceso';
      } finally {
        isLoading.value = false;
      }
    }
  }
}
