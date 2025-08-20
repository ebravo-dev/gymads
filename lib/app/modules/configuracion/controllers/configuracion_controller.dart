import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../data/config/rfid_config.dart';
import '../../../data/services/rfid_reader_service.dart';
import '../views/rfid_settings_view.dart';
import '../views/wifi_setup_view.dart';

class ConfiguracionController extends GetxController {
  // Variables observables para la configuración
  final RxBool isLoading = false.obs;
  
  // Variables para información de cuenta
  final RxString userName = 'Staff Usuario'.obs;
  final RxString userEmail = 'staff@gymads.com'.obs;
  final RxString userRole = 'Staff'.obs;
  
  // Variables para configuración del lector RFID (sin mostrar IP al usuario)
  final RxBool rfidConnectionStatus = false.obs;
  final RxString connectionStatusMessage = 'Verificando conexión...'.obs;
  
  // Variables para configuración WiFi
  final RxBool wifiSetupMode = false.obs;
  final RxBool isScanning = false.obs;
  final RxList<Map<String, dynamic>> availableNetworks = <Map<String, dynamic>>[].obs;
  final RxString selectedNetwork = ''.obs;
  final TextEditingController wifiPasswordController = TextEditingController();

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
    wifiPasswordController.dispose();
    super.onClose();
  }
  
  // Cargar configuración inicial
  Future<void> loadInitialConfig() async {
    // Cargar configuración RFID desde SharedPreferences
    await RfidConfig.loadConfig();
    
    // TODO: Cargar información de usuario desde autenticación
    // Por ahora usamos datos estáticos
    userName.value = 'Staff Usuario';
    userEmail.value = 'staff@gymads.com';
    userRole.value = 'Staff';
    
    // Verificar estado inicial de conexión
    connectionStatusMessage.value = 'Buscando dispositivo ESP32...';
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
      connectionStatusMessage.value = 'Verificando conexión con ESP32...';
      
      // Usar el servicio real de RFID para verificar la conexión
      final isConnected = await RfidReaderService.startReading();
      rfidConnectionStatus.value = isConnected;
      
      if (isConnected) {
        connectionStatusMessage.value = 'ESP32 conectado y funcionando';
        wifiSetupMode.value = false; // Ya no está en modo setup
      } else {
        connectionStatusMessage.value = 'ESP32 no conectado - Configura WiFi';
        wifiSetupMode.value = true; // Necesita configuración
        // Verificar si está en modo setup
        await checkIfInSetupMode();
      }
      
    } catch (e) {
      rfidConnectionStatus.value = false;
      wifiSetupMode.value = true;
      connectionStatusMessage.value = 'ESP32 no encontrado - Verifica configuración';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Verificar si el ESP32 está en modo setup
  Future<void> checkIfInSetupMode() async {
    try {
      const String espSetupIp = 'http://192.168.4.1';
      final response = await http.get(
        Uri.parse('$espSetupIp/api/wifi/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'setup_mode') {
          wifiSetupMode.value = true;
          connectionStatusMessage.value = 'ESP32 en modo configuración - Listo para WiFi';
        }
      }
    } catch (e) {
      // No está en modo setup o no podemos conectar
    }
  }
  
  // Probar conexión RFID con detección automática
  Future<void> testRfidConnection() async {
    isLoading.value = true;
    
    try {
      // Cargar configuración (esto incluye detección automática)
      await RfidConfig.loadConfig();
      
      // Verificar conexión
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
          'Dispositivo no encontrado',
          'El ESP32 puede estar en modo configuración WiFi. Usa "Configurar WiFi" si es necesario.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  // Detectar automáticamente la IP del Arduino cuando se conecte a WiFi
  Future<void> detectArduinoIP() async {
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Detectando nueva configuración...';
      
      // Cuando el ESP32 se conecta a WiFi, obtiene una nueva IP
      // Podemos intentar obtener esta IP del ESP32 mismo
      const String espIp = 'http://192.168.4.1';
      final response = await http.get(
        Uri.parse('$espIp/api/wifi/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'connected' && data['ip'] != null) {
          String newIp = data['ip'];
          String newUrl = 'http://$newIp/api';
          
          // Actualizar la configuración con la nueva IP
          await RfidConfig.updateConfig(newUrl: newUrl);
          
          Get.snackbar(
            'Configuración Actualizada',
            'El ESP32 se ha conectado exitosamente a WiFi',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          
          // Verificar conexión con la nueva IP
          await checkRfidConnection();
        }
      }
    } catch (e) {
      // No hacer nada si no se puede detectar, la IP se configurará manualmente
      print('No se pudo detectar IP automáticamente: $e');
      connectionStatusMessage.value = 'Configuración automática no disponible';
    } finally {
      isLoading.value = false;
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
  
  // Abrir configuración WiFi
  void openWiFiSetup() {
    // Mostrar diálogo explicativo tipo Echo Dot
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_protected_setup, color: Colors.blue[600]),
            const SizedBox(width: 12),
            const Expanded(child: Text('Configurar WiFi ESP32')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para configurar el WiFi del ESP32, necesitas seguir estos pasos:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildSetupStep(1, 'Desconéctate de tu WiFi actual'),
            _buildSetupStep(2, 'Conecta a la red "ESP_RFID_Setup"'),
            _buildSetupStep(3, 'Contraseña: "gymads123"'),
            _buildSetupStep(4, 'Regresa a la app para completar'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Igual que configurar un Echo Dot o dispositivo inteligente',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(() => const WiFiSetupView());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
            child: const Text('Continuar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSetupStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  // Escanear redes WiFi disponibles
  Future<void> scanWiFiNetworks() async {
    try {
      isScanning.value = true;
      availableNetworks.clear();
      
      // Endpoint del ESP32 para escanear redes
      const String espIp = 'http://192.168.4.1';
      final response = await http.get(
        Uri.parse('$espIp/api/wifi/scan'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] ?? 'unknown';
        
        if (status == 'success' || status == 'no_networks') {
          List<dynamic> networks = data['networks'] ?? [];
          
          // Filtrar y formatear redes
          List<Map<String, dynamic>> formattedNetworks = [];
          for (var network in networks) {
            if (network['ssid'] != null && network['ssid'].toString().isNotEmpty) {
              formattedNetworks.add({
                'ssid': network['ssid'].toString(),
                'rssi': network['rssi'] ?? -100,
                'secure': network['secure'] ?? false,
              });
            }
          }
          
          // Ordenar por fuerza de señal
          formattedNetworks.sort((a, b) => (b['rssi'] as int).compareTo(a['rssi'] as int));
          
          availableNetworks.value = formattedNetworks;
          
          if (availableNetworks.isNotEmpty) {
            Get.snackbar(
              'Escaneo completo',
              'Se encontraron ${availableNetworks.length} redes WiFi',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              'Sin redes',
              'No se encontraron redes WiFi disponibles. Verifica que hay redes cerca.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        } else {
          // Error reportado por el ESP32
          final message = data['message'] ?? 'Error desconocido en el escaneo';
          throw Exception(message);
        }
      } else {
        throw Exception('Error de conexión: HTTP ${response.statusCode}');
      }
    } catch (e) {
      String errorMessage = 'Error al escanear redes WiFi';
      
      // Personalizar mensaje según el tipo de error
      if (e.toString().contains('SocketException') || e.toString().contains('Software caused connection abort')) {
        errorMessage = 'No se pudo conectar al ESP32. Verifica que estés conectado a "ESP_RFID_Setup"';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Tiempo de espera agotado. El ESP32 puede estar ocupado, intenta de nuevo';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Conexión rechazada. Verifica la IP del ESP32';
      }
      
      Get.snackbar(
        'Error de escaneo',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isScanning.value = false;
    }
  }
  
  // Seleccionar red WiFi
  void selectNetwork(Map<String, dynamic> network) {
    selectedNetwork.value = network['ssid'];
    wifiPasswordController.clear();
    
    // Mostrar dialog para ingresar contraseña
    _showPasswordDialog(network);
  }
  
  // Mostrar dialog para contraseña
  void _showPasswordDialog(Map<String, dynamic> network) {
    final bool isSecure = network['secure'] ?? false;
    
    Get.dialog(
      AlertDialog(
        title: Text('Conectar a ${network['ssid']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSecure) ...[
              const Text('Esta red requiere contraseña:'),
              const SizedBox(height: 12),
              TextField(
                controller: wifiPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña WiFi',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              const Text('Esta es una red abierta. ¿Conectar sin contraseña?'),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              connectToWiFi(network['ssid'], isSecure ? wifiPasswordController.text : '');
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }
  
  // Conectar a red WiFi
  Future<void> connectToWiFi(String ssid, String password) async {
    try {
      isLoading.value = true;
      
      Get.snackbar(
        'Configurando WiFi',
        'Enviando configuración al ESP32...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      const String espIp = 'http://192.168.4.1';
      final response = await http.post(
        Uri.parse('$espIp/api/wifi/connect'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ssid': ssid,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'connecting') {
          Get.snackbar(
            'WiFi Configurado',
            'El ESP32 se está conectando a $ssid. Esto puede tomar unos momentos.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          
          // Actualizar estado
          wifiSetupMode.value = false;
          connectionStatusMessage.value = 'ESP32 conectándose a WiFi...';
          
          // Esperar un poco más para que el ESP32 se conecte y reinicie
          await Future.delayed(const Duration(seconds: 8));
          
          // Verificar conexión RFID tras la configuración
          await checkRfidConnection();
          
          // Intentar detectar la nueva IP automáticamente
          await detectArduinoIP();
          
        } else {
          throw Exception(data['message'] ?? 'Error al conectar');
        }
      } else {
        throw Exception('Error de comunicación con ESP32 (${response.statusCode})');
      }
    } catch (e) {
      Get.snackbar(
        'Error de configuración',
        'No se pudo configurar WiFi: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Cambiar red WiFi (forzar modo configuración)
  Future<void> changeWiFiNetwork() async {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_find, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Expanded(child: Text('Cambiar Red WiFi')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El ESP32 se desconectará de la red actual y entrará en modo configuración.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text('Después deberás:'),
            SizedBox(height: 8),
            Text('1. Conectarte a "ESP_RFID_Setup"'),
            Text('2. Usar contraseña: "gymads123"'),
            Text('3. Seleccionar nueva red WiFi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _executeChangeWiFiNetwork();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Cambiar Red', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Ejecutar cambio de red WiFi
  Future<void> _executeChangeWiFiNetwork() async {
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Activando modo configuración...';
      
      // Intentar forzar modo configuración usando la IP actual del ESP32
      String currentUrl = RfidConfig.baseUrl;
      String currentIp = currentUrl.replaceAll(RegExp(r'http://|/api'), '');
      
      try {
        final response = await http.post(
          Uri.parse('http://$currentIp/api/wifi/config'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            Get.snackbar(
              'Modo configuración activado',
              'Conecta a "${data['ap_ssid'] ?? 'ESP_RFID_Setup'}" para cambiar de red',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            
            // Actualizar estado
            wifiSetupMode.value = true;
            rfidConnectionStatus.value = false;
            connectionStatusMessage.value = 'ESP32 en modo configuración';
            return;
          }
        }
      } catch (e) {
        print('Error al activar modo configuración: $e');
      }
      
      // Si no se pudo activar por API, mostrar instrucciones manuales
      Get.snackbar(
        'Modo configuración',
        'Conecta a "ESP_RFID_Setup" (contraseña: gymads123) para cambiar de red',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      
      wifiSetupMode.value = true;
      rfidConnectionStatus.value = false;
      connectionStatusMessage.value = 'ESP32 en modo configuración';
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cambiar el modo de red: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Resetear configuración a valores de fábrica
  Future<void> factoryResetConfiguration() async {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.factory, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Expanded(child: Text('Reseteo de Fábrica')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ ATENCIÓN: Esta acción es irreversible',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 12),
            Text('Esto eliminará:'),
            SizedBox(height: 8),
            Text('• Configuración WiFi del ESP32'),
            Text('• Credenciales guardadas localmente'),
            Text('• Configuraciones de la aplicación'),
            SizedBox(height: 12),
            Text(
              'El ESP32 volverá a los valores de fábrica y deberás configurar todo nuevamente.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _executeFactoryReset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resetear Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Ejecutar reseteo de fábrica
  Future<void> _executeFactoryReset() async {
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Ejecutando reseteo de fábrica...';
      
      // Primero intentar resetear el ESP32 usando la IP actual
      String currentUrl = RfidConfig.baseUrl;
      String currentIp = currentUrl.replaceAll(RegExp(r'http://|/api'), '');
      
      try {
        final response = await http.post(
          Uri.parse('http://$currentIp/api/wifi/reset'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            Get.snackbar(
              'ESP32 reseteado',
              'Configuración del ESP32 eliminada exitosamente',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        }
      } catch (e) {
        print('ESP32 no disponible para reset: $e');
      }
      
      // Limpiar configuraciones locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Actualizar estado de la aplicación
      wifiSetupMode.value = true;
      rfidConnectionStatus.value = false;
      connectionStatusMessage.value = 'Configuración eliminada - ESP32 desconectado';
      
      Get.snackbar(
        'Reseteo completo',
        'Todas las configuraciones han sido eliminadas. Configura el ESP32 nuevamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
      
    } catch (e) {
      Get.snackbar(
        'Error en reseteo',
        'Ocurrió un error durante el reseteo: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Resetear configuración WiFi
  Future<void> resetWiFiConfiguration() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Resetear WiFi'),
        content: const Text(
          '¿Estás seguro de que quieres resetear la configuración WiFi del ESP32?\n\n'
          'Esto borrará las credenciales guardadas y el ESP32 entrará en modo de configuración.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _executeWiFiReset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resetear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Ejecutar reset de WiFi
  Future<void> _executeWiFiReset() async {
    try {
      isLoading.value = true;
      
      // Intentar con la IP del modo AP
      const String espIp = 'http://192.168.4.1';
      final response = await http.post(
        Uri.parse('$espIp/api/wifi/reset'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          Get.snackbar(
            'Reset exitoso',
            'La configuración WiFi ha sido reseteada. El ESP32 entrará en modo configuración.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          
          wifiSetupMode.value = true;
          rfidConnectionStatus.value = false;
        }
      }
    } catch (e) {
      // Si no podemos conectar al ESP32, asumir que ya está en modo configuración
      Get.snackbar(
        'Modo Configuración',
        'Conecta a la red ESP_RFID_Setup para configurar WiFi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      
      wifiSetupMode.value = true;
      rfidConnectionStatus.value = false;
    } finally {
      isLoading.value = false;
    }
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