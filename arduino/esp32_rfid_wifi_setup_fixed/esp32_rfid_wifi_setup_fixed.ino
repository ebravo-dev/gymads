/*
 * GYMADS - ESP32 RFID Reader con WiFi
 * LECTOR RFID CON CONEXIÓN WIFI AUTOMÁTICA PARA GYMADS
 * 
 * Versión 4.2.0 - Solo WiFi (Sin Bluetooth) - PN532 + HCE
 * Dispositivo: ESP32
 * 
 * Función: Leer tarjetas RFID físicas y emulación HCE (Host Card Emulation)
 * Sistema simplificado para lectura de tarjetas RFID con conectividad WiFi
 * Versión: 4.2.0 - WiFi automático sin Bluetooth + IP estática mejorada + Anti-rebote RFID + PN532 + Soporte HCE
 * 
 * Credenciales WiFi hardcodeadas para máxima simplicidad
 * 
 * MEJORAS v4.2.0:
 * - Soporte completo para HCE con activación ISO14443-4 (RATS)
 * - Detecta automáticamente tarjeta física o emulación HCE
 * - Secuencia: RATS → SELECT → GET DATA
 * - Pines: SDA en GPIO 21, SCL en GPIO 22
 * - Anti-rebote RFID (3 segundos entre lecturas)
 * - Logs simplificados y concisos
 */

#include <Wire.h>
#include <PN532_I2C.h>
#include <PN532.h>

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// =================== CONFIGURACIÓN HCE (APDU) ===================
// AID (Application ID) para la app de emulación HCE
const uint8_t AID[] = {0xF0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06};
const uint8_t AID_LENGTH = 7;

// Comandos APDU
const uint8_t APDU_SELECT[] = {
  0x00,  // CLA (Class)
  0xA4,  // INS (Instruction: SELECT)
  0x04,  // P1 (Parameter 1)
  0x00,  // P2 (Parameter 2)
  0x07,  // Lc (Length: 7 bytes)
  0xF0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06,  // AID
  0x00   // Le (Expected response length)
};

const uint8_t APDU_GET_DATA[] = {
  0x00,  // CLA (Class)
  0xCA,  // INS (Instruction: GET DATA)
  0x00,  // P1 (Parameter 1)
  0x00,  // P2 (Parameter 2)
  0x00   // Le (Expected response length)
};

// =================== CONFIGURACIÓN WIFI ===================
// TODO: Cambiar estas credenciales por las de tu red WiFi
const char* WIFI_SSID = "FamiliaBlanco";
const char* WIFI_PASSWORD = "*E2d0e0r4";

// =================== CONFIGURACIÓN DE ESCANEO RFID ===================
// Intervalo mínimo entre lecturas de la misma tarjeta (en milisegundos)
// Aumenta este valor si necesitas más tiempo entre lecturas
// Por defecto: 3000 ms (3 segundos)
const unsigned long CARD_READ_INTERVAL_MS = 3000;

// =================== CONFIGURACIÓN DE IP ESTÁTICA ===================
// Configuración de IP estática
bool useStaticIP = true;  // Establecer a false para usar DHCP
IPAddress staticIP(192, 168, 68, 108);  // IP estática que quieres asignar al ESP32
IPAddress gateway(192, 168, 68, 1);     // IP del router (puerta de enlace)
IPAddress subnet(255, 255, 255, 0);    // Máscara de subred
IPAddress dns(8, 8, 8, 8);             // Servidor DNS (Google)

// =================== PINES DEL HARDWARE ===================
// Pines del lector RFID PN532 (I2C)
#define PN532_SDA     21   // GPIO 21
#define PN532_SCL     22   // GPIO 22

// Pines de LEDs indicadores
#define LED_WIFI      2    // LED integrado del ESP32
#define LED_VERDE     15   // Membresía activa (cambiado de 21)
#define LED_AMARILLO  18   // Membresía por vencer (cambiado de 22)
#define LED_ROJO      5   // Membresía vencida/no encontrada

// =================== ESTADOS DE MEMBRESÍA ===================
#define MEMBERSHIP_ACTIVE      "active"
#define MEMBERSHIP_EXPIRING    "expiring"
#define MEMBERSHIP_EXPIRED     "expired"
#define MEMBERSHIP_NOT_FOUND   "not_found"

// =================== VARIABLES GLOBALES ===================
// Objetos principales
// IMPORTANTE: PN532_I2C debe inicializarse DESPUÉS de Wire.begin()
// Por eso se inicializa en setup(), aquí solo declaramos los punteros
PN532_I2C *pn532i2c;
PN532 *nfc;
WebServer server(80);

