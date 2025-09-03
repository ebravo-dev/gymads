import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';
import '../../../data/config/rfid_config.dart';
import '../../../data/services/rfid_reader_service.dart';
import '../../../data/services/bluetooth_service.dart';
import '../views/rfid_settings_view.dart';

class ConfiguracionController extends GetxController {
  // Variables observables para la configuración
  final RxBool isLoading = false.obs;
  
  // Variables para información de cuenta
  final RxString userName = 'Staff Usuario'.obs;
  final RxString userEmail = 'staff@gymads.com'.obs;
  final RxString userRole = 'Staff'.obs;
  
  // Variables para configuración del lector RFID
  final RxBool rfidConnectionStatus = false.obs;
  final RxString connectionStatusMessage = 'Verificando conexión...'.obs;
  final RxString esp32IpAddress = ''.obs;
  
  // Variables para Bluetooth
  final RxBool bluetoothEnabled = false.obs;
  final RxBool bluetoothConnected = false.obs;
  final RxString bluetoothStatusMessage = 'Bluetooth desconectado'.obs;
  final RxList<fbp.BluetoothDevice> availableDevices = <fbp.BluetoothDevice>[].obs;
  final RxBool isScanning = false.obs;
  
  // Variables para configuración WiFi via Bluetooth
  final RxList<Map<String, dynamic>> availableNetworks = <Map<String, dynamic>>[].obs;
  final RxString selectedNetwork = ''.obs;
  final RxBool isConnectingWifi = false.obs;
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
    // Verificar estado de conexión RFID y Bluetooth
    checkInitialConnections();
  }

  @override
  void onClose() {
    wifiPasswordController.dispose();
    BluetoothService.disconnect();
    super.onClose();
  }
  
  // Cargar configuración inicial
  Future<void> loadInitialConfig() async {
    // Cargar configuración RFID desde SharedPreferences
    await RfidConfig.loadConfig();
    
    // TODO: Cargar información de usuario desde autenticación
    userName.value = 'Staff Usuario';
    userEmail.value = 'staff@gymads.com';
    userRole.value = 'Staff';
    
    // Verificar estado inicial
    connectionStatusMessage.value = 'Verificando configuración...';
  }
  
  // Verificar conexiones iniciales
  Future<void> checkInitialConnections() async {
    await checkBluetoothStatus();
    await checkRfidConnection();
  }
  
  // Verificar estado de Bluetooth
  Future<void> checkBluetoothStatus() async {
    bluetoothEnabled.value = await BluetoothService.initialize();
    
    if (bluetoothEnabled.value) {
      bluetoothStatusMessage.value = 'Bluetooth disponible';
      if (BluetoothService.isConnected) {
        bluetoothConnected.value = true;
        bluetoothStatusMessage.value = 'Conectado a ESP32';
      } else {
        bluetoothStatusMessage.value = 'Bluetooth listo para conectar';
      }
    } else {
      bluetoothStatusMessage.value = 'Bluetooth no disponible';
    }
  }
  
  // Verificar conexión con el lector RFID
  Future<void> checkRfidConnection() async {
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Verificando conexión con ESP32...';
      
      // Verificar si ya tenemos IP configurada
      if (RfidConfig.isConfigured) {
        final isConnected = await RfidReaderService.startReading();
        rfidConnectionStatus.value = isConnected;
        
        if (isConnected) {
          final baseUrl = RfidConfig.baseUrl;
          if (baseUrl != null) {
            esp32IpAddress.value = baseUrl.replaceAll('/api', '').replaceAll('http://', '');
            connectionStatusMessage.value = 'ESP32 conectado y listo';
          }
        } else {
          connectionStatusMessage.value = 'ESP32 no responde - Revisar conexión WiFi';
        }
      } else {
        rfidConnectionStatus.value = false;
        connectionStatusMessage.value = 'ESP32 no configurado - Usar Bluetooth para configurar';
      }
      
    } catch (e) {
      rfidConnectionStatus.value = false;
      connectionStatusMessage.value = 'Error al verificar ESP32';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Buscar dispositivos ESP32 via Bluetooth
  Future<void> scanForESP32Devices() async {
    if (!bluetoothEnabled.value) {
      Get.snackbar(
        'Bluetooth',
        'Bluetooth no está disponible',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isScanning.value = true;
      bluetoothStatusMessage.value = 'Buscando dispositivos ESP32...';
      
      List<fbp.BluetoothDevice> devices = await BluetoothService.findESP32Devices();
      availableDevices.value = devices;
      
      if (devices.isNotEmpty) {
        bluetoothStatusMessage.value = 'Dispositivos ESP32 encontrados';
        _showDeviceSelectionDialog(devices);
      } else {
        bluetoothStatusMessage.value = 'No se encontraron dispositivos ESP32';
        Get.snackbar(
          'Búsqueda Bluetooth',
          'No se encontraron dispositivos ESP32.\nAsegúrate de que el ESP32 esté encendido.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
      
    } catch (e) {
      bluetoothStatusMessage.value = 'Error al buscar dispositivos';
      Get.snackbar(
        'Error Bluetooth',
        'Error al buscar dispositivos: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isScanning.value = false;
    }
  }
  
  // Mostrar dialog para seleccionar dispositivo
  void _showDeviceSelectionDialog(List<fbp.BluetoothDevice> devices) {
    Get.dialog(
      AlertDialog(
        title: const Text('Dispositivos ESP32 encontrados'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              String deviceName = device.platformName.isNotEmpty ? device.platformName : device.advName;
              if (deviceName.isEmpty) deviceName = 'Dispositivo desconocido';
              
              return ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(deviceName),
                subtitle: Text(device.remoteId.toString()),
                onTap: () {
                  Get.back();
                  connectToESP32Device(device);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  
  // Conectar a dispositivo ESP32
  Future<void> connectToESP32Device(fbp.BluetoothDevice device) async {
    try {
      isLoading.value = true;
      String deviceName = device.platformName.isNotEmpty ? device.platformName : device.advName;
      if (deviceName.isEmpty) deviceName = 'ESP32';
      
      bluetoothStatusMessage.value = 'Conectando a $deviceName...';
      
      bool connected = await BluetoothService.connectToESP32(device);
      
      if (connected) {
        bluetoothConnected.value = true;
        bluetoothStatusMessage.value = 'Conectado a $deviceName';
        
        Get.snackbar(
          'Bluetooth',
          'Conectado exitosamente a $deviceName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Verificar estado del ESP32
        await checkESP32Status();
        
      } else {
        bluetoothStatusMessage.value = 'Error al conectar con $deviceName';
        Get.snackbar(
          'Error Bluetooth',
          'No se pudo conectar a $deviceName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      bluetoothStatusMessage.value = 'Error de conexión';
      Get.snackbar(
        'Error',
        'Error al conectar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Verificar estado del ESP32 via Bluetooth
  Future<void> checkESP32Status() async {
    if (!bluetoothConnected.value) return;
    
    try {
      var status = await BluetoothService.getESP32Status();
      
      if (status != null) {
        bool wifiConnected = status['wifi_connected'] ?? false;
        
        if (wifiConnected) {
          String ipAddress = status['ip_address'] ?? '';
          if (ipAddress.isNotEmpty) {
            esp32IpAddress.value = ipAddress;
            await RfidConfig.configureFromBluetooth(ipAddress);
            rfidConnectionStatus.value = true;
            connectionStatusMessage.value = 'ESP32 configurado y listo';
            
            Get.snackbar(
              'ESP32 Configurado',
              'ESP32 conectado a WiFi con IP: $ipAddress',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          }
        } else {
          connectionStatusMessage.value = 'ESP32 conectado pero sin WiFi - Configurar red';
          _showWiFiConfigurationDialog();
        }
      }
      
    } catch (e) {
      connectionStatusMessage.value = 'Error al verificar estado del ESP32';
    }
  }
  
  // Mostrar dialog de configuración WiFi
  void _showWiFiConfigurationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Configurar WiFi'),
        content: const Text(
          'El ESP32 no está conectado a WiFi.\n¿Deseas configurar la conexión WiFi ahora?'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              scanWiFiNetworks();
            },
            child: const Text('Configurar WiFi'),
          ),
        ],
      ),
    );
  }
  
  // Escanear redes WiFi via Bluetooth
  Future<void> scanWiFiNetworks() async {
    if (!bluetoothConnected.value) {
      Get.snackbar(
        'Error',
        'Primero conecta con el ESP32 via Bluetooth',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Escaneando redes WiFi...';
      
      List<Map<String, dynamic>> networks = await BluetoothService.scanWiFiNetworks();
      availableNetworks.value = networks;
      
      if (networks.isNotEmpty) {
        connectionStatusMessage.value = 'Redes WiFi encontradas';
        _showNetworkSelectionDialog(networks);
      } else {
        connectionStatusMessage.value = 'No se encontraron redes WiFi';
        Get.snackbar(
          'WiFi',
          'No se encontraron redes WiFi disponibles',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      connectionStatusMessage.value = 'Error al escanear WiFi';
      Get.snackbar(
        'Error WiFi',
        'Error al escanear redes: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Mostrar dialog de selección de red WiFi
  void _showNetworkSelectionDialog(List<Map<String, dynamic>> networks) {
    Get.dialog(
      AlertDialog(
        title: const Text('Seleccionar Red WiFi'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: networks.length,
            itemBuilder: (context, index) {
              final network = networks[index];
              final String ssid = network['ssid'] ?? '';
              final int rssi = network['rssi'] ?? -100;
              final bool secure = network['secure'] ?? false;
              
              return ListTile(
                leading: Icon(secure ? Icons.wifi_lock : Icons.wifi),
                title: Text(ssid),
                subtitle: Text('${secure ? 'Segura' : 'Abierta'} • Señal: ${_getSignalStrength(rssi)}'),
                onTap: () {
                  Get.back();
                  selectNetwork(network);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              scanWiFiNetworks(); // Volver a escanear
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
  
  // Obtener fuerza de señal visual
  String _getSignalStrength(int rssi) {
    if (rssi > -50) return '●●●●';
    if (rssi > -60) return '●●●○';
    if (rssi > -70) return '●●○○';
    if (rssi > -80) return '●○○○';
    return '○○○○';
  }
  
  // Seleccionar red WiFi
  void selectNetwork(Map<String, dynamic> network) {
    selectedNetwork.value = network['ssid'];
    wifiPasswordController.clear();
    
    // Mostrar dialog para contraseña
    _showPasswordDialog(network);
  }
  
  // Mostrar dialog para contraseña WiFi
  void _showPasswordDialog(Map<String, dynamic> network) {
    final bool isSecure = network['secure'] ?? false;
    
    Get.dialog(
      AlertDialog(
        title: Text('Conectar a ${network['ssid']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSecure) ...[
              const Text('Esta red requiere contraseña:'),
              const SizedBox(height: 16),
              TextField(
                controller: wifiPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña WiFi',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              const Text('Esta red está abierta y no requiere contraseña.'),
            ],
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
              connectToWiFi(network['ssid'], wifiPasswordController.text);
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }
  
  // Conectar a WiFi via Bluetooth
  Future<void> connectToWiFi(String ssid, String password) async {
    if (!bluetoothConnected.value) {
      Get.snackbar(
        'Error',
        'Primero conecta con el ESP32 via Bluetooth',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isConnectingWifi.value = true;
      connectionStatusMessage.value = 'Conectando ESP32 a WiFi...';
      
      bool connected = await BluetoothService.connectToWiFi(ssid, password);
      
      if (connected) {
        // Obtener la IP del ESP32
        String? ipAddress = await BluetoothService.getESP32IP();
        
        if (ipAddress != null) {
          esp32IpAddress.value = ipAddress;
          await RfidConfig.configureFromBluetooth(ipAddress);
          rfidConnectionStatus.value = true;
          connectionStatusMessage.value = 'ESP32 configurado exitosamente';
          
          Get.snackbar(
            'WiFi Configurado',
            'ESP32 conectado a $ssid con IP: $ipAddress',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        } else {
          connectionStatusMessage.value = 'WiFi conectado pero no se obtuvo IP';
        }
      } else {
        connectionStatusMessage.value = 'Error al conectar WiFi';
        Get.snackbar(
          'Error WiFi',
          'No se pudo conectar a la red $ssid.\nVerifica la contraseña.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      connectionStatusMessage.value = 'Error de configuración WiFi';
      Get.snackbar(
        'Error',
        'Error al configurar WiFi: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isConnectingWifi.value = false;
    }
  }
  
  // Probar conexión RFID
  Future<void> testRfidConnection() async {
    await checkRfidConnection();
  }
  
  // Resetear configuración WiFi via Bluetooth
  Future<void> resetWiFiConfiguration() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Resetear WiFi'),
        content: const Text(
          '¿Estás seguro de que deseas resetear la configuración WiFi del ESP32?\n\n'
          'Esto eliminará las credenciales WiFi guardadas y el ESP32 deberá ser reconfigurado.'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _executeWiFiReset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
  }
  
  // Ejecutar reset de WiFi
  Future<void> _executeWiFiReset() async {
    if (!bluetoothConnected.value) {
      Get.snackbar(
        'Error',
        'Primero conecta con el ESP32 via Bluetooth',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Reseteando configuración WiFi...';
      
      bool success = await BluetoothService.resetWiFiConfig();
      
      if (success) {
        // Limpiar configuración local también
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('esp32_api_url');
        
        rfidConnectionStatus.value = false;
        esp32IpAddress.value = '';
        connectionStatusMessage.value = 'Configuración WiFi reseteada - Reconfigurar';
        
        Get.snackbar(
          'Reset Exitoso',
          'Configuración WiFi eliminada. Configura nuevamente la red.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        connectionStatusMessage.value = 'Error al resetear configuración';
        Get.snackbar(
          'Error',
          'No se pudo resetear la configuración WiFi',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      connectionStatusMessage.value = 'Error al resetear WiFi';
      Get.snackbar(
        'Error',
        'Error al resetear: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Desconectar Bluetooth
  Future<void> disconnectBluetooth() async {
    await BluetoothService.disconnect();
    bluetoothConnected.value = false;
    bluetoothStatusMessage.value = 'Bluetooth desconectado';
    
    Get.snackbar(
      'Bluetooth',
      'Desconectado del ESP32',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }
  
  // Cerrar sesión
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implementar lógica de logout
              Get.snackbar(
                'Logout',
                'Cerrando sesión...',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
  
  // Abrir configuración de cuenta
  void openAccountSettings() {
    Get.dialog(
      AlertDialog(
        title: const Text('Configuración de Cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccountInfoRow(Icons.person, 'Usuario:', userName.value),
            const SizedBox(height: 8),
            _buildAccountInfoRow(Icons.email, 'Email:', userEmail.value),
            const SizedBox(height: 8),
            _buildAccountInfoRow(Icons.badge, 'Rol:', userRole.value, Colors.blue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  // Abrir configuración de RFID
  void openRfidSettings() {
    Get.to(() => const RfidSettingsView());
  }
  
  // Widget helper para información de cuenta
  Widget _buildAccountInfoRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  // Abrir configuración de aplicación (futuro)
  void openAppSettings() {
    Get.snackbar(
      'Configuración',
      'Configuración de aplicación próximamente',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
