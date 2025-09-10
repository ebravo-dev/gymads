import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/configuracion_controller.dart';

class RfidSettingsView extends GetView<ConfiguracionController> {
  const RfidSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Configuración ESP32 RFID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
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
            // Estado de conexión ESP32
            _buildConnectionStatus(),
            
            const SizedBox(height: 24),
            
            // Estado Bluetooth
            _buildBluetoothStatus(),
            
            const SizedBox(height: 24),
            
            // Configuración WiFi
            _buildWiFiConfiguration(),
            
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionStatus() {
    return Obx(() {
      final isConnected = controller.rfidConnectionStatus.value;
      final statusMessage = controller.connectionStatusMessage.value;
      final ipAddress = controller.esp32IpAddress.value;
      
      return Card(
        elevation: 4,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.cardBackground,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  ),
                  child: Icon(
                    isConnected ? Icons.check_circle : Icons.warning,
                    color: isConnected ? AppColors.success : AppColors.warning,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isConnected ? 'ESP32 Conectado' : 'ESP32 No Configurado',
                  style: TextStyle(
                    color: isConnected ? AppColors.success : AppColors.warning,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusMessage,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (ipAddress.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Text(
                      'IP: $ipAddress',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
  
  Widget _buildBluetoothStatus() {
    return Obx(() {
      final bluetoothEnabled = controller.bluetoothEnabled.value;
      final bluetoothConnected = controller.bluetoothConnected.value;
      final statusMessage = controller.bluetoothStatusMessage.value;
      
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
                      color: bluetoothEnabled 
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      bluetoothConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      color: bluetoothEnabled ? AppColors.info : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado Bluetooth',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusMessage,
                          style: TextStyle(
                            color: bluetoothEnabled ? AppColors.textSecondary : AppColors.warning,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Botones Bluetooth
              Row(
                children: [
                  if (!bluetoothConnected && bluetoothEnabled) ...[
                    Expanded(
                      child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isScanning.value 
                          ? null 
                          : controller.scanForESP32Devices,
                        icon: controller.isScanning.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search),
                        label: Text(
                          controller.isScanning.value ? 'Buscando...' : 'Buscar ESP32',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )),
                    ),
                  ] else if (bluetoothConnected) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: controller.disconnectBluetooth,
                        icon: const Icon(Icons.bluetooth_disabled),
                        label: const Text('Desconectar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.snackbar(
                            'Bluetooth',
                            'Habilita Bluetooth en configuración del sistema',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.warning,
                            colorText: Colors.white,
                          );
                        },
                        icon: const Icon(Icons.bluetooth_disabled),
                        label: const Text('Bluetooth Deshabilitado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textSecondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildWiFiConfiguration() {
    return Obx(() {
      final isConnected = controller.rfidConnectionStatus.value;
      final bluetoothConnected = controller.bluetoothConnected.value;
      
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
                      color: isConnected 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? AppColors.success : AppColors.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Configuración WiFi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Estado WiFi actual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isConnected 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected 
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.warning,
                      color: isConnected ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConnected 
                          ? 'ESP32 conectado a WiFi correctamente'
                          : 'ESP32 no está conectado a WiFi',
                        style: TextStyle(
                          color: isConnected ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botones de configuración WiFi
              if (bluetoothConnected) ...[
                Row(
                  children: [
                    Expanded(
                      child: Obx(() => ElevatedButton.icon(
                        onPressed: controller.isConnectingWifi.value 
                          ? null 
                          : (isConnected ? controller.changeWiFiNetwork : controller.scanWiFiNetworks),
                        icon: controller.isConnectingWifi.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.wifi_find),
                        label: Text(
                          controller.isConnectingWifi.value 
                            ? 'Configurando...' 
                            : (isConnected ? 'Cambiar WiFi' : 'Configurar WiFi'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: controller.resetWiFiConfiguration,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppColors.info),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Conecta via Bluetooth para configurar WiFi',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botón de verificar conexión
        SizedBox(
          width: double.infinity,
          child: Obx(() => ElevatedButton.icon(
            onPressed: controller.isLoading.value 
              ? null 
              : controller.testRfidConnection,
            icon: controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh),
            label: Text(
              controller.isLoading.value 
                ? 'Verificando...' 
                : 'Verificar Conexión RFID',
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
        
        const SizedBox(height: 16),
        
        // Información sobre nueva configuración
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bluetooth, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Nueva Configuración Bluetooth',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'El ESP32 ahora se configura via Bluetooth, '
                      'eliminando problemas de IP dinámica. '
                      'Conecta via Bluetooth y configura WiFi directamente.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
