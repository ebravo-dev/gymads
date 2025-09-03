import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import '../config/rfid_config.dart';

/// Servicio para manejar la comunicación Bluetooth con el ESP32
/// Nota: El ESP32 usa Bluetooth Classic (Serial), pero adaptamos con BLE
class BluetoothService {
  static fbp.BluetoothDevice? _connectedDevice;
  static fbp.BluetoothCharacteristic? _writeCharacteristic;
  static StreamSubscription<List<int>>? _readSubscription;
  static final StreamController<String> _responseController = StreamController<String>.broadcast();
  
  // Nombre del dispositivo ESP32
  static const String ESP32_DEVICE_NAME = "ESP32_RFID_GYMADS";
  
  // Estados de conexión
  static bool get isConnected => _connectedDevice != null;
  static String? _currentESP32IP;
  static String? get currentIP => _currentESP32IP;
  
  /// Inicializar Bluetooth y verificar permisos
  static Future<bool> initialize() async {
    try {
      // Verificar permisos de Bluetooth
      if (!await _checkBluetoothPermissions()) {
        if (kDebugMode) {
          print('Permisos de Bluetooth denegados');
        }
        return false;
      }
      
      // Verificar si Bluetooth está habilitado
      if (await fbp.FlutterBluePlus.isSupported == false) {
        if (kDebugMode) {
          print('Bluetooth no es compatible con este dispositivo');
        }
        return false;
      }
      
      // Verificar estado del adaptador
      fbp.BluetoothAdapterState adapterState = await fbp.FlutterBluePlus.adapterState.first;
      if (adapterState != fbp.BluetoothAdapterState.on) {
        if (kDebugMode) {
          print('Bluetooth no está habilitado');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('Bluetooth inicializado correctamente');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar Bluetooth: $e');
      }
      return false;
    }
  }
  
  /// Verificar permisos de Bluetooth
  static Future<bool> _checkBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();
    
    return statuses.values.every((status) => status == PermissionStatus.granted);
  }
  
  /// Habilitar Bluetooth si no está activo
  static Future<bool> enableBluetooth() async {
    try {
      fbp.BluetoothAdapterState adapterState = await fbp.FlutterBluePlus.adapterState.first;
      if (adapterState != fbp.BluetoothAdapterState.on) {
        // Flutter Blue Plus no puede habilitar Bluetooth directamente
        // El usuario debe habilitarlo manualmente
        if (kDebugMode) {
          print('Bluetooth deshabilitado. El usuario debe habilitarlo manualmente.');
        }
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar estado de Bluetooth: $e');
      }
      return false;
    }
  }
  
  /// Buscar dispositivos ESP32 disponibles
  static Future<List<fbp.BluetoothDevice>> findESP32Devices() async {
    try {
      if (kDebugMode) {
        print('Buscando dispositivos ESP32...');
      }
      
      List<fbp.BluetoothDevice> esp32Devices = [];
      
      // Buscar en dispositivos conectados
      List<fbp.BluetoothDevice> connectedDevices = fbp.FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        String deviceName = device.platformName.isNotEmpty ? device.platformName : device.advName;
        if (deviceName.contains(ESP32_DEVICE_NAME)) {
          esp32Devices.add(device);
          if (kDebugMode) {
            print('ESP32 encontrado en dispositivos conectados: $deviceName');
          }
        }
      }
      
      // Si no hay dispositivos conectados, buscar nuevos dispositivos
      if (esp32Devices.isEmpty) {
        if (kDebugMode) {
          print('Iniciando búsqueda de nuevos dispositivos...');
        }
        
        // Verificar si ya está escaneando
        if (fbp.FlutterBluePlus.isScanningNow) {
          await fbp.FlutterBluePlus.stopScan();
        }
        
        // Iniciar escaneo
        await fbp.FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 15),
        );
        
        // Escuchar resultados del escaneo
        await for (List<fbp.ScanResult> results in fbp.FlutterBluePlus.scanResults) {
          for (fbp.ScanResult result in results) {
            String deviceName = result.device.platformName.isNotEmpty ? 
                                result.device.platformName : result.device.advName;
            
            if (deviceName.contains(ESP32_DEVICE_NAME)) {
              esp32Devices.add(result.device);
              if (kDebugMode) {
                print('ESP32 encontrado: $deviceName (RSSI: ${result.rssi})');
              }
            }
          }
          
          // Si encontramos al menos un dispositivo, parar búsqueda
          if (esp32Devices.isNotEmpty) {
            await fbp.FlutterBluePlus.stopScan();
            break;
          }
        }
        
