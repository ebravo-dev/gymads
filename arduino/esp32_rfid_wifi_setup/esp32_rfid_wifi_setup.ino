/**
 * LECTOR RFID CON CONFIGURACIÓN BLUETOOTH LE Y SISTEMA DE LEDs PARA GYMADS
 * Dispositivo: ESP32
 * Función: Leer tarjetas RFID, configurar WiFi via Bluetooth LE y mostrar estado de membresía con LEDs
 * Versión: 3.1 - Configuración por Bluetooth LE (BLE)
 */

#include <SPI.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Configuración de pines del lector RFID
#define SS_PIN 5     // Pin SDA del MFRC522
#define RST_PIN 21   // Pin RST del MFRC522

// Pines de LEDs con nombres descriptivos
#define LED_WIFI 2        // LED para indicar conexión WiFi
#define LED_VERDE 4       // LED Verde - Membresía activa
#define LED_ROJO 22       // LED Rojo - Membresía vencida/no encontrada
#define LED_AMARILLO 15   // LED Amarillo - Membresía por vencer
#define LED_BLUETOOTH 12  // LED para indicar Bluetooth activo

// Variables globales
WebServer server(80);
MFRC522 rfidReader(SS_PIN, RST_PIN);
Preferences preferences;
String lastUid = "NO_CARD";

// Configuración Bluetooth LE
const String BT_DEVICE_NAME = "ESP32_RFID_GYMADS";
BLEServer* pServer = NULL;
BLECharacteristic* pTxCharacteristic;
BLECharacteristic* pRxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
String receivedCommand = "";

// UUIDs para el servicio UART BLE (Nordic UART Service)
#define SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_RX "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID_TX "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

// Estados de WiFi y Bluetooth
bool wifiConnected = false;
bool bluetoothEnabled = false;
bool bluetoothClientConnected = false;

// Estados de membresía
const String MEMBERSHIP_ACTIVE = "ACTIVE";
const String MEMBERSHIP_EXPIRING = "EXPIRING";
const String MEMBERSHIP_EXPIRED = "EXPIRED";
const String MEMBERSHIP_NOT_FOUND = "NOT_FOUND";

// =================== DECLARACIONES DE FUNCIONES ===================
void processBluetoothCommand(String command);
void sendBLEData(String data);
void handleBLEWiFiScan();
void handleBLEWiFiConnect(DynamicJsonDocument& doc);
void sendCurrentIPBLE();
void sendBLEStatus();
void sendBLEResponse(String status, String message);

// =================== CLASES CALLBACK BLUETOOTH LE ===================

// Callback para conexiones del servidor BLE
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      bluetoothClientConnected = true;
      Serial.println("Cliente BLE conectado");
      digitalWrite(LED_BLUETOOTH, HIGH);
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      bluetoothClientConnected = false;
      Serial.println("Cliente BLE desconectado");
      
      // Reiniciar advertising para permitir nuevas conexiones
      BLEDevice::startAdvertising();
      Serial.println("Advertising reiniciado");
    }
};

// Callback para recibir datos del cliente BLE
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue().c_str();

      if (rxValue.length() > 0) {
        receivedCommand = "";
        receivedCommand = rxValue;
        receivedCommand.trim();
        
        Serial.println("Comando BLE recibido: " + receivedCommand);
        
        // Procesar el comando
        processBluetoothCommand(receivedCommand);
      }
    }
};

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("=== GYMADS - RFID ESP32 CON BLUETOOTH LE v3.1 ===");
  
  // Configurar LEDs
  pinMode(LED_WIFI, OUTPUT);
  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_ROJO, OUTPUT);
  pinMode(LED_AMARILLO, OUTPUT);
  pinMode(LED_BLUETOOTH, OUTPUT);
  
  // Apagar todos los LEDs al inicio
  digitalWrite(LED_WIFI, LOW);
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_AMARILLO, LOW);
  digitalWrite(LED_BLUETOOTH, LOW);
  
  // Inicializar preferencias
  preferences.begin("wifi", false);
  
  // Inicializar lector RFID
  SPI.begin();
  rfidReader.PCD_Init();
  Serial.println("RFID Reader inicializado");
  
  // Inicializar Bluetooth LE
  initializeBluetooth();
  
  // Intentar conectar a WiFi guardado
  if (connectToSavedWiFi()) {
    setupServerRoutes();
    server.begin();
    Serial.println("Servidor HTTP iniciado");
    testLedSequence();
  } else {
    Serial.println("No hay WiFi configurado. Bluetooth LE listo para configuración.");
    // LED Bluetooth parpadeando para indicar que está esperando configuración
    digitalWrite(LED_BLUETOOTH, LOW);
  }
  
  Serial.println("=== SISTEMA LISTO - RFID ACTIVO ===");
}

