// #include "BluetoothSerial.h"

// BluetoothSerial SerialBT;

// const int alcoholPin = 34; // Analog pin connected to alcohol sensor
// int sensorValue = 0;
// float voltage = 0.0;

// void setup() {
//   Serial.begin(115200);
//   delay(1000);

//   // Initialize Bluetooth
//   if(!SerialBT.begin("SmartHelmet")) {
//     Serial.println("An error occurred initializing Bluetooth");
//   } else {
//     Serial.println("Bluetooth initialized. Waiting for connection...");
//   }

//   // Get ESP32 MAC address
//   uint8_t mac[6];
//   SerialBT.getBtAddress(mac);
//   Serial.print("ESP32 Bluetooth MAC: ");
//   for (int i = 0; i < 6; i++) {
//     if (mac[i] < 16) Serial.print("0");
//     Serial.print(mac[i], HEX);
//     if (i < 5) Serial.print(":");
//   }
//   Serial.println();

//   delay(1000);
// }

// void loop() {
//   sensorValue = analogRead(alcoholPin);
//   voltage = sensorValue * (3.3 / 4095.0);

//   if (SerialBT.hasClient()) {
//     SerialBT.println(String(voltage, 2));
//     Serial.println("Sent: " + String(voltage, 2));
//   } else {
//     Serial.println("No client connected yet...");
//   }

//   delay(500);
// }

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Define UUIDs (Universally Unique Identifiers)
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "abcd1234-5678-90ab-cdef-1234567890ab"

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Device connected");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Device disconnected");
    pServer->getAdvertising()->start(); // restart advertising
  }
};

void setup() {
  Serial.begin(115200);

  // Init BLE
  BLEDevice::init("SmartHelmet-BLE"); // device name

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("Waiting for client to connect...");
}

void loop() {
  if (deviceConnected) {
    int sensorValue = analogRead(34); // alcohol sensor pin
    float voltage = sensorValue * (3.3 / 4095.0);
    
    String val = String(voltage, 2);
    pCharacteristic->setValue(val.c_str());
    pCharacteristic->notify(); // send to app
    Serial.println("Sent: " + val);
  }

  delay(1000);
}

