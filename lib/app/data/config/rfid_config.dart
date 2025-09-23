import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';

/// Clase para manejar la configuración del lector RFID ESP32
class RfidConfig {
  // Claves para guardar configuraciones en SharedPreferences
  static const String _urlKey = 'esp32_api_url';
  static const String _staticIpKey = 'esp32_static_ip';
  static const String _networkPrefixKey = 'network_prefix';
  
  // Variable estática para mantener la URL actual en memoria
  static String? _currentUrl;
  
  // Variable para guardar el prefijo de red actual
  static String? _currentNetworkPrefix;
  
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
      
      // Intenta detectar la red WiFi actual
      await _detectCurrentNetwork();
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        if (kDebugMode) {
          print('Configuración ESP32 cargada desde preferencias: $savedUrl');
        }
        
        // Primero intentamos con la URL guardada
        if (await _testConnection(savedUrl)) {
          _currentUrl = savedUrl;
          if (kDebugMode) {
            print('IP guardada es válida: $savedUrl');
          }
          return;
        }
        
        // Si la URL guardada no funciona, intentamos con IP estática para la red actual
        if (_currentNetworkPrefix != null) {
          final staticIpForNetwork = prefs.getString('${_staticIpKey}_${_currentNetworkPrefix}');
          if (staticIpForNetwork != null && staticIpForNetwork.isNotEmpty) {
            final staticUrl = 'http://$staticIpForNetwork/api';
            if (kDebugMode) {
              print('Intentando con IP estática para esta red: $staticUrl');
            }
            
            if (await _testConnection(staticUrl)) {
              _currentUrl = staticUrl;
              await saveConfig(staticUrl);
              if (kDebugMode) {
                print('Conectado usando IP estática: $staticUrl');
              }
              return;
            }
          }
          
          // Si no hay IP estática guardada para esta red, intentar con escaneo de IP
          if (await _tryAutoDetectEsp32Ip()) {
            return;
          }
        }
        
        if (kDebugMode) {
          print('IP guardada no responde, se requiere configuración via Bluetooth');
        }
        _currentUrl = null; // Forzar reconfiguración
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

  // Escanear la red actual para intentar encontrar el ESP32
  static Future<bool> _tryAutoDetectEsp32Ip() async {
    if (_currentNetworkPrefix == null) return false;
    
    if (kDebugMode) {
      print('Intentando detectar ESP32 en la red actual $_currentNetworkPrefix...');
    }
    
    // Solo probar con el prefijo de red actual detectado
    if (await _scanNetworkRange(_currentNetworkPrefix!)) {
      return true;
    }
    
    if (kDebugMode) {
      print('No se encontró ESP32 en la red actual $_currentNetworkPrefix');
    }
    
    return false;
  }
  
  // Escanear un rango de IPs en la red
  static Future<bool> _scanNetworkRange(String networkPrefix) async {
    // Probar las últimas direcciones de la red, ya que los routers suelen asignar IPs desde el final
    for (int i = 254; i >= 1; i--) {
      // Solo intentar algunos rangos comunes para evitar escaneos muy largos
      if (i > 200 || (i > 100 && i < 110) || (i > 1 && i < 20)) {
        final ipToTest = '$networkPrefix$i';
        final urlToTest = 'http://$ipToTest/api';
        
        if (kDebugMode) {
          print('Probando IP: $urlToTest');
        }
        
        if (await _testConnection(urlToTest)) {
          _currentUrl = urlToTest;
          await saveConfig(urlToTest);
          await saveStaticIpForNetwork(ipToTest);
          
          if (kDebugMode) {
            print('ESP32 encontrado automáticamente en: $urlToTest');
          }
          return true;
        }
      }
    }
    
    return false;
  }

  // Detectar la red WiFi actual y su prefijo
  static Future<void> _detectCurrentNetwork() async {
    try {
      final networkInfo = NetworkInfo();
      final wifiIP = await networkInfo.getWifiIP();
      
      if (wifiIP != null && wifiIP.isNotEmpty) {
        if (kDebugMode) {
          print('IP WiFi actual: $wifiIP');
        }
        
        // Extraer el prefijo de red
        final ipParts = wifiIP.split('.');
        if (ipParts.length == 4) {
          _currentNetworkPrefix = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}.';
          
          if (kDebugMode) {
            print('Prefijo de red detectado: $_currentNetworkPrefix');
          }
          
          // Guardar el prefijo de red actual
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_networkPrefixKey, _currentNetworkPrefix!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al detectar red WiFi: $e');
      }
      _currentNetworkPrefix = null;
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
      
      // Si estamos conectados a una red WiFi, guardar esta IP como estática para esta red
      if (_currentNetworkPrefix != null) {
        await saveStaticIpForNetwork(ipAddress);
      }
      
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
  
  // Guardar IP estática para la red actual
  static Future<void> saveStaticIpForNetwork(String ipAddress) async {
    if (_currentNetworkPrefix == null) {
      await _detectCurrentNetwork();
      if (_currentNetworkPrefix == null) return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_staticIpKey}_${_currentNetworkPrefix}', ipAddress);
      
      if (kDebugMode) {
        print('IP estática guardada para red $_currentNetworkPrefix: $ipAddress');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar IP estática para la red: $e');
      }
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
      
      // También guardar como IP estática para la red actual
      if (_currentNetworkPrefix != null) {
        saveStaticIpForNetwork(ipAddress);
      }
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
      
      // Extraer la dirección IP de la URL
      final ipAddress = _extractIpFromUrl(validatedUrl);
      if (ipAddress != null) {
        await saveStaticIpForNetwork(ipAddress);
      }
      
      if (kDebugMode) {
        print('Configuración ESP32 actualizada: $validatedUrl');
      }
    }
  }
  
  // Extraer la dirección IP de una URL
  static String? _extractIpFromUrl(String url) {
    try {
      // Formato esperado: http://192.168.1.x/api
      final uri = Uri.parse(url);
      final host = uri.host;
      
      // Verificar si es una dirección IP válida
      final ipRegex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
      if (ipRegex.hasMatch(host)) {
        return host;
      }
      return null;
    } catch (e) {
      return null;
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
  
  // Listar todas las redes WiFi con IPs estáticas configuradas
  static Future<Map<String, String>> getConfiguredStaticIPs() async {
    final Map<String, String> result = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      for (final key in allKeys) {
        if (key.startsWith('${_staticIpKey}_')) {
          final networkPrefix = key.substring('${_staticIpKey}_'.length);
          final ipAddress = prefs.getString(key);
          if (ipAddress != null && ipAddress.isNotEmpty) {
            result[networkPrefix] = ipAddress;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener IPs estáticas configuradas: $e');
      }
    }
    return result;
  }

  // Borrar una IP estática para una red específica
  static Future<bool> deleteStaticIpForNetwork(String networkPrefix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove('${_staticIpKey}_$networkPrefix');
      
      if (kDebugMode) {
        print('IP estática para red $networkPrefix ${success ? "eliminada" : "no se pudo eliminar"}');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error al eliminar IP estática para la red: $e');
      }
      return false;
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
