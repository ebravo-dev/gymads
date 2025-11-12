import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/checador_controller.dart';
import '../../shared/widgets/welcome_screen_widget.dart';

class ChecadorView extends GetView<ChecadorController> {
  const ChecadorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Acceso'), centerTitle: true),
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.normal,
                facing: CameraFacing.back,
                torchEnabled: false,
              ),
              onDetect: controller.onDetect,
            ),

            // Mensaje guía
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(
                    () => Text(
                      controller.errorMessage.isEmpty
                          ? 'Escanea el código QR del usuario'
                          : controller.errorMessage.value,
                      style: TextStyle(
                        color:
                            controller.errorMessage.isEmpty
                                ? Colors.white
                                : Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Indicador de carga
          Obx(
            () =>
                controller.isLoading.value
                    ? Container(
                      color: Colors.black54,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                    : const SizedBox.shrink(),
          ),

          // Pantalla de bienvenida compartida
          Obx(
            () => WelcomeScreenWidget(
              userName: controller.userName.value,
              userPhotoUrl: controller.userPhotoUrl.value,
              membershipType: controller.membershipType.value,
              daysLeft: controller.daysLeft.value,
              isVisible: controller.isShowingDialog.value,
            ),
          ),
          ],
        ),
      ),
    );
  }
}