// Variables de estado
bool wifiConnected = false;
String lastUid = "NO_CARD";
bool lastWasHCE = false;  // Indica si la última lectura fue de HCE o tarjeta física
String networkType = "none";  // Tipo de red: "static", "dhcp", "none"
bool staticIPConfigured = false; // Indica si se aplicó correctamente la IP estática

// Variables para control de tiempos de LEDs
unsigned long ledStateTimeout = 0;
const unsigned long LED_TIMEOUT = 3000;  // LEDs de estado se apagan después de 3 segundos

// Variables para control de escaneo RFID (evitar lecturas duplicadas)
unsigned long lastCardReadTime = 0;
String lastScannedCard = "";

// Variables para reintento de conexión WiFi
const unsigned long WIFI_CHECK_INTERVAL = 10000; // 10 segundos
const int MAX_CONNECTION_RETRIES = 3; // Número máximo de reintentos antes de recurrir a DHCP
int connectionRetries = 0;

// =================== DECLARACIONES DE FUNCIONES ===================
void connectToWiFi();
bool setupStaticIP();
void setupServerRoutes();
void handleGetUid();
void handleStatus();
void handleDiscover();
void handleMembershipStatus();
void controlStatusLeds(String status);
void handleStatusLeds();
void turnOffAllStatusLeds();
void testLedSequence();
String getCardUID(uint8_t* uid, uint8_t uidLength);
String getNetworkInfo();
bool isStaticIPConfigured();
bool tryReadHCE(String &uid);
bool detectNFCDevice();

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("=== GYMADS v4.2.0 ===");
  Serial.println("PN532 + HCE Support");

  // Configurar LEDs
  pinMode(LED_WIFI, OUTPUT);
  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_ROJO, OUTPUT);
  pinMode(LED_AMARILLO, OUTPUT);

  // Apagar todos los LEDs al inicio
  digitalWrite(LED_WIFI, LOW);
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_AMARILLO, LOW);

  // Inicializar I2C para PN532
  Serial.println("Init I2C...");
  Wire.begin(PN532_SDA, PN532_SCL);
  Wire.setClock(100000);
  delay(500);  // Delay más largo para que el PN532 se inicialice
  
  // IMPORTANTE: Crear los objetos PN532 DESPUÉS de Wire.begin()
  Serial.println("Init PN532 objects...");
  pn532i2c = new PN532_I2C(Wire);
  nfc = new PN532(*pn532i2c);
  
  // Inicializar lector RFID PN532
  Serial.println("Init PN532...");
  nfc->begin();
  delay(500);
  
  uint32_t versiondata = nfc->getFirmwareVersion();
  if (!versiondata) {
    Serial.println("ERROR: PN532 no encontrado");
    Serial.println("Verifica: SDA->21, SCL->22, VCC->3.3V");
  } else {
    Serial.print("PN532 OK - FW v");
    Serial.print((versiondata >> 16) & 0xFF);
    Serial.print(".");
    Serial.println((versiondata >> 8) & 0xFF);
    nfc->SAMConfig();
  }

  // Conectar a WiFi
  connectToWiFi();

  // Configurar servidor HTTP si está conectado
  if (wifiConnected) {
    setupServerRoutes();
    server.begin();
    Serial.print("HTTP Server: ");
    Serial.println(WiFi.localIP());
  }

  testLedSequence();
  Serial.println("=== SISTEMA LISTO ===");
}

