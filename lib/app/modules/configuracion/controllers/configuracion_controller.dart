import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../data/config/rfid_config.dart';
import '../../../data/services/rfid_reader_service.dart';
import '../views/rfid_settings_view.dart';

class ConfiguracionController extends GetxController {
  // Variables observables para la configuración
  final RxBool isLoading = false.obs;
  
  // Variables para información de cuenta
  final RxString userName = 'Staff Usuario'.obs;
  final RxString userEmail = 'staff@gymads.com'.obs;
  final RxString userRole = 'Staff'.obs;
  
  // Variables para configuración del lector RFID
  final TextEditingController rfidIpController = TextEditingController();
  final RxString currentRfidIp = ''.obs;
  final RxBool rfidConnectionStatus = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Actualizar el índice de navegación cuando se inicialice la vista Configuración
    NavigationController.to.updateIndexFromRoute(Routes.CONFIGURACION);
    
    // Cargar configuración inicial
    loadInitialConfig();
  }

  @override
  void onReady() {
    super.onReady();
    // Verificar estado de conexión RFID
    checkRfidConnection();
  }

  @override
  void onClose() {
    rfidIpController.dispose();
    super.onClose();
  }
  
  // Cargar configuración inicial
  void loadInitialConfig() {
    // Cargar IP actual del lector RFID
    currentRfidIp.value = RfidConfig.baseUrl;
    rfidIpController.text = extractIpFromUrl(currentRfidIp.value);
    
    // TODO: Cargar información de usuario desde autenticación
    // Por ahora usamos datos estáticos
    userName.value = 'Staff Usuario';
    userEmail.value = 'staff@gymads.com';
    userRole.value = 'Staff';
  }
  
  // Extraer IP de la URL completa (ahora público)
  String extractIpFromUrl(String url) {
    try {
      if (url.contains('://') && url.contains('/api')) {
        final parts = url.split('://');
        if (parts.length > 1) {
          final hostParts = parts[1].split('/');
          return hostParts[0];
        }
      }
      return url;
    } catch (e) {
      return url;
    }
  }
  
  // Verificar conexión con el lector RFID
  Future<void> checkRfidConnection() async {
    try {
      isLoading.value = true;
      
      // Usar el servicio real de RFID para verificar la conexión
      final isConnected = await RfidReaderService.startReading();
      rfidConnectionStatus.value = isConnected;
      
    } catch (e) {
      rfidConnectionStatus.value = false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Actualizar IP del lector RFID
  Future<void> updateRfidIp() async {
    final newIp = rfidIpController.text.trim();
    
    if (newIp.isEmpty) {
      Get.snackbar(
        'Error',
        'La dirección IP no puede estar vacía',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isLoading.value = true;
      
      // Formatear la IP correctamente
      String formattedIp = newIp;
      if (!formattedIp.startsWith('http://') && !formattedIp.startsWith('https://')) {
        formattedIp = 'http://$formattedIp';
      }
      if (!formattedIp.endsWith('/api')) {
        if (formattedIp.endsWith('/')) {
          formattedIp = formattedIp.substring(0, formattedIp.length - 1);
        }
        formattedIp = '$formattedIp/api';
      }
      
      // Actualizar configuración
      RfidConfig.updateConfig(newUrl: formattedIp);
      currentRfidIp.value = formattedIp;
      
      // Verificar nueva conexión
      await checkRfidConnection();
      
      Get.snackbar(
        'Éxito',
        'Dirección IP del lector RFID actualizada',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al actualizar la IP: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Probar conexión RFID
  Future<void> testRfidConnection() async {
    await checkRfidConnection();
    
    if (rfidConnectionStatus.value) {
      Get.snackbar(
        'Conexión exitosa',
        'El lector RFID está funcionando correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error de conexión',
        'No se pudo conectar con el lector RFID. Verifica la IP y que el ESP32 esté encendido.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
  
  // Cerrar sesión
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implementar lógica de cierre de sesión
              Get.snackbar(
                'Sesión cerrada',
                'Has cerrado sesión correctamente',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Abrir configuración de cuenta
  void openAccountSettings() {
    Get.dialog(
      _buildAccountSettingsDialog(),
      barrierDismissible: true,
    );
  }
  
  // Abrir configuración de RFID
  void openRfidSettings() {
    Get.to(() => const RfidSettingsView());
  }
  
  // Abrir configuración de aplicación (futuro)
  void openAppSettings() {
    Get.snackbar(
      'Próximamente',
      'Esta función estará disponible en una futura actualización',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
  
  // Dialog para configuración de cuenta
  Widget _buildAccountSettingsDialog() {
    return AlertDialog(
      title: const Text('Información de Cuenta'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccountInfoRow(Icons.person, 'Usuario', userName.value),
            const SizedBox(height: 12),
            _buildAccountInfoRow(Icons.email, 'Email', userEmail.value),
            const SizedBox(height: 12),
            _buildAccountInfoRow(Icons.badge, 'Rol', userRole.value, Colors.blue[600]),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
  
  // Widget helper para información de cuenta
  Widget _buildAccountInfoRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.grey[800],
              fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
