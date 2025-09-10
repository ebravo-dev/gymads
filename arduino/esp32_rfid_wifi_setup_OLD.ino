/**
 * LECTOR RFID CON CONFIGURACIÓN WIFI Y SISTEMA DE LEDs PARA GYMADS
 * Dispositivo: ESP32
 * Función: Leer tarjetas RFID, configurar WiFi via AP y mostrar estado de membresía con LEDs
 */

#include <SPI.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include "BluetoothSerial.h"

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
BluetoothSerial SerialBT;
String lastUid = "NO_CARD";

// Configuración Bluetooth
const String BT_DEVICE_NAME = "ESP32_RFID_GYMADS";

// Estados de WiFi y Bluetooth
bool wifiConnected = false;
bool bluetoothEnabled = false;
bool bluetoothClientConnected = false;

// Estados de membresía
const String MEMBERSHIP_ACTIVE = "ACTIVE";
const String MEMBERSHIP_EXPIRING = "EXPIRING";
const String MEMBERSHIP_EXPIRED = "EXPIRED";
const String MEMBERSHIP_NOT_FOUND = "NOT_FOUND";

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("GYMADS - RFID ESP32 CON BLUETOOTH SETUP");
  
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
  
  // Inicializar Bluetooth
  initializeBluetooth();
  
  // Intentar conectar a WiFi guardado
  if (connectToSavedWiFi()) {
    setupServerRoutes();
    server.begin();
    Serial.println("Servidor HTTP iniciado");
    testLedSequence();
  } else {
    Serial.println("No hay WiFi configurado. Bluetooth listo para configuración.");
    blinkBluetoothLed();
  }
  
  Serial.println("Sistema listo - RFID activo");
}

void loop() {
  // Manejar solicitudes del servidor HTTP (si WiFi está conectado)
  if (wifiConnected) {
    server.handleClient();
  }
  
  // Manejar comunicación Bluetooth
  handleBluetoothCommunication();
  
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

// Inicializar Bluetooth
void initializeBluetooth() {
  SerialBT.begin(BT_DEVICE_NAME);
  bluetoothEnabled = true;
  digitalWrite(LED_BLUETOOTH, HIGH);
  Serial.println("Bluetooth iniciado como: " + BT_DEVICE_NAME);
  Serial.println("Bluetooth listo para emparejamiento");
}

// Manejar comunicación Bluetooth
void handleBluetoothCommunication() {
  if (SerialBT.available()) {
    String receivedData = SerialBT.readString();
    receivedData.trim();
    
    Serial.println("Datos recibidos por Bluetooth: " + receivedData);
    
    // Parsear comando JSON
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, receivedData);
    
    if (error) {
      Serial.println("Error al parsear JSON");
      sendBluetoothResponse("ERROR", "Invalid JSON format");
      return;
    }
    
    String command = doc["command"];
    
    if (command == "scan_wifi") {
      handleBluetoothWiFiScan();
    }
    else if (command == "connect_wifi") {
      handleBluetoothWiFiConnect(doc);
    }
    else if (command == "get_ip") {
      sendCurrentIP();
    }
    else if (command == "get_status") {
      sendBluetoothStatus();
    }
    else {
      sendBluetoothResponse("ERROR", "Unknown command: " + command);
    }
  }
  
  // Verificar estado de conexión Bluetooth
  bluetoothClientConnected = SerialBT.hasClient();
}

// Escanear redes WiFi vía Bluetooth
void handleBluetoothWiFiScan() {
  Serial.println("Escaneando redes WiFi por solicitud Bluetooth...");
  
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);
  
  int networks = WiFi.scanNetworks();
  
  DynamicJsonDocument doc(2048);
  doc["status"] = "success";
  doc["command"] = "scan_wifi";
  doc["count"] = networks;
  
  JsonArray networksArray = doc.createNestedArray("networks");
  
  for (int i = 0; i < networks; i++) {
    JsonObject network = networksArray.createNestedObject();
    network["ssid"] = WiFi.SSID(i);
    network["rssi"] = WiFi.RSSI(i);
    network["secure"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
  }
  
  String response;
  serializeJson(doc, response);
  SerialBT.println(response);
  
  Serial.println("Enviadas " + String(networks) + " redes por Bluetooth");
}