void loop() {
  // Manejar solicitudes del servidor HTTP (si WiFi está conectado)
  if (wifiConnected) {
    server.handleClient();
  }

  // Manejar LEDs de estado
  handleStatusLeds();

  // Solo procesar RFID si estamos conectados a WiFi
  if (wifiConnected) {
    String cardUid = "";
    bool cardDetected = false;
    bool isHCE = false;
    
    // PASO 1: Detectar dispositivo NFC sin leer UID automáticamente
    // Usar inListPassiveTarget() en lugar de readPassiveTargetID()
    // Esto permite que HCE responda antes de leer el UID físico
    if (detectNFCDevice()) {
      // PASO 2: Primero intentar leer como HCE usando comandos APDU
      if (tryReadHCE(cardUid)) {
        cardDetected = true;
        isHCE = true;
      } else {
        // No es HCE, leer el UID físico de la tarjeta
        uint8_t uid[] = { 0, 0, 0, 0, 0, 0, 0 };
        uint8_t uidLength;
        if (nfc->readPassiveTargetID(PN532_MIFARE_ISO14443A, uid, &uidLength)) {
          cardUid = getCardUID(uid, uidLength);
          cardDetected = true;
          isHCE = false;
        }
      }
      
      unsigned long currentTime = millis();

      // Verificar si ha pasado suficiente tiempo desde la última lectura
      // O si es una tarjeta diferente
      bool canRead = false;
      
      if (cardUid != lastScannedCard) {
        // Es una tarjeta diferente, siempre permitir lectura
        canRead = true;
        lastScannedCard = cardUid;
        lastCardReadTime = currentTime;
      } else if (currentTime - lastCardReadTime >= CARD_READ_INTERVAL_MS) {
        // Es la misma tarjeta pero ha pasado el intervalo mínimo
        canRead = true;
        lastCardReadTime = currentTime;
      }

      // Solo actualizar lastUid si se permite la lectura
      if (canRead && cardUid != lastUid) {
        lastUid = cardUid;
        lastWasHCE = isHCE;
        Serial.print(isHCE ? "[HCE] " : "[RFID] ");
        Serial.println(cardUid);
      }

      delay(100); // Pequeño delay para evitar lecturas múltiples
    } else {
      // No hay tarjeta presente, resetear el UID después de un tiempo
      static unsigned long lastNoCardTime = 0;
      unsigned long currentTime = millis();
      
      if (lastUid != "NO_CARD") {
        if (lastNoCardTime == 0) {
          lastNoCardTime = currentTime; // Iniciar contador
        } else if (currentTime - lastNoCardTime > 1000) { // 1 segundo sin tarjeta
          lastUid = "NO_CARD";
          lastScannedCard = "";
          lastNoCardTime = 0;
        }
      } else {
        lastNoCardTime = 0; // Resetear contador si ya está en NO_CARD
      }
    }
  }

  // Verificar estado de conexión WiFi periódicamente
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > WIFI_CHECK_INTERVAL) {
    if (WiFi.status() != WL_CONNECTED && wifiConnected) {
      wifiConnected = false;
      digitalWrite(LED_WIFI, LOW);
      connectToWiFi();
    } else if (WiFi.status() == WL_CONNECTED && !wifiConnected) {
      wifiConnected = true;
      digitalWrite(LED_WIFI, HIGH);
    }
    lastWiFiCheck = millis();
  }
}

// =================== FUNCIONES WIFI ===================

// Configuración de IP estática
bool setupStaticIP() {
  Serial.println("Configurando IP estática: " + staticIP.toString());
  
  // Primer intento directo
  if (!WiFi.config(staticIP, gateway, subnet, dns)) {
    Serial.println("Error: La configuración de IP estática falló en el primer intento");
    
    // Segundo intento con desconexión previa
    WiFi.disconnect(true);
    delay(1000);
    if (!WiFi.config(staticIP, gateway, subnet, dns)) {
      Serial.println("Error: La configuración de IP estática falló en el segundo intento");
      return false;
    }
  }
  
  Serial.println("IP estática configurada correctamente");
  networkType = "static";
  staticIPConfigured = true;
  return true;
}

// Verificar si la IP estática se aplicó correctamente
bool isStaticIPConfigured() {
  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }
  
  // Compara la IP actual con la IP estática solicitada
  IPAddress currentIP = WiFi.localIP();
  return currentIP == staticIP;
}

// Obtener información de red
String getNetworkInfo() {
  String info = "Network: " + WiFi.localIP().toString();
  info += " (" + networkType + ")";
  return info;
}

// Conectar a WiFi
void connectToWiFi() {
  Serial.print("WiFi: ");
  Serial.print(WIFI_SSID);

  // Reiniciar contadores si este es un nuevo intento de conexión
  if (!wifiConnected) {
    connectionRetries = 0;
  }

  // Configurar modo WiFi
  WiFi.mode(WIFI_STA);
  
  // Configurar IP estática si está habilitada
  bool staticIPSetupSuccess = false;
  if (useStaticIP) {
    staticIPSetupSuccess = setupStaticIP();
    if (!staticIPSetupSuccess && connectionRetries >= MAX_CONNECTION_RETRIES) {
      Serial.println("ADVERTENCIA: Después de varios intentos, usando DHCP en lugar de IP estática");
      useStaticIP = false;
      networkType = "dhcp";
    }
  } else {
    networkType = "dhcp";
  }
  
  // Iniciar conexión
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  // LED parpadeando durante conexión
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    digitalWrite(LED_WIFI, !digitalRead(LED_WIFI)); // Parpadeo
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    digitalWrite(LED_WIFI, HIGH);
    Serial.print(" OK - ");
    Serial.println(WiFi.localIP());
    
    if (isStaticIPConfigured()) {
      networkType = "static";
      staticIPConfigured = true;
    } else if (useStaticIP) {
      networkType = "dhcp";
      staticIPConfigured = false;
      connectionRetries++;
      
      if (connectionRetries < MAX_CONNECTION_RETRIES) {
        WiFi.disconnect(true);
        delay(1000);
        connectToWiFi();
        return;
      }
    } else {
      networkType = "dhcp";
    }
  } else {
    wifiConnected = false;
    networkType = "none";
    digitalWrite(LED_WIFI, LOW);
    Serial.println(" FAIL");
  }
}

