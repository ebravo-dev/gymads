/**
 * Test de compilación - Versión mínima para verificar errores
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

// Test de declaraciones
#define SS_PIN 5
#define RST_PIN 21
#define LED_WIFI 2
#define LED_VERDE 4
#define LED_ROJO 22
#define LED_AMARILLO 15
#define LED_BLUETOOTH 12

WebServer server(80);
MFRC522 rfidReader(SS_PIN, RST_PIN);
Preferences preferences;
String lastUid = "NO_CARD";

bool wifiConnected = false;
bool bluetoothEnabled = false;

void setup() {
  Serial.begin(115200);
  Serial.println("Test de compilación OK");
}

void loop() {
  // Test loop
}