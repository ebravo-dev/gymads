import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Clase para manejar la configuración del lector RFID ESP32
class RfidConfig {
  // Clave para guardar la URL en SharedPreferences
  static const String _urlKey = 'esp32_api_url';
  
  // URL por defecto (se actualizará dinámicamente desde el Arduino)
  static const String _defaultUrl = 'http://192.168.1.136/api';
  
  // Variable estática para mantener la URL actual en memoria
  static String? _currentUrl;
  
  // URL del ESP32 con persistencia en SharedPreferences
  static String get baseUrl {
    // Si ya tenemos la URL en memoria, la devolvemos
    if (_currentUrl != null) return _currentUrl!;
    
    // Si no, intentamos obtenerla de dotenv o usar la por defecto
    String url = dotenv.env['ESP32_API_URL'] ?? _defaultUrl;
    _currentUrl = url;
    return url;
  }
  
  // Cargar la configuración guardada
  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_urlKey);
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _currentUrl = savedUrl;
        dotenv.env['ESP32_API_URL'] = savedUrl;
        if (kDebugMode) {
          print('Configuración ESP32 cargada desde preferencias');
        }
        
        // Verificar si la IP guardada sigue siendo válida
        if (!(await _testConnection(savedUrl))) {
          if (kDebugMode) {
            print('IP guardada no responde, intentando detectar automáticamente...');
          }
          await _detectEspIp();
        }
      } else {
        // Si no hay URL guardada, intentar detectar automáticamente
        await _detectEspIp();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar configuración RFID: $e');
      }
      _currentUrl = _defaultUrl;
    }
  }

  // Detecta automáticamente la IP del ESP32
  static Future<void> _detectEspIp() async {
    // Lista de IPs posibles a verificar
    final possibleIps = [
      '192.168.4.1',    // IP por defecto en modo AP
      '192.168.1.136',  // IP común en redes domésticas
      '192.168.0.136',  // Otra IP común
      '10.0.0.136',     // IP en algunas redes
      '192.168.1.100',  // Rango común adicional
      '192.168.0.100',  
    ];

    for (final ip in possibleIps) {
      final testUrl = 'http://$ip/api';
      if (await _testConnection(testUrl)) {
        if (kDebugMode) {
          print('ESP32 encontrado automáticamente en: $ip');
        }
        await updateConfig(newUrl: testUrl);
        return;
      }
    }

    if (kDebugMode) {
      print('No se pudo detectar automáticamente la IP del ESP32, usando IP por defecto');
    }
    _currentUrl = _defaultUrl;
    await saveConfig(_defaultUrl);
  }

  // Probar conexión con una URL específica
  static Future<bool> _testConnection(String url) async {
    try {
      final testUrl = url.endsWith('/api') ? url : '$url/api';
      final statusUrl = '$testUrl/wifi/status';
      
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('ESP32 encontrado en $url (modo: ${data['mode'] ?? 'unknown'})');
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
  
  // Método para actualizar la configuración cuando cambie la IP del Arduino
  static Future<void> updateConfig({String? newUrl}) async {
    if (newUrl != null) {
      final validatedUrl = validateUrl(newUrl);
      _currentUrl = validatedUrl;
      dotenv.env['ESP32_API_URL'] = validatedUrl;
      await saveConfig(validatedUrl);
      
      if (kDebugMode) {
        print('Configuración ESP32 actualizada automáticamente desde dispositivo');
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
