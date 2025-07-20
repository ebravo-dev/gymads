import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/rfid_checkin_controller.dart';
import 'package:gymads/core/theme/app_colors.dart';

class RfidCheckinView extends GetView<RfidCheckinController> {
  const RfidCheckinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso con Tarjeta RFID'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          _buildMainContent(),
          
          // Indicador de carga
          Obx(() => controller.isLoading.value
              ? Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink()),
          
          // Información del usuario cuando se detecta acceso
          Obx(() => controller.isShowingDialog.value
              ? _buildUserInfoOverlay()
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título e instrucciones
          const Text(
            'Control de Acceso RFID',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ingrese el código de la tarjeta RFID o acerque la tarjeta al lector',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Campo para ingresar el código RFID manualmente
          TextField(
            controller: controller.rfidTextController,
            decoration: InputDecoration(
              labelText: 'Código RFID',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.credit_card),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (controller.rfidTextController.text.isNotEmpty) {
                    controller.checkAccessByRfid(controller.rfidTextController.text);
                  }
                },
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                controller.checkAccessByRfid(value);
              }
            },
            autofocus: true,
          ),
          const SizedBox(height: 24),
          
          // Mensajes de error o éxito
          Obx(() => controller.errorMessage.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: Colors.red.shade800),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink()),
          
          Obx(() => controller.successMessage.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    controller.successMessage.value,
                    style: TextStyle(color: Colors.green.shade800),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink()),
          
          const Spacer(),
          
          // Botón para simular lectura de RFID (para pruebas)
          ElevatedButton.icon(
            onPressed: () {
              // Generar un código aleatorio para pruebas
              final random = List.generate(10, (_) => '${DateTime.now().millisecondsSinceEpoch}'.substring(10, 11)).join();
              controller.rfidTextController.text = random;
              controller.checkAccessByRfid(random);
            },
            icon: const Icon(Icons.contactless),
            label: const Text('Simular Lectura RFID'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoOverlay() {
    return GestureDetector(
      onTap: () {
        controller.isShowingDialog.value = false;
      },
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de éxito
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 16),
                
                // Foto del usuario si está disponible
                Obx(() => controller.userPhotoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          controller.userPhotoUrl.value,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, error, _) => const CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 50),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.accent.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.accent,
                        ),
                      )),
                const SizedBox(height: 16),
                
                // Información del usuario
                Text(
                  controller.userName.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Tipo de membresía
                Obx(() => Text(
                  'Membresía: ${controller.membershipType.value.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                )),
                const SizedBox(height: 8),
                
                // Días restantes
                Obx(() => Text(
                  'Días restantes: ${controller.daysLeft.value}',
                  style: TextStyle(
                    fontSize: 18,
                    color: controller.daysLeft.value <= 5
                        ? Colors.orange
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                const SizedBox(height: 24),
                
                // Mensaje
                Text(
                  controller.successMessage.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Mensaje de cierre
                const Text(
                  'Toca en cualquier lugar para cerrar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
