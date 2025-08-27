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

// Configuración de pines del lector RFID
#define SS_PIN 5     // Pin SDA del MFRC522
#define RST_PIN 21   // Pin RST del MFRC522

// Pines de LEDs con nombres descriptivos
#define LED_WIFI 2        // LED para indicar conexión WiFi
#define LED_VERDE 4       // LED Verde - Membresía activa
#define LED_ROJO 22       // LED Rojo - Membresía vencida/no encontrada
#define LED_AMARILLO 15   // LED Amarillo - Membresía por vencer

// Variables globales
WebServer server(80);
MFRC522 rfidReader(SS_PIN, RST_PIN);
Preferences preferences;
String lastUid = "NO_CARD";

// Configuración de Access Point
const char* ap_ssid = "ESP_RFID_Setup";
const char* ap_password = "gymads123";

// Estados de WiFi
bool isAPMode = false;
bool wifiConnected = false;

// Estados de membresía
const String MEMBERSHIP_ACTIVE = "ACTIVE";
const String MEMBERSHIP_EXPIRING = "EXPIRING";
const String MEMBERSHIP_EXPIRED = "EXPIRED";
const String MEMBERSHIP_NOT_FOUND = "NOT_FOUND";

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("GYMADS - RFID ESP32 CON WIFI SETUP");
  
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
  
  // Inicializar preferencias
  preferences.begin("wifi", false);
  
  // Inicializar lector RFID
  SPI.begin();
  rfidReader.PCD_Init();
  
  // Intentar conectar a WiFi guardado
  if (connectToSavedWiFi()) {
    setupServerRoutes();
    server.begin();
    Serial.println("Servidor iniciado en modo cliente WiFi");
    testLedSequence();
  } else {
    setupAccessPoint();
  }
  
  Serial.println("Listo para escanear");
}

void loop() {
  // Manejar solicitudes del servidor
  server.handleClient();
  
  // Manejar LED WiFi en modo AP
  if (isAPMode) {
    blinkWiFiLedSlow();
  }
  
  // Solo procesar RFID si estamos conectados a WiFi (no en modo AP)
  if (wifiConnected && !isAPMode) {
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
    digitalWrite(LED_WIFI, HIGH); // LED WiFi fijo cuando está conectado
    wifiConnected = true;
    isAPMode = false;
    return true;
  } else {
    Serial.println("\nNo se pudo conectar a WiFi");
    digitalWrite(LED_WIFI, LOW);
    wifiConnected = false;
    return false;
  }
}

// Configurar Access Point
void setupAccessPoint() {
  Serial.println("Iniciando modo Access Point");
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ap_ssid, ap_password);
  
  Serial.println("Access Point iniciado");
  Serial.println("SSID: " + String(ap_ssid));
  Serial.println("Password: " + String(ap_password));
  Serial.println("IP AP: " + WiFi.softAPIP().toString());
  
  isAPMode = true;
  wifiConnected = false;
  
  // LED parpadeando lento para indicar modo AP
  blinkWiFiLedSlow();
  
  setupServerRoutes();
  server.begin();
  Serial.println("Servidor iniciado en modo Access Point");
}

// Configurar rutas del servidor
void setupServerRoutes() {
  // Rutas para modo normal (cliente WiFi)
  server.on("/api/uid", HTTP_GET, handleGetUid);
  server.on("/api/status", HTTP_GET, handleStatus);
  server.on("/api/membership", HTTP_POST, handleMembershipStatus);
  
  // Rutas para configuración WiFi (modo AP)
  server.on("/api/wifi/scan", HTTP_GET, handleWiFiScan);
  server.on("/api/wifi/connect", HTTP_POST, handleWiFiConnect);
  server.on("/api/wifi/status", HTTP_GET, handleWiFiStatus);
  server.on("/api/wifi/reset", HTTP_POST, handleWiFiReset);
  server.on("/api/wifi/config", HTTP_POST, handleEnterConfigMode);
  
  // Manejar CORS
  server.enableCORS(true);
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
  doc["ap_mode"] = isAPMode;
  doc["last_uid"] = lastUid;
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
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

// Verificar estado de conexión WiFi
void checkWiFiConnection() {
  if (!isAPMode && WiFi.status() != WL_CONNECTED) {
    Serial.println("Conexión WiFi perdida, reintentando...");
    wifiConnected = false;
    digitalWrite(LED_WIFI, LOW);
    
    if (!connectToSavedWiFi()) {
      Serial.println("No se pudo reconectar, iniciando modo AP");
      setupAccessPoint();
    }
  }
}

// Apagar todos los LEDs de estado (excepto WiFi)
void turnOffAllStatusLeds() {
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_AMARILLO, LOW);
}

// LED WiFi parpadeando lento (modo AP)
void blinkWiFiLedSlow() {
  static unsigned long lastBlink = 0;
  static bool ledState = false;
  
  if (millis() - lastBlink > 1000) {
    ledState = !ledState;
    digitalWrite(LED_WIFI, ledState);
    lastBlink = millis();
  }
}

// Secuencia de prueba de LEDs al inicializar
void testLedSequence() {
  // Indicar que está listo con el LED de WiFi
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_WIFI, HIGH);
    delay(200);
    digitalWrite(LED_WIFI, LOW);
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
  
  // Restaurar LED WiFi
  if (wifiConnected) {
    digitalWrite(LED_WIFI, HIGH);
  }
}

// Manejador para entrar en modo configuración WiFi
void handleEnterConfigMode() {
  Serial.println("Forzando entrada a modo configuración WiFi...");
  
  // Desconectar WiFi actual si está conectado
  if (wifiConnected) {
    WiFi.disconnect(true);
    wifiConnected = false;
  }
  
  // Activar modo AP
  isAPMode = true;
  setupAccessPoint();
  
  // Responder que se ha entrado en modo configuración
  DynamicJsonDocument doc(512);
  doc["status"] = "success";
  doc["message"] = "Modo configuración activado";
  doc["ap_ssid"] = ap_ssid;
  doc["ip"] = WiFi.softAPIP().toString();
  
  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
  
  Serial.println("Modo configuración activado. SSID: " + String(ap_ssid));
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