void loop() {
  // Manejar solicitudes del servidor HTTP (si WiFi está conectado)
  if (wifiConnected) {
    server.handleClient();
  }
  
  // Manejar conexiones BLE
  handleBluetoothConnections();
  
  // Manejar LEDs de estado
  handleStatusLeds();
  
  // Solo procesar RFID si estamos conectados a WiFi
  if (wifiConnected) {
    // Verificar si hay una tarjeta presente
    if (rfidReader.PICC_IsNewCardPresent() && rfidReader.PICC_ReadCardSerial()) {
      // Obtener UID de la tarjeta
      String uid = getCardUID();
      
      // Guardar el UID para que esté disponible cuando se solicite
      lastUid = uid;
      
      // Mostrar UID en consola
      Serial.println("Tarjeta detectada: " + uid);
      
      // Apagar todos los LEDs de estado mientras se procesa
      turnOffAllStatusLeds();
      
      // Detener la tarjeta actual
      rfidReader.PICC_HaltA();
      rfidReader.PCD_StopCrypto1();
    }
  }
  
  // Verificar estado de conexión WiFi periódicamente
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > 10000) { // Cada 10 segundos
    checkWiFiConnection();
    lastWiFiCheck = millis();
  }
}

// =================== FUNCIONES BLUETOOTH LE ===================

// Inicializar Bluetooth LE
void initializeBluetooth() {
  Serial.println("Inicializando Bluetooth LE...");
  
  // Inicializar BLE
  BLEDevice::init(BT_DEVICE_NAME.c_str());
  
  // Crear servidor BLE
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Crear servicio BLE (Nordic UART Service)
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Crear característica TX (para enviar datos al cliente)
  pTxCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID_TX,
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pTxCharacteristic->addDescriptor(new BLE2902());

  // Crear característica RX (para recibir datos del cliente)
  pRxCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID_RX,
                      BLECharacteristic::PROPERTY_WRITE
                    );
  pRxCharacteristic->setCallbacks(new MyCallbacks());

  // Iniciar el servicio
  pService->start();

  // Configurar advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  
  // Iniciar advertising
  BLEDevice::startAdvertising();
  
  bluetoothEnabled = true;
  Serial.println("Bluetooth LE iniciado como: " + BT_DEVICE_NAME);
  Serial.println("Esperando conexiones BLE...");
  
  // LED parpadeando para indicar que está esperando conexión
  digitalWrite(LED_BLUETOOTH, LOW);
}

// Manejar conexiones BLE
void handleBluetoothConnections() {
  // Manejar reconexiones
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Dar tiempo al cliente para procesar la desconexión
    pServer->startAdvertising();
    Serial.println("Reiniciando advertising...");
    oldDeviceConnected = deviceConnected;
  }
  
  // Nueva conexión
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    Serial.println("Nueva conexión BLE establecida");
  }
  
  bluetoothClientConnected = deviceConnected;
}

// Procesar comandos recibidos por BLE
void processBluetoothCommand(String command) {
  Serial.println("Procesando comando: " + command);
  
  // Parsear comando JSON
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, command);
  
  if (error) {
    Serial.println("Error al parsear JSON: " + String(error.c_str()));
    sendBLEResponse("ERROR", "Invalid JSON format");
    return;
  }
  
  String cmd = doc["command"];
  
  if (cmd == "scan_wifi") {
    handleBLEWiFiScan();
  }
  else if (cmd == "connect_wifi") {
    handleBLEWiFiConnect(doc);
  }
  else if (cmd == "get_ip") {
    sendCurrentIPBLE();
  }
  else if (cmd == "get_status") {
    sendBLEStatus();
  }
  else if (cmd == "reset_wifi") {
    resetWiFiConfig();
    sendBLEResponse("success", "WiFi configuration reset");
  }
  else {
    sendBLEResponse("ERROR", "Unknown command: " + cmd);
  }
}

// Enviar datos por BLE
void sendBLEData(String data) {
  if (deviceConnected && pTxCharacteristic != NULL) {
    pTxCharacteristic->setValue(data.c_str());
    pTxCharacteristic->notify();
    delay(10); // Pequeña pausa para asegurar la transmisión
    Serial.println("Enviado por BLE: " + data);
  } else {
    Serial.println("No hay cliente BLE conectado para enviar: " + data);
  }
}

