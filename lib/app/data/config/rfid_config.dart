import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Clase para manejar la configuración del lector RFID ESP32
class RfidConfig {
  // URL del ESP32 (por defecto es la IP local que proporcionaste)
  static String get baseUrl => dotenv.env['ESP32_API_URL'] ?? 'http://192.168.1.136/api';
  
  // Método para actualizar la configuración (útil si cambia la IP)
  static void updateConfig({String? newUrl}) {
    if (newUrl != null) {
      dotenv.env['ESP32_API_URL'] = newUrl;
      if (kDebugMode) {
        print('URL del ESP32 actualizada a: $newUrl');
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
