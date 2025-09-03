import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/rfid_config.dart';

class RfidReaderService {
  // Método para verificar si hay un UID disponible desde el ESP32
  static Future<String?> checkForCard() async {
    try {
      // Verificar si hay configuración disponible
      if (!RfidConfig.isConfigured) {
        if (kDebugMode) {
          print('ESP32 no configurado - se requiere configuración via Bluetooth');
        }
        return null;
      }
      
      final baseUrl = RfidConfig.baseUrl;
      if (baseUrl == null) {
        if (kDebugMode) {
          print('No hay URL configurada para el ESP32');
        }
        return null;
      }
      
      if (kDebugMode) {
        print('Verificando tarjeta RFID en: $baseUrl/uid');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/uid'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final responseText = response.body.trim();
        
        if (responseText.isNotEmpty && responseText != "NO_CARD") {
          if (kDebugMode) {
            print('UID detectado: $responseText');
          }
          return responseText;
        }
        return null;
      } else {
        if (kDebugMode) {
          print('Error al verificar tarjeta: ${response.statusCode}');
          print('Respuesta: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar tarjeta: $e');
        print('Asegúrate de que el ESP32 esté encendido y configurado via Bluetooth');
      }
      return null;
    }
  }
  
  // Método para iniciar la lectura (ya no necesario con el nuevo enfoque, pero mantenido para compatibilidad)
  static Future<bool> startReading() async {
    try {
      // Verificar si hay configuración disponible
      if (!RfidConfig.isConfigured) {
        if (kDebugMode) {
          print('ESP32 no configurado - se requiere configuración via Bluetooth');
        }
        return false;
      }
      
      final baseUrl = RfidConfig.baseUrl;
      if (baseUrl == null) {
        if (kDebugMode) {
          print('No hay URL configurada para el ESP32');
        }
        return false;
      }
      
      // Simplemente verificamos si podemos conectarnos al ESP32
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error al comunicarse con el lector RFID: $e');
        print('Asegúrate de que el ESP32 esté configurado via Bluetooth');
      }
      return false;
    }
  }
  
  // Método para enviar el estado de membresía al ESP32
  static Future<bool> sendMembershipStatus(String uid, String status) async {
    try {
      // Verificar si hay configuración disponible
      if (!RfidConfig.isConfigured) {
        if (kDebugMode) {
          print('ESP32 no configurado - no se puede enviar estado de membresía');
        }
        return false;
      }
      
      final baseUrl = RfidConfig.baseUrl;
      if (baseUrl == null) {
        if (kDebugMode) {
          print('No hay URL configurada para el ESP32');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('Enviando estado de membresía al ESP32: UID=$uid, Status=$status');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/membership'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Estado de membresía enviado correctamente');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Error al enviar estado de membresía: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al enviar estado de membresía: $e');
      }
      return false;
    }
  }
  
  // Este es el fin de la clase RfidReaderService
}