// Escanear redes WiFi vía BLE
void handleBLEWiFiScan() {
  Serial.println("Escaneando redes WiFi por solicitud BLE...");
  
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  
  int networks = WiFi.scanNetworks();
  
  DynamicJsonDocument doc(2048);
  doc["status"] = "success";
  doc["command"] = "scan_wifi";
  doc["count"] = networks;
  
  JsonArray networksArray = doc.createNestedArray("networks");
  
  for (int i = 0; i < networks && i < 10; i++) { // Limitar a 10 redes para evitar overflow
    JsonObject network = networksArray.createNestedObject();
    network["ssid"] = WiFi.SSID(i);
    network["rssi"] = WiFi.RSSI(i);
    network["secure"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
  }
  
  String response;
  serializeJson(doc, response);
  sendBLEData(response);
  
  Serial.println("Enviadas " + String(networks) + " redes por BLE");
}

// Conectar a WiFi vía BLE
void handleBLEWiFiConnect(DynamicJsonDocument& doc) {
  String ssid = doc["ssid"];
  String password = doc["password"];
  
  Serial.println("Conectando a WiFi: " + ssid);
  
  // Guardar credenciales
  preferences.putString("ssid", ssid);
  preferences.putString("password", password);
  
  // Intentar conectar
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid.c_str(), password.c_str());
  
  // Indicar que se está conectando
  sendBLEResponse("connecting", "Connecting to WiFi...");
  
  // Esperar conexión con timeout
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    digitalWrite(LED_WIFI, HIGH);
    delay(250);
    digitalWrite(LED_WIFI, LOW);
    delay(250);
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi conectado exitosamente!");
    Serial.println("IP asignada: " + WiFi.localIP().toString());
    
    digitalWrite(LED_WIFI, HIGH);
    wifiConnected = true;
    
    // Iniciar servidor HTTP
    setupServerRoutes();
    server.begin();
    
    // Enviar IP por BLE
    sendCurrentIPBLE();
    
    Serial.println("Configuración completada - Sistema listo");
  } else {
    Serial.println("Error al conectar WiFi");
    digitalWrite(LED_WIFI, LOW);
    wifiConnected = false;
    sendBLEResponse("error", "Failed to connect to WiFi");
  }
}

// Enviar IP actual por BLE
void sendCurrentIPBLE() {
  DynamicJsonDocument doc(512);
  doc["status"] = "success";
  doc["command"] = "get_ip";
  doc["wifi_connected"] = wifiConnected;
  
  if (wifiConnected) {
    doc["ip_address"] = WiFi.localIP().toString();
    doc["ssid"] = WiFi.SSID();
    doc["rssi"] = WiFi.RSSI();
    doc["mac_address"] = WiFi.macAddress();
  } else {
    doc["ip_address"] = "";
    doc["error"] = "WiFi not connected";
  }
  
  String response;
  serializeJson(doc, response);
  sendBLEData(response);
  
  if (wifiConnected) {
    Serial.println("IP enviada por BLE: " + WiFi.localIP().toString());
  } else {
    Serial.println("WiFi no conectado - enviado por BLE");
  }
}

// Enviar estado por BLE
void sendBLEStatus() {
  DynamicJsonDocument doc(512);
  doc["status"] = "success";
  doc["command"] = "get_status";
  doc["device_id"] = "ESP32_RFID_GYMADS";
  doc["wifi_connected"] = wifiConnected;
  doc["bluetooth_enabled"] = bluetoothEnabled;
  doc["bluetooth_client_connected"] = bluetoothClientConnected;
  doc["uptime"] = millis();
  doc["last_rfid_uid"] = lastUid;
  
  if (wifiConnected) {
    doc["ip_address"] = WiFi.localIP().toString();
    doc["ssid"] = WiFi.SSID();
  }
  
  String response;
  serializeJson(doc, response);
  sendBLEData(response);
}

// Enviar respuesta genérica por BLE
void sendBLEResponse(String status, String message) {
  DynamicJsonDocument doc(256);
  doc["status"] = status;
  doc["message"] = message;
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  sendBLEData(response);
}

// =================== FUNCIONES WIFI ===================

