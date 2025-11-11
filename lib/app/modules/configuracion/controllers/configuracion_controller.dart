import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/config/rfid_config.dart';
import '../../../data/services/rfid_reader_service.dart';
import '../../../../core/theme/app_colors.dart';

class ConfiguracionController extends GetxController {
  // Variables observables para la configuración
  final RxBool isLoading = false.obs;
  
  // Variables para información de cuenta
  final RxString userName = 'Eder Blanco'.obs;
  final RxString userEmail = 'eder@gymads.com'.obs;
  final RxString userRole = 'Admin'.obs;
  
  // Variables para configuración del lector RFID
  final RxBool rfidConnectionStatus = false.obs;
  final RxString connectionStatusMessage = 'Verificando conexión...'.obs;
  final RxString esp32IpAddress = ''.obs;
  
  // Variables para ESP32 con IP manual
  final RxBool esp32Connected = false.obs;
  final RxString esp32StatusMessage = 'ESP32 desconectado'.obs;
  
  // Variables para configuración de audio
  final RxBool soundEnabled = true.obs;
  final RxDouble soundVolume = 0.8.obs;
  
  // Variables para configuración de QR
  final RxBool qrEnabled = true.obs;
  final RxString qrCodeFormat = 'auto'.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadConfiguration();
    _initializeESP32Connection();
  }

  @override
  void onClose() {
    super.onClose();
  }

  // =================== MÉTODOS DE INICIALIZACIÓN ===================

  Future<void> _loadConfiguration() async {
    try {
      isLoading.value = true;
      
      // Cargar configuración desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Configuración de usuario
      userName.value = prefs.getString('user_name') ?? 'Eder Blanco';
      userEmail.value = prefs.getString('user_email') ?? 'eder@gymads.com';
      userRole.value = prefs.getString('user_role') ?? 'Admin';
      
      // Configuración de audio
      soundEnabled.value = prefs.getBool('sound_enabled') ?? true;
      soundVolume.value = prefs.getDouble('sound_volume') ?? 0.8;
      
      // Configuración de QR
      qrEnabled.value = prefs.getBool('qr_enabled') ?? true;
      qrCodeFormat.value = prefs.getString('qr_format') ?? 'auto';
      
      // Cargar IP manual si existe
      String? savedIP = prefs.getString('esp32_ip_manual');
      if (savedIP != null && savedIP.isNotEmpty) {
        // Intentar conectar con la IP guardada sin mostrar notificación
        await connectToESP32WithIP(savedIP, showNotification: false);
      }
      
      await RfidConfig.loadConfig();
      await _checkRfidConnection();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cargar configuración: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeESP32Connection() async {
    try {
      // Intentar conectar directamente con la IP estática predeterminada
      // sin mostrar notificación (conexión silenciosa al iniciar)
      await connectToESP32WithIP(RfidConfig.DEFAULT_ESP32_IP, showNotification: false);
    } catch (e) {
      esp32StatusMessage.value = 'Error de inicialización: $e';
    }
  }

  // =================== MÉTODOS DE CONEXIÓN ESP32 ===================





  /// Conectar manualmente con IP específica (método principal de conexión)
  Future<void> connectToESP32WithIP(String ipAddress, {bool showNotification = true}) async {
    try {
      isLoading.value = true;
      esp32StatusMessage.value = 'Conectando a $ipAddress...';
      
      // Verificar formato de IP válido
      final RegExp ipRegex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
      if (!ipRegex.hasMatch(ipAddress)) {
        if (showNotification) {
          Get.snackbar(
            'Formato inválido',
            'La dirección IP no tiene un formato válido (ej: 192.168.1.100)',
            backgroundColor: AppColors.warning,
            colorText: Colors.white,
          );
        }
        return;
      }
      
      bool connected = await RfidConfig.setManualIP(ipAddress);
      
      if (connected) {
        esp32Connected.value = true;
        esp32IpAddress.value = ipAddress;
        esp32StatusMessage.value = 'ESP32 conectado: $ipAddress';
        
        if (showNotification) {
          Get.snackbar(
            'Conectado',
            'ESP32 conectado exitosamente a $ipAddress',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
          );
        }
        
        // Guardar la IP para uso futuro
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('esp32_ip_manual', ipAddress);
      } else {
        esp32Connected.value = false;
        esp32StatusMessage.value = 'No se pudo conectar a $ipAddress';
        
        if (showNotification) {
          Get.snackbar(
            'Error de conexión',
            'No se pudo conectar al ESP32 en $ipAddress. Verifique que el dispositivo esté encendido y en la misma red.',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      esp32Connected.value = false;
      esp32StatusMessage.value = 'Error: $e';
      
      if (showNotification) {
        Get.snackbar(
          'Error',
          'Error al conectar: $e',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Obtener estado del ESP32
  Future<void> getESP32Status() async {
    try {
      bool available = await RfidConfig.isESP32Available();
      
      if (available) {
        esp32Connected.value = true;
        esp32IpAddress.value = RfidConfig.getCurrentIP() ?? RfidConfig.DEFAULT_ESP32_IP;
        esp32StatusMessage.value = 'ESP32 conectado: ${esp32IpAddress.value}';
      } else {
        esp32Connected.value = false;
        esp32StatusMessage.value = 'ESP32 sin conexión WiFi';
      }
    } catch (e) {
      esp32StatusMessage.value = 'Error al obtener estado: $e';
    }
  }

  // =================== MÉTODOS DE CONFIGURACIÓN RFID ===================

  Future<void> _checkRfidConnection() async {
    try {
      // Verificar si hay configuración RFID
      bool isConfigured = RfidConfig.isConfigured;
      rfidConnectionStatus.value = isConfigured;
      
      if (isConfigured) {
        connectionStatusMessage.value = 'RFID configurado';
        if (RfidConfig.baseUrl != null) {
          // Extraer IP de la URL
          String url = RfidConfig.baseUrl!;
          final RegExp ipRegex = RegExp(r'(\d+\.\d+\.\d+\.\d+)');
          final match = ipRegex.firstMatch(url);
          if (match != null) {
            esp32IpAddress.value = match.group(1)!;
          }
        }
      } else {
        connectionStatusMessage.value = 'RFID no configurado';
      }
    } catch (e) {
      rfidConnectionStatus.value = false;
      connectionStatusMessage.value = 'Error al verificar RFID: $e';
    }
  }

  /// Probar conexión RFID
  Future<void> testRfidConnection() async {
    try {
      isLoading.value = true;
      connectionStatusMessage.value = 'Probando conexión...';
      
      // Intentar leer una tarjeta para probar la conexión
      String? cardUid = await RfidReaderService.checkForCard();
      
      if (cardUid != null) {
        rfidConnectionStatus.value = true;
        connectionStatusMessage.value = 'RFID conectado - Tarjeta detectada';
        
        Get.snackbar(
          'Conexión exitosa',
          'El lector RFID está funcionando correctamente',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else if (RfidConfig.isConfigured) {
        rfidConnectionStatus.value = true;
        connectionStatusMessage.value = 'RFID conectado - Sin tarjeta';
        
        Get.snackbar(
          'Conexión OK',
          'El lector RFID está conectado pero no hay tarjeta presente',
          backgroundColor: AppColors.info,
          colorText: Colors.white,
        );
      } else {
        rfidConnectionStatus.value = false;
        connectionStatusMessage.value = 'RFID no configurado';
        
        Get.snackbar(
          'Sin configurar',
          'El lector RFID no está configurado',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      rfidConnectionStatus.value = false;
      connectionStatusMessage.value = 'Error: $e';
      
      Get.snackbar(
        'Error',
        'Error al probar conexión: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // =================== MÉTODOS DE CONFIGURACIÓN ===================

  /// Guardar configuración de usuario
  Future<void> saveUserConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('user_name', userName.value);
      await prefs.setString('user_email', userEmail.value);
      await prefs.setString('user_role', userRole.value);
      
      Get.snackbar(
        'Guardado',
        'Configuración de usuario guardada',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al guardar configuración: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  /// Guardar configuración de audio
  Future<void> saveAudioConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('sound_enabled', soundEnabled.value);
      await prefs.setDouble('sound_volume', soundVolume.value);
      
      Get.snackbar(
        'Guardado',
        'Configuración de audio guardada',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al guardar configuración de audio: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  /// Guardar configuración de QR
  Future<void> saveQRConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('qr_enabled', qrEnabled.value);
      await prefs.setString('qr_format', qrCodeFormat.value);
      
      Get.snackbar(
        'Guardado',
        'Configuración de QR guardada',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al guardar configuración de QR: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  /// Restablecer configuración
  Future<void> resetConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Restablecer valores por defecto
      userName.value = 'Eder Blanco';
      userEmail.value = 'eder@gymads.com';
      userRole.value = 'Admin';
      soundEnabled.value = true;
      soundVolume.value = 0.8;
      qrEnabled.value = true;
      qrCodeFormat.value = 'auto';
      
      Get.snackbar(
        'Restablecido',
        'Configuración restablecida a valores por defecto',
        backgroundColor: AppColors.info,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al restablecer configuración: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  // =================== MÉTODOS DE INFORMACIÓN ===================

  /// Mostrar información sobre la conexión WiFi
  void showWifiInfo() {
    Get.dialog(
      AlertDialog(
        title: const Text('Conexión WiFi con IP Estática'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El sistema ahora usa conexión WiFi directa con IP estática:'),
            SizedBox(height: 8),
            Text('✓ IP fija: 192.168.1.100'),
            Text('✓ Sin configuración necesaria'),
            Text('✓ Mayor estabilidad y rendimiento'),
            SizedBox(height: 12),
            Text('IMPORTANTE:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('El ESP32 debe estar en la misma red WiFi que este dispositivo.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  
  // =================== MÉTODOS PARA NAVEGACIÓN DE CONFIGURACIÓN ===================
  
  /// Abrir configuración de cuenta
  void openAccountSettings() {
    // Mostrar un diálogo simple por ahora
    Get.dialog(
      AlertDialog(
        title: const Text('Configuración de Cuenta'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Esta funcionalidad será implementada próximamente.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
  
  /// Abrir configuración de aplicación
  void openAppSettings() {
    // Mostrar un diálogo simple por ahora
    Get.dialog(
      AlertDialog(
        title: const Text('Configuración de Aplicación'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Esta funcionalidad será implementada próximamente.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
  
  /// Cerrar sesión
  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar la sesión?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Aquí implementar la lógica de cierre de sesión
              Get.back();
              Get.snackbar(
                'Cerrar Sesión',
                'Funcionalidad en desarrollo',
                backgroundColor: AppColors.info,
                colorText: Colors.white,
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}