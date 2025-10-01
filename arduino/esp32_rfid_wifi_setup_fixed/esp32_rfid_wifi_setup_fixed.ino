/*
 * GYMADS - ESP32 RFID Reader con WiFi
 * LECTOR RFID CON CONEXIÓN WIFI AUTOMÁTICA PARA GYMADS
 * 
 * Versión 4.0.1 - Solo WiFi (Sin Bluetooth)
 * Dispositivo: ESP32
 * 
 * Función: Leer tarjetas RFID y enviar datos via HTTP
 * Sistema simplificado para lectura de tarjetas RFID con conectividad WiFi
 * Versión: 4.0.1 - WiFi automático sin Bluetooth + IP estática mejorada
 * 
 * Credenciales WiFi hardcodeadas para máxima simplicidad
 */

#include <SPI.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// =================== CONFIGURACIÓN WIFI ===================
// TODO: Cambiar estas credenciales por las de tu red WiFi
const char* WIFI_SSID = "S24 Ultra de Eder";
const char* WIFI_PASSWORD = "*E2d0e0r4";

// Configuración de IP estática
bool useStaticIP = true;  // Establecer a false para usar DHCP
IPAddress staticIP(192, 168, 1, 100);  // IP estática que quieres asignar al ESP32
IPAddress gateway(192, 168, 1, 1);     // IP del router (puerta de enlace)
IPAddress subnet(255, 255, 255, 0);    // Máscara de subred
IPAddress dns(8, 8, 8, 8);             // Servidor DNS (Google)

// =================== PINES DEL HARDWARE ===================
// Pines del lector RFID
#define RFID_SS_PIN   5
#define RFID_RST_PIN  21   // Confirma que este pin es correcto para tu hardware

// Pines de LEDs indicadores
#define LED_WIFI      2    // LED integrado del ESP32
#define LED_VERDE     4    // Membresía activa
#define LED_AMARILLO  15   // Membresía por vencer
#define LED_ROJO      22   // Membresía vencida/no encontrada

// =================== ESTADOS DE MEMBRESÍA ===================
#define MEMBERSHIP_ACTIVE      "active"
#define MEMBERSHIP_EXPIRING    "expiring"
#define MEMBERSHIP_EXPIRED     "expired"
#define MEMBERSHIP_NOT_FOUND   "not_found"

// =================== VARIABLES GLOBALES ===================
// Objetos principales
MFRC522 rfidReader(RFID_SS_PIN, RFID_RST_PIN);
WebServer server(80);

// Variables de estado
bool wifiConnected = false;
String lastUid = "NO_CARD";
String networkType = "none";  // Tipo de red: "static", "dhcp", "none"
bool staticIPConfigured = false; // Indica si se aplicó correctamente la IP estática