// Intentar conectar a WiFi guardado
bool connectToSavedWiFi() {
  String ssid = preferences.getString("ssid", "");
  String password = preferences.getString("password", "");
  
  if (ssid.length() == 0) {
    Serial.println("No hay credenciales WiFi guardadas");
    return false;
  }
  
  Serial.println("Intentando conectar a: " + ssid);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid.c_str(), password.c_str());
  
  // LED parpadeando durante conexión
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    digitalWrite(LED_WIFI, HIGH);
    delay(250);
    digitalWrite(LED_WIFI, LOW);
    delay(250);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi conectado!");
    Serial.println("IP: " + WiFi.localIP().toString());
    digitalWrite(LED_WIFI, HIGH);
    wifiConnected = true;
    return true;
  } else {
    Serial.println("\nNo se pudo conectar a WiFi");
    digitalWrite(LED_WIFI, LOW);
    wifiConnected = false;
    return false;
  }
}

// Verificar estado de conexión WiFi
void checkWiFiConnection() {
  if (wifiConnected && WiFi.status() != WL_CONNECTED) {
    Serial.println("Conexión WiFi perdida");
    wifiConnected = false;
    digitalWrite(LED_WIFI, LOW);
    
    // Intentar reconectar automáticamente
    if (!connectToSavedWiFi()) {
      Serial.println("No se pudo reconectar - Bluetooth disponible para reconfiguración");
    }
  }
}

// Reiniciar configuración WiFi
void resetWiFiConfig() {
  Serial.println("Reiniciando configuración WiFi");
  
  // Limpiar credenciales guardadas
  preferences.remove("ssid");
  preferences.remove("password");
  
  // Desconectar WiFi
  if (wifiConnected) {
    WiFi.disconnect(true);
    wifiConnected = false;
    digitalWrite(LED_WIFI, LOW);
  }
  
  Serial.println("Configuración WiFi eliminada - Bluetooth listo para nueva configuración");
}

// =================== SERVIDOR HTTP ===================

// Configurar rutas del servidor HTTP
void setupServerRoutes() {
  // Rutas para modo normal (cliente WiFi)
  server.on("/api/uid", HTTP_GET, handleGetUid);
  server.on("/api/status", HTTP_GET, handleStatus);
  server.on("/api/membership", HTTP_POST, handleMembershipStatus);
  server.on("/api/discover", HTTP_GET, handleDiscover);
  
  // Manejar CORS
  server.enableCORS(true);
  
  Serial.println("Rutas del servidor HTTP configuradas");
}

// Manejador para la ruta /api/uid
void handleGetUid() {
  server.send(200, "text/plain", lastUid);
  
  // Después de enviar el UID, lo reseteamos
  if (lastUid != "NO_CARD") {
    lastUid = "NO_CARD";
  }
}

// Manejador para la ruta /api/status
void handleStatus() {
  DynamicJsonDocument doc(256);
  doc["status"] = "OK";
  doc["wifi_connected"] = wifiConnected;
  doc["bluetooth_enabled"] = bluetoothEnabled;
  doc["last_uid"] = lastUid;
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

// Manejador para la ruta /api/discover - Identificación del dispositivo para discovery automático
void handleDiscover() {
  DynamicJsonDocument doc(512);
  doc["device_id"] = "ESP32_RFID_GYMADS";
  doc["device_type"] = "RFID_READER";
  doc["version"] = "3.1.0";
  doc["bluetooth_type"] = "BLE";
  doc["manufacturer"] = "GYMADS";
  doc["wifi_connected"] = wifiConnected;
  doc["bluetooth_enabled"] = bluetoothEnabled;
  doc["status"] = "ONLINE";
  doc["uptime"] = millis();
  
  if (wifiConnected) {
    doc["ip_address"] = WiFi.localIP().toString();
    doc["mac_address"] = WiFi.macAddress();
    doc["ssid"] = WiFi.SSID();
    doc["rssi"] = WiFi.RSSI();
  }
  
  // Información adicional útil para la app
  doc["last_rfid_uid"] = lastUid;
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
  
  Serial.println("Respondiendo a discovery request desde: " + server.client().remoteIP().toString());
}

// Manejador para recibir el estado de membresía y controlar LEDs
void handleMembershipStatus() {
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, body);
    
    String uid = doc["uid"];
    String status = doc["status"];
    
    Serial.print("Estado recibido para UID ");
    Serial.print(uid);
    Serial.print(": ");
    Serial.println(status);
    
    // Controlar LEDs según el estado
    controlStatusLeds(status);
    
    server.send(200, "text/plain", "Status received");
  } else {
    server.send(400, "text/plain", "No data received");
  }
}

