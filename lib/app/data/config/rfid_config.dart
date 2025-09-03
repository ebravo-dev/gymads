import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Clase para manejar la configuración del lector RFID ESP32
class RfidConfig {
  // Clave para guardar la URL en SharedPreferences
  static const String _urlKey = 'esp32_api_url';
  
  // Variable estática para mantener la URL actual en memoria
  static String? _currentUrl;
  
  // URL del ESP32 con persistencia en SharedPreferences
  static String? get baseUrl {
    // Si ya tenemos la URL en memoria, la devolvemos
    if (_currentUrl != null) return _currentUrl!;
    
    // Si no hay URL configurada, devolver null (requiere configuración Bluetooth)
    return null;
  }
  
  // Verificar si el ESP32 está configurado y disponible
  static bool get isConfigured => _currentUrl != null && _currentUrl!.isNotEmpty;
  
  // Cargar la configuración guardada
  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_urlKey);
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        if (kDebugMode) {
          print('Configuración ESP32 cargada desde preferencias: $savedUrl');
        }
        
        // Verificar si la IP guardada sigue siendo válida
        if (await _testConnection(savedUrl)) {
          _currentUrl = savedUrl;
          if (kDebugMode) {
            print('IP guardada es válida: $savedUrl');
          }
        } else {
          if (kDebugMode) {
            print('IP guardada no responde, se requiere configuración via Bluetooth');
          }
          _currentUrl = null; // Forzar reconfiguración
          // Limpiar preferencias inválidas
          await prefs.remove(_urlKey);
        }
      } else {
        if (kDebugMode) {
          print('No hay configuración guardada, se requiere configuración via Bluetooth');
        }
        _currentUrl = null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar configuración RFID: $e');
      }
      _currentUrl = null;
    }
  }

  // Verificar si hay configuración IP disponible
  static bool get hasConfiguredIP => _currentUrl != null && _currentUrl!.isNotEmpty;
  
  // Configurar IP desde Bluetooth
  static Future<bool> configureFromBluetooth(String ipAddress) async {
    if (ipAddress.isEmpty) {
      if (kDebugMode) {
        print('IP desde Bluetooth está vacía');
      }
      return false;
    }
    
    String validatedUrl = 'http://$ipAddress/api';
    
    if (kDebugMode) {
      print('Configurando ESP32 desde Bluetooth: $validatedUrl');
    }
    
    // Probar la conexión primero
    if (await _testConnection(validatedUrl)) {
      _currentUrl = validatedUrl;
      await saveConfig(validatedUrl);
      
      if (kDebugMode) {
        print('Configuración ESP32 actualizada exitosamente desde Bluetooth: $validatedUrl');
      }
      return true;
    } else {
      if (kDebugMode) {
        print('IP desde Bluetooth no responde: $ipAddress');
      }
      return false;
    }
  }
  
  // Forzar actualización de IP (sin validación para casos donde sabemos que es correcta)
  static void forceUpdateIP(String ipAddress) {
    if (ipAddress.isNotEmpty) {
      String validatedUrl = 'http://$ipAddress/api';
      _currentUrl = validatedUrl;
      
      if (kDebugMode) {
        print('IP forzada desde Bluetooth: $validatedUrl');
      }
      
      // Guardar en background sin bloquear
      saveConfig(validatedUrl);
    }
  }

  // Probar conexión con una URL específica
  static Future<bool> _testConnection(String url) async {
    try {
      final testUrl = url.endsWith('/api') ? url : '$url/api';
      final statusUrl = '$testUrl/status';
      
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('ESP32 encontrado en $url (status: ${data['status'] ?? 'unknown'})');
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Guardar la configuración
  static Future<void> saveConfig(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_urlKey, url);
      if (kDebugMode) {
        print('Configuración ESP32 actualizada automáticamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar configuración RFID: $e');
      }
    }
  }
  
  // Método para actualizar la configuración cuando el ESP32 envíe su IP via Bluetooth
  static Future<void> updateConfig({String? newUrl}) async {
    if (newUrl != null && newUrl.isNotEmpty) {
      final validatedUrl = validateUrl(newUrl);
      _currentUrl = validatedUrl;
      await saveConfig(validatedUrl);
      
      if (kDebugMode) {
        print('Configuración ESP32 actualizada: $validatedUrl');
      }
    }
  }
  
  // Limpiar configuración (para forzar reconfiguración)
  static Future<void> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_urlKey);
      _currentUrl = null;
      
      if (kDebugMode) {
        print('Configuración ESP32 limpiada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al limpiar configuración: $e');
      }
    }
  }
  
  // Comprueba si la URL es válida y ajusta si es necesario
  static String validateUrl(String url) {
    // Asegurarse de que la URL no termina con una barra
    String validUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    
    // Asegurarse de que la URL tiene el formato correcto para las solicitudes
    if (!validUrl.startsWith('http://') && !validUrl.startsWith('https://')) {
      validUrl = 'http://$validUrl';
    }
    
    return validUrl;
  }
  
  // Tiempo máximo de espera para lectura de tarjeta (en segundos)
  static int get maxReadingTimeoutSeconds => 15;
  
  // Intervalo de verificación para nuevas tarjetas (en milisegundos)
  static int get pollingIntervalMs => 500;
  
  // Estados de membresía para el sistema de LEDs
  static const String membershipActive = 'ACTIVE';
  static const String membershipExpiring = 'EXPIRING';
  static const String membershipExpired = 'EXPIRED';
  static const String membershipNotFound = 'NOT_FOUND';
  
  // Días de advertencia antes del vencimiento
  static int get expiringWarningDays => 5;
}