// =================== SERVIDOR HTTP ===================

// Configurar rutas del servidor HTTP
void setupServerRoutes() {
  // Rutas para comunicación con la aplicación Flutter
  server.on("/api/uid", HTTP_GET, handleGetUid);
  server.on("/api/uid_only", HTTP_GET, handleGetUidOnly);  // Nuevo endpoint silencioso
  server.on("/api/status", HTTP_GET, handleStatus);
  server.on("/api/membership", HTTP_POST, handleMembershipStatus);
  server.on("/api/discover", HTTP_GET, handleDiscover);

  server.enableCORS(true);
}

// Manejador para la ruta /api/uid
void handleGetUid() {
  // Solo enviar el UID, NO resetearlo
  // El reseteo se maneja en el loop principal
  server.send(200, "text/plain", lastUid);
}

// Manejador para la ruta /api/uid_only - Solo devuelve el UID sin activar LEDs
// Usado para capturar tarjetas al agregar nuevos clientes
void handleGetUidOnly() {
  // Este endpoint es idéntico a /api/uid, pero semánticamente diferente
  // El servicio de fondo usa /api/uid y activa LEDs mediante /api/membership
  // Los formularios de registro usan /api/uid_only y NO activan LEDs
  server.send(200, "text/plain", lastUid);
}

// Manejador para la ruta /api/status
void handleStatus() {
  DynamicJsonDocument doc(300);
  doc["status"] = "OK";
  doc["wifi_connected"] = wifiConnected;
  doc["last_uid"] = lastUid;
  doc["is_hce"] = lastWasHCE;  // Indica si la última lectura fue HCE o tarjeta física
  doc["card_type"] = lastWasHCE ? "HCE" : "PHYSICAL";
  doc["ip_address"] = WiFi.localIP().toString();
  doc["network_type"] = networkType;
  doc["static_ip_enabled"] = useStaticIP;
  doc["static_ip_configured"] = staticIPConfigured;
  doc["expected_ip"] = staticIP.toString();

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

// Manejador para recibir el estado de membresía y controlar LEDs
void handleMembershipStatus() {
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    DynamicJsonDocument doc(256);

    DeserializationError error = deserializeJson(doc, body);
    if (error) {
      server.send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
      return;
    }

    String status = doc["status"];
    controlStatusLeds(status);

    server.send(200, "application/json", "{\"success\":true}");
  } else {
    server.send(400, "application/json", "{\"error\":\"No data received\"}");
  }
}

// Manejador para la ruta /api/discover - Identificación del dispositivo
void handleDiscover() {
  DynamicJsonDocument doc(600);
  doc["device_id"] = "ESP32_RFID_GYMADS";
  doc["device_type"] = "RFID_READER";
  doc["version"] = "4.2.0";
  doc["rfid_reader"] = "PN532";
  doc["hce_support"] = true;  // Soporte para Host Card Emulation
  doc["manufacturer"] = "GYMADS";
  doc["wifi_connected"] = wifiConnected;
  doc["status"] = "ONLINE";
  doc["uptime"] = millis();
  doc["network_type"] = networkType;
  doc["static_ip_enabled"] = useStaticIP;
  doc["static_ip_configured"] = staticIPConfigured;

  if (wifiConnected) {
    doc["ip_address"] = WiFi.localIP().toString();
    doc["gateway"] = WiFi.gatewayIP().toString();
    doc["subnet"] = WiFi.subnetMask().toString();
    doc["dns"] = WiFi.dnsIP().toString();
    doc["mac_address"] = WiFi.macAddress();
    doc["signal_strength"] = WiFi.RSSI();
    doc["ssid"] = WiFi.SSID();
  }

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

// =================== CONTROL DE LEDS ===================

// Controlar LEDs según el estado de membresía
void controlStatusLeds(String status) {
  // Apagar todos los LEDs de estado primero
  turnOffAllStatusLeds();

  if (status == MEMBERSHIP_ACTIVE) {
    digitalWrite(LED_VERDE, HIGH);
  } else if (status == MEMBERSHIP_EXPIRING) {
    digitalWrite(LED_AMARILLO, HIGH);
  } else if (status == MEMBERSHIP_EXPIRED || status == MEMBERSHIP_NOT_FOUND) {
    digitalWrite(LED_ROJO, HIGH);
  }
  
  ledStateTimeout = millis() + LED_TIMEOUT;
}

// Manejar LEDs de estado
void handleStatusLeds() {
  // LED WiFi: fijo si conectado, apagado si no
  if (wifiConnected) {
    digitalWrite(LED_WIFI, HIGH);
  } else {
    // Parpadeo lento si no está conectado
    static unsigned long lastBlink = 0;
    if (millis() - lastBlink > 1000) {
      digitalWrite(LED_WIFI, !digitalRead(LED_WIFI));
      lastBlink = millis();
    }
  }
  
  // Verificar si es tiempo de apagar los LEDs de estado
  if (ledStateTimeout > 0 && millis() > ledStateTimeout) {
    turnOffAllStatusLeds();
    ledStateTimeout = 0;  // Reiniciar el temporizador
  }
}

// Apagar todos los LEDs de estado (excepto WiFi)
void turnOffAllStatusLeds() {
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_AMARILLO, LOW);
}

