# ESP32 RFID - Arquitectura Bluetooth para Configuración

## 📋 Resumen de Cambios

La nueva versión del firmware ESP32 RFID ha migrado de **WiFi Access Point** a **Bluetooth Classic** para la configuración inicial. Esto elimina la complejidad de descubrir IPs dinámicas y proporciona una comunicación más confiable.

## 🔄 Arquitectura Anterior vs Nueva

### ❌ Arquitectura Anterior (Access Point)
```
1. ESP32 crea Access Point WiFi
2. App se conecta al AP
3. App configura WiFi principal
4. ESP32 se desconecta del AP y se conecta a WiFi
5. ⚠️ App debe "descubrir" la nueva IP del ESP32
6. ⚠️ Si cambia IP, se pierde conexión
```

### ✅ Nueva Arquitectura (Bluetooth)
```
1. ESP32 activa Bluetooth clásico
2. App se conecta via Bluetooth
3. App configura WiFi via Bluetooth
4. ESP32 se conecta a WiFi
5. ESP32 envía IP via Bluetooth
6. ✅ Comunicación persistente via Bluetooth
7. ✅ HTTP directo con IP conocida
```

## 📱 Protocolo de Comunicación Bluetooth

### Comandos JSON Soportados

#### 1. Escanear Redes WiFi
```json
{
  "command": "scan_wifi"
}
```

**Respuesta:**
```json
{
  "status": "success",
  "command": "scan_wifi",
  "count": 5,
  "networks": [
    {
      "ssid": "MiWiFi",
      "rssi": -45,
      "secure": true
    }
  ]
}
```

#### 2. Conectar a WiFi
```json
{
  "command": "connect_wifi",
  "ssid": "MiWiFi",
  "password": "mipassword"
}
```

**Respuesta:**
```json
{
  "status": "success",
  "command": "get_ip",
  "wifi_connected": true,
  "ip_address": "192.168.1.100",
  "ssid": "MiWiFi",
  "rssi": -45,
  "mac_address": "AA:BB:CC:DD:EE:FF"
}
```

#### 3. Obtener IP Actual
```json
{
  "command": "get_ip"
}
```

#### 4. Obtener Estado del Sistema
```json
{
  "command": "get_status"
}
```

**Respuesta:**
```json
{
  "status": "success",
  "command": "get_status",
  "device_id": "ESP32_RFID_GYMADS",
  "wifi_connected": true,
  "bluetooth_enabled": true,
  "bluetooth_client_connected": true,
  "uptime": 120000,
  "last_rfid_uid": "1A2B3C4D",
  "ip_address": "192.168.1.100",
  "ssid": "MiWiFi"
}
```

#### 5. Resetear Configuración WiFi
```json
{
  "command": "reset_wifi"
}
```

## 🔧 Características Técnicas

### Hardware Requerido
- **ESP32** con Bluetooth Classic
- **MFRC522** (Lector RFID)
- **5 LEDs** para indicadores de estado:
  - `LED_WIFI (Pin 2)`: Estado WiFi
  - `LED_BLUETOOTH (Pin 12)`: Estado Bluetooth
  - `LED_VERDE (Pin 4)`: Membresía activa
  - `LED_AMARILLO (Pin 15)`: Membresía por vencer
  - `LED_ROJO (Pin 22)`: Membresía vencida/no encontrada

### Librerías Necesarias
```cpp
#include <SPI.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include "BluetoothSerial.h"
```

### Configuración Bluetooth
- **Nombre del dispositivo**: `ESP32_RFID_GYMADS`
- **Tipo**: Bluetooth Classic (SPP)
- **Emparejamiento**: Automático

## 💡 Estados de LEDs

### LED WiFi (Pin 2)
- **Apagado**: Sin conexión WiFi
- **Parpadeando**: Conectando a WiFi
- **Encendido sólido**: WiFi conectado

### LED Bluetooth (Pin 12)
- **Parpadeando lento**: Bluetooth habilitado, esperando conexión
- **Encendido sólido**: Cliente Bluetooth conectado

### LEDs de Membresía
- **Verde**: Membresía activa
- **Amarillo**: Membresía por vencer
- **Rojo**: Membresía vencida o no encontrada

## 🔄 Flujo de Operación

### 1. Inicio del Sistema
```
1. Inicializar RFID
2. Activar Bluetooth
3. Cargar credenciales WiFi guardadas
4. Si hay credenciales: conectar a WiFi
5. Si WiFi OK: iniciar servidor HTTP
6. Sistema listo para operar
```

### 2. Modo Configuración (Primera vez)
```
1. ESP32 visible como "ESP32_RFID_GYMADS"
2. App Flutter se conecta via Bluetooth
3. App escanea redes WiFi via Bluetooth
4. Usuario selecciona red y proporciona password
5. ESP32 se conecta a WiFi
6. ESP32 envía IP via Bluetooth
7. App guarda IP para comunicación HTTP directa
```

### 3. Modo Operación Normal
```
1. RFID detecta tarjeta
2. App consulta UID via HTTP (usando IP conocida)
3. App verifica membresía en Supabase
4. App envía estado via HTTP
5. ESP32 controla LEDs según estado
```

### 4. Reconexión Automática
```
1. Si WiFi se desconecta: intento automático de reconexión
2. Si falla: Bluetooth disponible para reconfiguración
3. No requiere descubrimiento de IP - se mantiene comunicación directa
```

## 🚀 Ventajas de la Nueva Arquitectura

### ✅ Ventajas Principales
1. **Eliminación de descubrimiento de IP**: Bluetooth proporciona IP directamente
2. **Comunicación persistente**: Bluetooth siempre disponible para reconfiguración
3. **Setup más simple**: Un solo emparejamiento Bluetooth
4. **Mejor confiabilidad**: Menos puntos de falla en la conexión
5. **Diagnósticos mejorados**: Estado completo via Bluetooth
6. **Reconexión automática**: WiFi se reconecta automáticamente
7. **Backup de comunicación**: Si WiFi falla, Bluetooth sigue disponible

### 🔧 Beneficios Técnicos
- **Menor latencia de setup**: No hay que cambiar entre redes WiFi
- **Mejor UX**: Usuario no necesita cambiar WiFi del teléfono
- **Más robusto**: Tolerante a cambios de IP del router
- **Escalable**: Fácil agregar más ESP32 sin conflictos de IP

## 📝 Próximos Pasos para Flutter

1. **Crear BluetoothService**: Servicio para comunicación Bluetooth
2. **Integrar flutter_bluetooth_serial**: Plugin para Bluetooth Classic
3. **Actualizar RfidConfig**: Usar Bluetooth en lugar de descubrimiento
4. **UI de configuración Bluetooth**: Pantalla para emparejamiento y setup
5. **Mantener compatibilidad HTTP**: Para operación normal una vez configurado

## 🔍 API HTTP (Modo Operación)

Una vez configurado via Bluetooth, el ESP32 mantiene las mismas rutas HTTP:

- `GET /api/uid`: Obtener último UID leído
- `GET /api/status`: Estado del sistema
- `POST /api/membership`: Enviar estado de membresía
- `GET /api/discover`: Información de identificación

**La diferencia es que ahora la IP se obtiene via Bluetooth, no por descubrimiento de red.**