// Variables para control de tiempos de LEDs
unsigned long ledStateTimeout = 0;
const unsigned long LED_TIMEOUT = 3000;  // LEDs de estado se apagan después de 3 segundos

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
String getCardUID();
String getNetworkInfo();
bool isStaticIPConfigured();

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("=== GYMADS - RFID ESP32 v4.0.1 ===");
  Serial.println("Versión con soporte mejorado para IP estática");

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

  // Inicializar lector RFID
  SPI.begin();
  rfidReader.PCD_Init();
  Serial.println("RFID Reader inicializado");

  // Conectar a WiFi
  connectToWiFi();

  // Configurar servidor HTTP si está conectado
  if (wifiConnected) {
    setupServerRoutes();
    server.begin();
    Serial.println("Servidor HTTP iniciado en puerto 80");
    Serial.print("Dirección IP: ");
    Serial.println(WiFi.localIP());
    
    // Mostrar información de red
    Serial.println(getNetworkInfo());
  }

  // Secuencia de prueba de LEDs
  testLedSequence();

  Serial.println("=== SISTEMA LISTO - RFID ACTIVO ===");
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
    // Verificar si hay una nueva tarjeta presente
    if (rfidReader.PICC_IsNewCardPresent() && rfidReader.PICC_ReadCardSerial()) {
      String cardUid = getCardUID();

      if (cardUid != lastUid) {
        lastUid = cardUid;
        Serial.println("Tarjeta detectada: " + cardUid);

        // Mantener la tarjeta disponible hasta que la aplicación la lea
        // No la reseteamos inmediatamente
      }

      delay(100); // Pequeño delay para evitar lecturas múltiples
    }
  }

  // Verificar estado de conexión WiFi periódicamente
  static unsigned long lastWiFiCheck = 0;
  if (millis() - lastWiFiCheck > WIFI_CHECK_INTERVAL) { // Cada 10 segundos
    if (WiFi.status() != WL_CONNECTED && wifiConnected) {
      Serial.println("Conexión WiFi perdida, reintentando...");
      wifiConnected = false;
      digitalWrite(LED_WIFI, LOW);
      connectToWiFi();
    } else if (WiFi.status() == WL_CONNECTED && !wifiConnected) {
      // Caso donde el estado interno no coincide con el real
      wifiConnected = true;
      digitalWrite(LED_WIFI, HIGH);
      Serial.println("Estado de conexión WiFi actualizado");
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
  String info = "--- Información de Red ---\n";
  info += "Estado: " + String(wifiConnected ? "Conectado" : "Desconectado") + "\n";
  info += "Tipo de IP: " + networkType + "\n";
  info += "Dirección IP: " + WiFi.localIP().toString() + "\n";
  info += "Máscara de subred: " + WiFi.subnetMask().toString() + "\n";
  info += "Puerta de enlace: " + WiFi.gatewayIP().toString() + "\n";
  info += "Servidor DNS: " + WiFi.dnsIP().toString() + "\n";
  info += "Dirección MAC: " + WiFi.macAddress() + "\n";
  info += "SSID: " + WiFi.SSID() + "\n";
  info += "Fuerza de señal: " + String(WiFi.RSSI()) + " dBm\n";
  
  if (useStaticIP) {
    info += "IP estática: " + staticIP.toString() + "\n";
    info += "Configuración de IP estática: " + String(staticIPConfigured ? "Exitosa" : "Fallida") + "\n";
  }
  
  return info;
}

// Conectar a WiFi
void connectToWiFi() {
  Serial.println("Conectando a WiFi...");
  Serial.print("SSID: ");
  Serial.println(WIFI_SSID);

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
    digitalWrite(LED_WIFI, HIGH); // LED fijo = conectado
    Serial.println();
    Serial.println("WiFi conectado!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    
    // Verificar si se está usando la IP estática o DHCP
    if (isStaticIPConfigured()) {
      Serial.println("Usando IP estática configurada correctamente");
      networkType = "static";
      staticIPConfigured = true;
    } else if (useStaticIP) {
      Serial.println("ADVERTENCIA: Se intentó usar IP estática pero se obtuvo una IP dinámica");
      Serial.println("IP solicitada: " + staticIP.toString() + " | IP obtenida: " + WiFi.localIP().toString());
      networkType = "dhcp";
      staticIPConfigured = false;
      
      // Incrementar contador de reintentos
      connectionRetries++;
      
      if (connectionRetries < MAX_CONNECTION_RETRIES) {
        Serial.println("Reintentando con IP estática... (Intento " + String(connectionRetries) + " de " + String(MAX_CONNECTION_RETRIES) + ")");
        WiFi.disconnect(true);
        delay(1000);
        connectToWiFi(); // Recursivo
        return;
      } else {
        Serial.println("Se alcanzó el máximo de reintentos. Usando IP dinámica.");
      }
    } else {
      Serial.println("Usando DHCP (configurado)");
      networkType = "dhcp";
    }
  } else {
    wifiConnected = false;
    networkType = "none";
    digitalWrite(LED_WIFI, LOW);
    Serial.println();
    Serial.println("Error: No se pudo conectar a WiFi");
    Serial.println("Verifique las credenciales WiFi en el código");
  }
}

// =================== SERVIDOR HTTP ===================

// Configurar rutas del servidor HTTP
void setupServerRoutes() {
  // Rutas para comunicación con la aplicación Flutter
  server.on("/api/uid", HTTP_GET, handleGetUid);
  server.on("/api/status", HTTP_GET, handleStatus);
  server.on("/api/membership", HTTP_POST, handleMembershipStatus);
  server.on("/api/discover", HTTP_GET, handleDiscover);

  // Habilitar CORS para permitir solicitudes desde la aplicación
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
  doc["last_uid"] = lastUid;
  doc["ip_address"] = WiFi.localIP().toString();
  doc["network_type"] = networkType;
  doc["static_ip_enabled"] = useStaticIP;
  doc["static_ip_configured"] = staticIPConfigured;
  doc["expected_ip"] = staticIP.toString();

  String response;
  serializeJson(doc, response);
  server.send(200, "application/json", response);
}

// Manejador para la ruta /api/discover - Identificación del dispositivo
void handleDiscover() {
  DynamicJsonDocument doc(512);
  doc["device_id"] = "ESP32_RFID_GYMADS";
  doc["device_type"] = "RFID_READER";
  doc["version"] = "4.0.1";
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
  
  // Iniciar el temporizador para apagar los LEDs después de un tiempo
  ledStateTimeout = millis() + LED_TIMEOUT;

  Serial.println("Estado de membresía: " + status);
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
  Serial.println("Probando LEDs...");

  // Primero apagar todos los LEDs
  digitalWrite(LED_WIFI, LOW);
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_AMARILLO, LOW);
  delay(300);

  // Encender todos los LEDs brevemente
  digitalWrite(LED_WIFI, HIGH);
  digitalWrite(LED_VERDE, HIGH);
  digitalWrite(LED_ROJO, HIGH);
  digitalWrite(LED_AMARILLO, HIGH);
  delay(500);

  // Apagar todos
  digitalWrite(LED_WIFI, LOW);
  digitalWrite(LED_VERDE, LOW);
  digitalWrite(LED_ROJO, LOW);
  digitalWrite(LED_AMARILLO, LOW);
  delay(300);

  // Secuencia individual
  digitalWrite(LED_VERDE, HIGH);
  delay(200);
  digitalWrite(LED_VERDE, LOW);

  digitalWrite(LED_AMARILLO, HIGH);
  delay(200);
  digitalWrite(LED_AMARILLO, LOW);

  digitalWrite(LED_ROJO, HIGH);
  delay(200);
  digitalWrite(LED_ROJO, LOW);

  digitalWrite(LED_WIFI, HIGH);
  delay(200);
  digitalWrite(LED_WIFI, LOW);
  
  // Establecer el estado inicial correcto de los LEDs
  if (wifiConnected) {
    digitalWrite(LED_WIFI, HIGH);  // Restaurar el LED de WiFi si estamos conectados
  }
  
  Serial.println("Prueba de LEDs completada");
}

// =================== UTILIDADES ===================

// Convierte el UID de la tarjeta a formato String
String getCardUID() {
  String cardString = "";
  for (byte i = 0; i < rfidReader.uid.size; i++) {
    // Añadir un 0 para números hexadecimales menores a 16 (0x10)
    if (rfidReader.uid.uidByte[i] < 0x10) {
      cardString += "0";
    }
    cardString += String(rfidReader.uid.uidByte[i], HEX);
  }
  cardString.toUpperCase();
  return cardString;
}