// Conectar a WiFi vía Bluetooth
void handleBluetoothWiFiConnect(DynamicJsonDocument& doc) {
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
  sendBluetoothResponse("connecting", "Connecting to WiFi...");
  
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
    
    // Enviar IP por Bluetooth
    sendCurrentIP();
    
    Serial.println("Configuración completada - Sistema listo");
  } else {
    Serial.println("Error al conectar WiFi");
    digitalWrite(LED_WIFI, LOW);
    wifiConnected = false;
    sendBluetoothResponse("error", "Failed to connect to WiFi");
  }
}

// Enviar IP actual por Bluetooth
void sendCurrentIP() {
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
  SerialBT.println(response);
  
  Serial.println("IP enviada por Bluetooth: " + WiFi.localIP().toString());
}

// Enviar estado por Bluetooth
void sendBluetoothStatus() {
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
  SerialBT.println(response);
}

// Enviar respuesta genérica por Bluetooth
void sendBluetoothResponse(String status, String message) {
  DynamicJsonDocument doc(256);
  doc["status"] = status;
  doc["message"] = message;
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  SerialBT.println(response);
}

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

// Manejar LEDs de estado
void handleStatusLeds() {
  // LED Bluetooth - parpadea si está habilitado pero sin cliente
  if (bluetoothEnabled && !bluetoothClientConnected && !wifiConnected) {
    blinkBluetoothLed();
  } else if (bluetoothClientConnected) {
    digitalWrite(LED_BLUETOOTH, HIGH);
  }
  
  // LED WiFi - sólido si está conectado
  if (wifiConnected) {
    digitalWrite(LED_WIFI, HIGH);
  } else {
    digitalWrite(LED_WIFI, LOW);
  }
}