// Secuencia de prueba de LEDs al inicializar
void testLedSequence() {
  digitalWrite(LED_VERDE, HIGH);
  digitalWrite(LED_AMARILLO, HIGH);
  digitalWrite(LED_ROJO, HIGH);
  delay(200);
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_AMARILLO, LOW);
  digitalWrite(LED_ROJO, LOW);
  
  if (wifiConnected) {
    digitalWrite(LED_WIFI, HIGH);
  }
}

// =================== UTILIDADES ===================

// Convierte el UID de la tarjeta a formato String
String getCardUID(uint8_t* uid, uint8_t uidLength) {
  String cardString = "";
  for (byte i = 0; i < uidLength; i++) {
    // Añadir un 0 para números hexadecimales menores a 16 (0x10)
    if (uid[i] < 0x10) {
      cardString += "0";
    }
    cardString += String(uid[i], HEX);
  }
  cardString.toUpperCase();
  return cardString;
}

// =================== FUNCIONES HCE (HOST CARD EMULATION) ===================

// Detectar dispositivo NFC sin leer UID automáticamente
bool detectNFCDevice() {
  // inListPassiveTarget() detecta el dispositivo sin leer el UID
  // Esto permite que HCE responda antes de que se lea el UID físico
  return nfc->inListPassiveTarget();
}

// Intentar leer UID de un dispositivo HCE usando comandos APDU
bool tryReadHCE(String &uid) {
  uint8_t response[64];
  uint8_t responseLength = 32;
  
  Serial.println("HCE: SELECT AID...");
  
  // Enviar SELECT AID usando inDataExchange
  // IMPORTANTE: responseLength se pasa por referencia (&)
  bool success = nfc->inDataExchange((uint8_t*)APDU_SELECT, sizeof(APDU_SELECT), response, &responseLength);
  
  if (!success || responseLength < 2) {
    Serial.println("SELECT: No response");
    return false;
  }
  
  // Verificar status word 90 00
  uint8_t sw1 = response[responseLength - 2];
  uint8_t sw2 = response[responseLength - 1];
  
  if (sw1 != 0x90 || sw2 != 0x00) {
    Serial.print("SELECT failed: ");
    Serial.print(sw1, HEX);
    Serial.print(" ");
    Serial.println(sw2, HEX);
    return false;
  }
  
  Serial.println("HCE: SELECT OK");
  
  // Enviar GET DATA
  Serial.println("HCE: GET DATA...");
  responseLength = 32;
  success = nfc->inDataExchange((uint8_t*)APDU_GET_DATA, sizeof(APDU_GET_DATA), response, &responseLength);
  
  if (!success || responseLength < 2) {
    Serial.println("GET DATA: No response");
    return false;
  }
  
  sw1 = response[responseLength - 2];
  sw2 = response[responseLength - 1];
  
  if (sw1 != 0x90 || sw2 != 0x00) {
    Serial.print("GET DATA error: ");
    Serial.print(sw1, HEX);
    Serial.print(" ");
    Serial.println(sw2, HEX);
    return false;
  }
  
  // Extraer UID (sin los 2 bytes finales 90 00)
  if (responseLength > 2) {
    uid = "";
    for (uint8_t i = 0; i < responseLength - 2; i++) {
      if (response[i] < 0x10) uid += "0";
      uid += String(response[i], HEX);
    }
    uid.toUpperCase();
    Serial.print("HCE UID: ");
    Serial.println(uid);
    return true;
  }
  
  return false;
}