import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/background_rfid_service.dart';
import '../../shared/widgets/welcome_screen_widget.dart';

/// Widget que muestra el diálogo de bienvenida cuando se escanea en el home
class BackgroundWelcomeDialog extends StatelessWidget {
  const BackgroundWelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificar si el servicio está disponible
    if (!Get.isRegistered<BackgroundRfidService>()) {
      return const SizedBox.shrink();
    }
    
    try {
      final service = Get.find<BackgroundRfidService>();
      
      return Obx(() {
        if (!service.showWelcomeDialog.value || service.currentUser.value == null) {
          return const SizedBox.shrink();
        }
        
        final user = service.currentUser.value!;
        
        return WelcomeScreenWidget(
          userName: user.name,
          userPhotoUrl: user.photoUrl ?? '',
          membershipType: user.membershipType,
          daysLeft: user.daysRemaining,
          isVisible: service.showWelcomeDialog.value,
        );
      });
    } catch (e) {
      // Servicio no disponible
      return const SizedBox.shrink();
    }
  }
}