// LED Bluetooth parpadeando (modo configuración)
void blinkBluetoothLed() {
  static unsigned long lastBlink = 0;
  static bool ledState = false;
  
  if (millis() - lastBlink > 1000) {
    ledState = !ledState;
    digitalWrite(LED_BLUETOOTH, ledState);
    lastBlink = millis();
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

// Manejador para escanear redes WiFi
void handleWiFiScan() {
  Serial.println("Escaneando redes WiFi...");
  
  // Si estamos conectados a WiFi, desconectarse para permitir cambio de red
  if (wifiConnected && !isAPMode) {
    Serial.println("Desconectando de WiFi actual para permitir cambio de red...");
    WiFi.disconnect(true);
    wifiConnected = false;
    isAPMode = true;
    
    // Volver a modo AP para configuración
    setupAccessPoint();
    delay(1000);
    Serial.println("ESP32 listo para nueva configuración WiFi");
  }
  
  // Usar modo AP+STA para mantener el Access Point mientras escaneamos
  WiFi.mode(WIFI_AP_STA);
  int networks = WiFi.scanNetworks();
  
  DynamicJsonDocument doc(2048);
  
  if (networks == 0) {
    doc["status"] = "no_networks";
    doc["count"] = 0;
    doc["message"] = "No se encontraron redes WiFi";
    doc.createNestedArray("networks"); // Array vacío
  } else if (networks > 0) {
    doc["status"] = "success";
    doc["count"] = networks;
    doc["message"] = "Redes encontradas exitosamente";
    JsonArray networksArray = doc.createNestedArray("networks");
    
    for (int i = 0; i < networks; i++) {
      JsonObject network = networksArray.createNestedObject();
      network["ssid"] = WiFi.SSID(i);
      network["rssi"] = WiFi.RSSI(i);
      network["secure"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
    }
  } else {
    // Error en el escaneo
    doc["status"] = "error";
    doc["count"] = 0;
    doc["message"] = "Error al escanear redes WiFi";
    doc.createNestedArray("networks");
  }
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
  
  Serial.println("Redes encontradas: " + String(networks));
  
  // Asegurar que el Access Point sigue activo después del escaneo
  if (isAPMode) {
    WiFi.mode(WIFI_AP);
    // Reconfigurar el AP si es necesario
    WiFi.softAP(ap_ssid, ap_password);
  }
}

// Manejador para conectar a WiFi
void handleWiFiConnect() {
  if (server.hasArg("plain")) {
    String body = server.arg("plain");
    
    DynamicJsonDocument doc(1024);
    deserializeJson(doc, body);
    
    String ssid = doc["ssid"];
    String password = doc["password"];
    
    Serial.println("Intentando conectar a: " + ssid);
    
    // Guardar credenciales
    preferences.putString("ssid", ssid);
    preferences.putString("password", password);
    
    // Responder inmediatamente que se está conectando
    server.send(200, "application/json", "{\"status\":\"connecting\",\"message\":\"Configurando conexión WiFi...\"}");
    
    // Pequeña pausa para asegurar que la respuesta se envíe
    delay(500);
    
    // Intentar conectar
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid.c_str(), password.c_str());
    
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
      Serial.println("IP: " + WiFi.localIP().toString());
      digitalWrite(LED_WIFI, HIGH);
      wifiConnected = true;
      isAPMode = false;
      
      // Esperar un poco más antes de reiniciar para estabilizar la conexión
      delay(3000);
      ESP.restart();
    } else {
      Serial.println("Error al conectar WiFi");
      digitalWrite(LED_WIFI, LOW);
      
      // Volver a modo AP
      setupAccessPoint();
    }
  } else {
    server.send(400, "application/json", "{\"status\":\"error\",\"message\":\"No se recibieron datos\"}");
  }
}

// Manejador para estado de WiFi
void handleWiFiStatus() {
  DynamicJsonDocument doc(512);
  
  if (isAPMode) {
    doc["mode"] = "ap";
    doc["ap_ssid"] = ap_ssid;
    doc["ap_ip"] = WiFi.softAPIP().toString();
    doc["connected"] = false;
    doc["status"] = "setup_mode";
    doc["message"] = "Dispositivo en modo configuración WiFi";
  } else {
    doc["mode"] = "client";
    doc["ssid"] = WiFi.SSID();
    doc["ip"] = WiFi.localIP().toString();
    doc["connected"] = wifiConnected;
    doc["rssi"] = WiFi.RSSI();
    doc["status"] = "connected";
    doc["message"] = "Dispositivo conectado y listo";
  }
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

// Manejador para resetear configuración WiFi
void handleWiFiReset() {
  Serial.println("Ejecutando reset de fábrica - Eliminando toda la configuración");
  
  // Limpiar todas las preferencias guardadas
  preferences.clear();
  
  // Desconectar WiFi actual si está conectado
  if (wifiConnected) {
    WiFi.disconnect(true);
    wifiConnected = false;
  }
  
  // Forzar modo AP
  isAPMode = true;
  
  // Responder antes de reiniciar
  DynamicJsonDocument doc(512);
  doc["status"] = "success";
  doc["message"] = "Reset de fábrica completado - ESP32 reiniciándose";
  doc["action"] = "factory_reset";
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
  
  Serial.println("Configuración eliminada. Reiniciando en 2 segundos...");
  
  // Parpadear todos los LEDs para indicar reset
  for (int i = 0; i < 5; i++) {
    digitalWrite(LED_WIFI, HIGH);
    digitalWrite(LED_VERDE, HIGH);
    digitalWrite(LED_AMARILLO, HIGH);
    digitalWrite(LED_ROJO, HIGH);
    delay(200);
    digitalWrite(LED_WIFI, LOW);
    digitalWrite(LED_VERDE, LOW);
    digitalWrite(LED_AMARILLO, LOW);
    digitalWrite(LED_ROJO, LOW);
    delay(200);
  }
  
  delay(1000);
  ESP.restart();
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
  doc["version"] = "3.0.0";
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
  
  // Restaurar LED Bluetooth
  if (bluetoothEnabled) {
    digitalWrite(LED_BLUETOOTH, HIGH);
  }
  
  Serial.println("Secuencia de LEDs completada");
}

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
