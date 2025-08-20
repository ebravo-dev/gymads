import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/configuracion_controller.dart';

class WiFiSetupView extends GetView<ConfiguracionController> {
  const WiFiSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Configuración WiFi ESP32',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.titleColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instrucciones
            _buildInstructions(),
            
            const SizedBox(height: 24),
            
            // Estado de conexión
            _buildConnectionStatus(),
            
            const SizedBox(height: 24),
            
            // Lista de redes WiFi
            _buildNetworksList(),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructions() {
    return Card(
      elevation: 4,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Instrucciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            const Text(
              '1. Asegúrate de que el ESP32 esté encendido',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '2. Si no está conectado a WiFi, el ESP32 creará una red llamada "ESP_RFID_Setup"',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '3. Conéctate a esa red con la contraseña: gymads123',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '4. Vuelve a la app y usa este menú para configurar el WiFi',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionStatus() {
    return Obx(() => Card(
      elevation: 4,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: controller.wifiSetupMode.value 
                  ? AppColors.warning.withOpacity(0.2)
                  : controller.rfidConnectionStatus.value 
                    ? AppColors.success.withOpacity(0.2)
                    : AppColors.error.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                controller.wifiSetupMode.value 
                  ? Icons.settings_ethernet
                  : controller.rfidConnectionStatus.value 
                    ? Icons.wifi
                    : Icons.wifi_off,
                size: 40,
                color: controller.wifiSetupMode.value 
                  ? AppColors.warning
                  : controller.rfidConnectionStatus.value 
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.wifiSetupMode.value 
                ? 'Modo Configuración Activo'
                : controller.rfidConnectionStatus.value 
                  ? 'ESP32 Conectado a WiFi'
                  : 'ESP32 Desconectado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: controller.wifiSetupMode.value 
                  ? AppColors.warning
                  : controller.rfidConnectionStatus.value 
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.wifiSetupMode.value 
                ? 'Conectado a ESP_RFID_Setup - IP: 192.168.4.1'
                : controller.rfidConnectionStatus.value 
                  ? 'Configuración completada exitosamente'
                  : 'Conecta a la red ESP_RFID_Setup para configurar',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ));
  }
  
  Widget _buildNetworksList() {
    return Obx(() => Card(
      elevation: 4,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.titleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.wifi,
                    color: AppColors.titleColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Redes WiFi Disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.scanWiFiNetworks,
                  icon: controller.isScanning.value 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.titleColor,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: AppColors.titleColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lista de redes
            if (controller.availableNetworks.isEmpty && !controller.isScanning.value)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.containerBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: AppColors.textHint),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No hay redes disponibles. Asegúrate de estar conectado a ESP_RFID_Setup',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (controller.isScanning.value)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.titleColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Escaneando redes WiFi...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.availableNetworks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final network = controller.availableNetworks[index];
                  return _buildNetworkTile(network);
                },
              ),
          ],
        ),
      ),
    ));
  }
  
  Widget _buildNetworkTile(Map<String, dynamic> network) {
    final String ssid = network['ssid'] ?? '';
    final int rssi = network['rssi'] ?? -100;
    final bool secure = network['secure'] ?? false;
    
    // Calcular la fuerza de la señal
    int signalStrength = 0;
    if (rssi > -50) signalStrength = 4;
    else if (rssi > -60) signalStrength = 3;
    else if (rssi > -70) signalStrength = 2;
    else if (rssi > -80) signalStrength = 1;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.containerBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Icon(
          secure ? Icons.wifi_lock : Icons.wifi,
          color: AppColors.textSecondary,
        ),
        title: Text(
          ssid,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${secure ? 'Segura' : 'Abierta'} • Señal: ${'●' * signalStrength}${'○' * (4 - signalStrength)}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: () => controller.selectNetwork(network),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón de escanear redes
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isScanning.value 
              ? null 
              : controller.scanWiFiNetworks,
            icon: controller.isScanning.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.wifi_find),
            label: Text(
              controller.isScanning.value 
                ? 'Escaneando...' 
                : 'Escanear Redes WiFi',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          )),
        ),
        
        const SizedBox(height: 12),
        
        // Botón de resetear configuración
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.resetWiFiConfiguration,
            icon: const Icon(Icons.restore),
            label: const Text(
              'Resetear Configuración WiFi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }
}