// =================== CONTROL DE LEDS ===================

// Controlar LEDs según el estado de membresía
void controlStatusLeds(String status) {
  // Primero apagar todos los LEDs de estado
  turnOffAllStatusLeds();
  
  if (status == MEMBERSHIP_ACTIVE) {
    // Membresía activa - LED Verde
    digitalWrite(LED_VERDE, HIGH);
    delay(1000);
    digitalWrite(LED_VERDE, LOW);
    
  } else if (status == MEMBERSHIP_EXPIRING) {
    // Membresía por vencer - LED Amarillo
    digitalWrite(LED_AMARILLO, HIGH);
    delay(1000);
    digitalWrite(LED_AMARILLO, LOW);
    
  } else if (status == MEMBERSHIP_EXPIRED || status == MEMBERSHIP_NOT_FOUND) {
    // Membresía vencida o no encontrada - LED Rojo
    digitalWrite(LED_ROJO, HIGH);
    delay(1000);
    digitalWrite(LED_ROJO, LOW);
  }
}

// Manejar LEDs de estado
void handleStatusLeds() {
  // LED Bluetooth - parpadea si está habilitado pero sin cliente conectado y sin WiFi
  if (bluetoothEnabled && !bluetoothClientConnected && !wifiConnected) {
    blinkBluetoothLed();
  } else if (bluetoothClientConnected) {
    digitalWrite(LED_BLUETOOTH, HIGH);
  } else if (bluetoothEnabled && wifiConnected) {
    // Bluetooth habilitado y WiFi conectado - LED sólido
    digitalWrite(LED_BLUETOOTH, HIGH);
  }
  
  // LED WiFi - sólido si está conectado
  if (wifiConnected) {
    digitalWrite(LED_WIFI, HIGH);
  } else {
    digitalWrite(LED_WIFI, LOW);
  }
}

// LED Bluetooth parpadeando (modo configuración) - más rápido para indicar espera
void blinkBluetoothLed() {
  static unsigned long lastBlink = 0;
  static bool ledState = false;
  
  // Parpadeo más rápido cuando está esperando configuración
  int blinkInterval = wifiConnected ? 1000 : 500;
  
  if (millis() - lastBlink > blinkInterval) {
    ledState = !ledState;
    digitalWrite(LED_BLUETOOTH, ledState);
    lastBlink = millis();
  }
}

// Apagar todos los LEDs de estado (excepto WiFi y Bluetooth)
void turnOffAllStatusLeds() {
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_AMARILLO, LOW);
}

// Secuencia de prueba de LEDs al inicializar
void testLedSequence() {
  Serial.println("Ejecutando secuencia de prueba de LEDs");
  
  // Probar LED WiFi
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_WIFI, HIGH);
    delay(200);
    digitalWrite(LED_WIFI, LOW);
    delay(200);
  }
  
  // Probar LED Bluetooth
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_BLUETOOTH, HIGH);
    delay(200);
    digitalWrite(LED_BLUETOOTH, LOW);
    delay(200);
  }
  
  // Probar cada LED de estado brevemente
  digitalWrite(LED_VERDE, HIGH);
  delay(300);
  digitalWrite(LED_VERDE, LOW);
  
  digitalWrite(LED_AMARILLO, HIGH);
  delay(300);
  digitalWrite(LED_AMARILLO, LOW);
  
  digitalWrite(LED_ROJO, HIGH);
  delay(300);
  digitalWrite(LED_ROJO, LOW);
  
  // Restaurar LED WiFi si está conectado
  if (wifiConnected) {
    digitalWrite(LED_WIFI, HIGH);
  }
  
  // Restaurar LED Bluetooth - sólido si está conectado, sino se manejará en handleStatusLeds()
  if (bluetoothEnabled && wifiConnected) {
    digitalWrite(LED_BLUETOOTH, HIGH);
  }
  
  Serial.println("Secuencia de LEDs completada");
}

// =================== UTILIDADES ===================

// Convierte el UID de la tarjeta a formato String
String getCardUID() {
  String uidString = "";
  for (byte i = 0; i < rfidReader.uid.size; i++) {
    if (rfidReader.uid.uidByte[i] < 0x10) {
      uidString += "0";
    }
    uidString += String(rfidReader.uid.uidByte[i], HEX);
  }
  uidString.toUpperCase();
  return uidString;
}
