import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/checador_controller.dart';

class ChecadorView extends GetView<ChecadorController> {
  const ChecadorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Acceso'), centerTitle: true),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.front,
              torchEnabled: false,
            ),
            onDetect: controller.onDetect,
          ),

          // Mensaje guía
          Positioned(
            bottom: 24,
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

          // Información del usuario
          Obx(
            () =>
                controller.isShowingDialog.value
                    ? _buildUserInfoOverlay()
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.userPhotoUrl.value.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.network(
                    controller.userPhotoUrl.value,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 100),
                  ),
                )
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              Text(
                controller.userName.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Días restantes: ${controller.daysLeft}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