        // Asegurar que el escaneo se detiene
        if (fbp.FlutterBluePlus.isScanningNow) {
          await fbp.FlutterBluePlus.stopScan();
        }
      }
      
      if (kDebugMode) {
        print('Búsqueda completada. ${esp32Devices.length} dispositivos ESP32 encontrados');
      }
      
      return esp32Devices;
    } catch (e) {
      if (kDebugMode) {
        print('Error al buscar dispositivos ESP32: $e');
      }
      if (fbp.FlutterBluePlus.isScanningNow) {
        await fbp.FlutterBluePlus.stopScan();
      }
      return [];
    }
  }
  
  /// Conectar al ESP32
  static Future<bool> connectToESP32(fbp.BluetoothDevice device) async {
    try {
      String deviceName = device.platformName.isNotEmpty ? device.platformName : device.advName;
      if (kDebugMode) {
        print('Conectando a $deviceName...');
      }
      
      // Desconectar conexión anterior si existe
      await disconnect();
      
      // Conectar al dispositivo
      await device.connect(timeout: const Duration(seconds: 20));
      _connectedDevice = device;
      
      if (kDebugMode) {
        print('Conexión establecida, descubriendo servicios...');
      }
      
      // Descubrir servicios
      List<fbp.BluetoothService> services = await device.discoverServices();
      
      bool servicesFound = false;
      
      // Buscar servicios UART/Serial comunes del ESP32
      for (fbp.BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toUpperCase();
        
        if (kDebugMode) {
          print('Servicio encontrado: $serviceUuid');
        }
        
        // UUIDs comunes para ESP32 Bluetooth Serial:
        // - Nordic UART Service: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
        // - ESP32 Serial: 0000FFE0-0000-1000-8000-00805F9B34FB
        // - Standard Serial Port: 00001101-0000-1000-8000-00805F9B34FB
        if (serviceUuid.contains("6E400001") ||
            serviceUuid.contains("FFE0") ||
            serviceUuid.contains("1101")) {
          
          for (fbp.BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toUpperCase();
            
            if (kDebugMode) {
              print('Característica: $charUuid - Props: ${characteristic.properties}');
            }
            
            // Característica de escritura (TX desde la app)
            if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
              _writeCharacteristic = characteristic;
              if (kDebugMode) {
                print('Característica de escritura configurada: $charUuid');
              }
              servicesFound = true;
            }
            
            // Característica de lectura/notificación (RX en la app)
            if (characteristic.properties.read || characteristic.properties.notify || characteristic.properties.indicate) {
              // Habilitar notificaciones para recibir datos
              if (characteristic.properties.notify || characteristic.properties.indicate) {
                await characteristic.setNotifyValue(true);
                
                // Configurar listener para respuestas
                _readSubscription = characteristic.lastValueStream.listen(
                  (data) {
                    String receivedData = utf8.decode(data);
                    _responseController.add(receivedData);
                    if (kDebugMode) {
                      print('Datos recibidos del ESP32: $receivedData');
                    }
                  },
                  onError: (error) {
                    if (kDebugMode) {
                      print('Error en stream de lectura: $error');
                    }
                  },
                );
              }
              
              if (kDebugMode) {
                print('Característica de lectura configurada: $charUuid');
              }
              servicesFound = true;
            }
          }
          
          if (servicesFound) break;
        }
      }
      
      if (!servicesFound || _writeCharacteristic == null) {
        if (kDebugMode) {
          print('No se encontraron servicios UART válidos');
        }
        await disconnect();
        return false;
      }
      
      if (kDebugMode) {
        print('Conexión Bluetooth establecida exitosamente con $deviceName');
      }
      
      // Verificar estado inicial
      await Future.delayed(const Duration(milliseconds: 500));
      await _sendInitialStatusCheck();
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error al conectar con ESP32: $e');
      }
      await disconnect();
      return false;
    }
  }
  
  /// Verificación inicial del estado del ESP32
  static Future<void> _sendInitialStatusCheck() async {
    try {
      var status = await getESP32Status();
      if (status != null) {
        if (status['wifi_connected'] == true) {
          _currentESP32IP = status['ip_address'];
          if (kDebugMode) {
            print('ESP32 ya conectado a WiFi. IP: $_currentESP32IP');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error en verificación inicial: $e');
      }
    }
  }
  
  /// Desconectar del ESP32
  static Future<void> disconnect() async {
    try {
      // Cancelar subscripción de lectura
      if (_readSubscription != null) {
        await _readSubscription!.cancel();
        _readSubscription = null;
      }
      
      // Desconectar dispositivo
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
        _currentESP32IP = null;
        
        if (kDebugMode) {
          print('Conexión Bluetooth cerrada');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cerrar conexión Bluetooth: $e');
      }
    }
  }
  
  /// Limpiar recursos al cerrar la aplicación
  static Future<void> dispose() async {
    await disconnect();
    await _responseController.close();
  }
  
  /// Enviar comando JSON al ESP32
  static Future<Map<String, dynamic>?> sendCommand(Map<String, dynamic> command) async {
    if (!isConnected || _writeCharacteristic == null) {
      if (kDebugMode) {
        print('No hay conexión Bluetooth activa');
      }
      return null;
    }
    
    try {
      String jsonCommand = jsonEncode(command);
      if (kDebugMode) {
        print('Enviando comando: $jsonCommand');
      }
      
      // Convertir string a bytes y añadir nueva línea
      List<int> bytes = utf8.encode('$jsonCommand\n');
      
      // Enviar comando
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      
      // Esperar respuesta con timeout mejorado
      Map<String, dynamic>? response = await _waitForResponse(timeout: 15);
      
      if (response != null) {
        // Si recibimos una IP nueva, guardarla
        if (response.containsKey('ip_address') && response['ip_address'] != null) {
          String? newIP = response['ip_address'];
          if (newIP != null && newIP.isNotEmpty && newIP != _currentESP32IP) {
            _currentESP32IP = newIP;
            if (kDebugMode) {
              print('IP del ESP32 actualizada: $_currentESP32IP');
            }
          }
        }
        
        if (kDebugMode) {
          print('Respuesta recibida: $response');
        }
        return response;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error al enviar comando: $e');
      }
      return null;
    }
  }
  
  /// Esperar respuesta del ESP32 con timeout configurable
  static Future<Map<String, dynamic>?> _waitForResponse({int timeout = 10}) async {
    try {
      if (!isConnected) {
        if (kDebugMode) {
          print('No hay conexión activa para recibir respuesta');
        }
        return null;
      }
      
      String buffer = '';
      
      // Usar el stream controller para recibir datos
      await for (String receivedData in _responseController.stream.timeout(
        Duration(seconds: timeout),
        onTimeout: (sink) {
          if (kDebugMode) {
            print('Timeout esperando respuesta del ESP32');
          }
          sink.close();
        },
      )) {
        buffer += receivedData;
        
        // Buscar JSON completo
        int startIndex = buffer.indexOf('{');
        if (startIndex != -1) {
          int braceCount = 0;
          int endIndex = -1;
          
          for (int i = startIndex; i < buffer.length; i++) {
            if (buffer[i] == '{') braceCount++;
            if (buffer[i] == '}') braceCount--;
            
            if (braceCount == 0) {
              endIndex = i;
              break;
            }
          }
          
          if (endIndex != -1) {
            String jsonStr = buffer.substring(startIndex, endIndex + 1);
            try {
              Map<String, dynamic> response = jsonDecode(jsonStr);
              return response;
            } catch (e) {
              if (kDebugMode) {
                print('Error al decodificar JSON: $e');
                print('JSON problemático: $jsonStr');
              }
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error al esperar respuesta: $e');
      }
      return null;
    }
  }
  
  /// Escanear redes WiFi via Bluetooth
  static Future<List<Map<String, dynamic>>> scanWiFiNetworks() async {
    var response = await sendCommand({'command': 'scan_wifi'});
    
    if (response != null && response['status'] == 'success') {
      List<dynamic> networks = response['networks'] ?? [];
      return networks.cast<Map<String, dynamic>>();
    }
    
    return [];
  }
  
  /// Conectar a WiFi via Bluetooth
  static Future<bool> connectToWiFi(String ssid, String password) async {
    try {
      if (kDebugMode) {
        print('Iniciando conexión WiFi a: $ssid');
      }
      
      var response = await sendCommand({
        'command': 'connect_wifi',
        'ssid': ssid,
        'password': password
      });
      
      if (response != null) {
        if (response['status'] == 'connecting') {
          if (kDebugMode) {
            print('ESP32 está conectando a WiFi...');
          }
          
          // Esperar un poco más para que el ESP32 se conecte
          await Future.delayed(const Duration(seconds: 8));
          
          // Solicitar la IP actual varias veces si es necesario
          String? ipAddress;
          for (int attempt = 0; attempt < 3; attempt++) {
            ipAddress = await getESP32IP();
            if (ipAddress != null && ipAddress.isNotEmpty) {
              break;
            }
            await Future.delayed(const Duration(seconds: 2));
          }
          
          if (ipAddress != null && ipAddress.isNotEmpty) {
            _currentESP32IP = ipAddress;
            
            // Actualizar configuración inmediatamente
            RfidConfig.forceUpdateIP(ipAddress);
            
            if (kDebugMode) {
              print('WiFi conectado exitosamente. IP: $_currentESP32IP');
            }
            return true;
          } else {
            if (kDebugMode) {
              print('No se pudo obtener IP válida del ESP32');
            }
          }
        } else if (response['status'] == 'success') {
          // Ya está conectado, obtener IP
          String? ipAddress = response['ip_address'];
          if (ipAddress != null && ipAddress.isNotEmpty) {
            _currentESP32IP = ipAddress;
            
            // Actualizar configuración inmediatamente
            RfidConfig.forceUpdateIP(ipAddress);
            
            if (kDebugMode) {
              print('WiFi ya estaba conectado. IP: $_currentESP32IP');
            }
            return true;
          }
        }
      }
      
      if (kDebugMode) {
        print('No se pudo conectar a WiFi o no se obtuvo IP válida');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error al conectar WiFi: $e');
      }
      return false;
    }
  }
  
  /// Obtener IP actual del ESP32
  static Future<String?> getESP32IP() async {
    try {
      var response = await sendCommand({'command': 'get_ip'});
      
      if (response != null && response['wifi_connected'] == true) {
        String? ipAddress = response['ip_address'];
        if (ipAddress != null && ipAddress.isNotEmpty) {
          // Actualizar IP guardada si es nueva
          if (ipAddress != _currentESP32IP) {
            _currentESP32IP = ipAddress;
            
            // Actualizar configuración de RfidConfig inmediatamente
            RfidConfig.forceUpdateIP(ipAddress);
            
            if (kDebugMode) {
              print('IP del ESP32 actualizada: $_currentESP32IP');
            }
          }
          return ipAddress;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener IP del ESP32: $e');
      }
      return null;
    }
  }
  
  /// Monitorear cambios de IP del ESP32 (para llamar periódicamente)
  static Future<String?> checkForIPChanges() async {
    if (!isConnected) {
      return null;
    }
    
    try {
      String? currentIP = await getESP32IP();
      
      if (currentIP != null && currentIP != _currentESP32IP) {
        String? oldIP = _currentESP32IP;
        _currentESP32IP = currentIP;
        
        // Actualizar configuración de RfidConfig
        RfidConfig.forceUpdateIP(currentIP);
        
        if (kDebugMode) {
          print('IP del ESP32 cambió de $oldIP a $_currentESP32IP');
        }
      }
      
      return _currentESP32IP;
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar cambios de IP: $e');
      }
      return null;
    }
  }
  
  /// Obtener estado completo del ESP32
  static Future<Map<String, dynamic>?> getESP32Status() async {
    try {
      var response = await sendCommand({'command': 'get_status'});
      
      if (response != null) {
        // Actualizar IP si está disponible
        if (response.containsKey('ip_address') && response['ip_address'] != null) {
          String? ipAddress = response['ip_address'];
          if (ipAddress != null && ipAddress.isNotEmpty) {
            _currentESP32IP = ipAddress;
          }
        }
      }
      
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error al obtener estado del ESP32: $e');
      }
      return null;
    }
  }
  
  /// Resetear configuración WiFi del ESP32
  static Future<bool> resetWiFiConfig() async {
    try {
      var response = await sendCommand({'command': 'reset_wifi'});
      
      if (response != null && response['status'] == 'success') {
        _currentESP32IP = null; // Limpiar IP guardada
        if (kDebugMode) {
          print('Configuración WiFi del ESP32 reseteada');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error al resetear configuración WiFi: $e');
      }
      return false;
    }
  }
  
  /// Verificar si el ESP32 está conectado a WiFi
  static Future<bool> isESP32ConnectedToWiFi() async {
    try {
      var status = await getESP32Status();
      return status != null && status['wifi_connected'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error al verificar conexión WiFi del ESP32: $e');
      }
      return false;
    }
  }
}
