import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/rfid_config.dart';

class RfidReaderService {
  // Método para verificar si hay un UID disponible desde el ESP32
  static Future<String?> checkForCard() async {
    try {
      if (kDebugMode) {
        print('Verificando tarjeta RFID en: ${RfidConfig.baseUrl}/uid');
      }

      final response = await http.get(
        Uri.parse('${RfidConfig.baseUrl}/uid'),
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
        print('Asegúrate de que el ESP32 esté encendido y en la misma red WiFi');
        print('URL configurada: ${RfidConfig.baseUrl}');
      }
      return null;
    }
  }
  
  // Método para iniciar la lectura (ya no necesario con el nuevo enfoque, pero mantenido para compatibilidad)
  static Future<bool> startReading() async {
    try {
      // Simplemente verificamos si podemos conectarnos al ESP32
      final response = await http.get(
        Uri.parse('${RfidConfig.baseUrl}/status'),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error al comunicarse con el lector RFID: $e');
        print('Asegúrate de que el ESP32 esté encendido y en la misma red WiFi');
        print('URL configurada: ${RfidConfig.baseUrl}');
      }
      return false;
    }
  }
  
  // Este es el fin de la clase RfidReaderService
}
