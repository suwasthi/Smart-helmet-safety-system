// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>
// #include <TinyGPSPlus.h>
// #include <HardwareSerial.h>

// // BLE UUIDs
// #define SERVICE_UUID                 "12345678-1234-1234-1234-1234567890ab"
// #define DATA_CHARACTERISTIC_UUID     "abcd1234-5678-90ab-cdef-1234567890ab"
// #define PHONE_CHARACTERISTIC_UUID    "56781234-1234-1234-1234-1234567890ab"

// // Pins
// #define ALCOHOL_PIN 34

// BLECharacteristic *dataCharacteristic;
// BLECharacteristic *phoneCharacteristic;
// bool deviceConnected = false;

// // GPS
// HardwareSerial GPSSerial(1); // UART1
// TinyGPSPlus gps;

// // Callback class
// class MyServerCallbacks : public BLEServerCallbacks {
//   void onConnect(BLEServer* pServer) {
//     deviceConnected = true;
//     Serial.println("Device connected");
//   }

//   void onDisconnect(BLEServer* pServer) {
//     deviceConnected = false;
//     Serial.println("Device disconnected");
//     pServer->getAdvertising()->start(); // restart advertising
//   }
// };

// // Callback for phone characteristic write
// class PhoneCharacteristicCallbacks : public BLECharacteristicCallbacks {
//   void onWrite(BLECharacteristic *pChar) override {
//     String value = pChar->getValue();  // <-- Use Arduino String, NOT std::string
//     if (value.length() > 0) {
//       Serial.println("Received phone number: " + value);
//       // You can store or use this phone number here
//     }
//   }
// };

// void setup() {
//   Serial.begin(115200);

//   // Init GPS
//   GPSSerial.begin(9600, SERIAL_8N1, 16, 17); // RX=16, TX=17

//   // Init BLE
//   BLEDevice::init("SmartHelmet-BLE");
//   BLEServer *pServer = BLEDevice::createServer();
//   pServer->setCallbacks(new MyServerCallbacks());

//   // Create service
//   BLEService *pService = pServer->createService(SERVICE_UUID);

//   // Data characteristic (notify + read)
//   dataCharacteristic = pService->createCharacteristic(
//     DATA_CHARACTERISTIC_UUID,
//     BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
//   );
//   dataCharacteristic->addDescriptor(new BLE2902());

//   // Phone characteristic (write)
//   phoneCharacteristic = pService->createCharacteristic(
//     PHONE_CHARACTERISTIC_UUID,
//     BLECharacteristic::PROPERTY_WRITE
//   );
//   phoneCharacteristic->setCallbacks(new PhoneCharacteristicCallbacks());

//   // Start service and advertising
//   pService->start();
//   pServer->getAdvertising()->start();
//   Serial.println("Waiting for client to connect...");
// }

// void loop() {
//   // Read alcohol sensor
//   int sensorValue = analogRead(ALCOHOL_PIN);
//   float voltage = sensorValue * (3.3 / 4095.0);

//   // Read GPS data
//   while (GPSSerial.available() > 0) {
//     gps.encode(GPSSerial.read());
//   }

//   float latitude = 0.0;
//   float longitude = 0.0;

//   if (gps.location.isValid()) {
//     latitude = gps.location.lat();
//     longitude = gps.location.lng();
//   }

//   // Prepare data string: "voltage,lat,lon"
//   String data = String(voltage, 2) + "," + String(latitude, 6) + "," + String(longitude, 6);

//   if (deviceConnected) {
//     dataCharacteristic->setValue(data.c_str());
//     dataCharacteristic->notify();
//     Serial.println("Sent: " + data);
//   }

//   delay(1000); // Send every 1 second
// }

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <TinyGPSPlus.h>
#include <HardwareSerial.h>

// BLE UUIDs
#define SERVICE_UUID                 "12345678-1234-1234-1234-1234567890ab"
#define DATA_CHARACTERISTIC_UUID     "abcd1234-5678-90ab-cdef-1234567890ab"
#define PHONE_CHARACTERISTIC_UUID    "56781234-1234-1234-1234-1234567890ab"

// Pins
#define ALCOHOL_PIN 34

BLECharacteristic *dataCharacteristic;
BLECharacteristic *phoneCharacteristic;
bool deviceConnected = false;

// GPS
HardwareSerial GPSSerial(1); // UART1
TinyGPSPlus gps;

// Store hospital number
String hospitalNumber = "";

// Callback class
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

// Callback for phone characteristic write
class PhoneCharacteristicCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pChar) override {
    String value = pChar->getValue();
    if (value.length() > 0) {
      hospitalNumber = value;  // store received number
      Serial.println("Received phone number: " + hospitalNumber);
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Init GPS
  GPSSerial.begin(9600, SERIAL_8N1, 16, 17); // RX=16, TX=17

  // Init BLE
  BLEDevice::init("SmartHelmet-BLE");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Data characteristic (notify + read)
  dataCharacteristic = pService->createCharacteristic(
    DATA_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  dataCharacteristic->addDescriptor(new BLE2902());

  // Phone characteristic (write)
  phoneCharacteristic = pService->createCharacteristic(
    PHONE_CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  phoneCharacteristic->setCallbacks(new PhoneCharacteristicCallbacks());

  // Start service and advertising
  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("Waiting for client to connect...");
}

void loop() {
  // Read alcohol sensor
  int sensorValue = analogRead(ALCOHOL_PIN);
  float voltage = sensorValue * (3.3 / 4095.0);

  // Read GPS data
  while (GPSSerial.available() > 0) {
    gps.encode(GPSSerial.read());
  }

  float latitude = 0.0;   // Default coordinate (Colombo)
  float longitude = 0.0; // Default coordinate

  if (gps.location.isValid()) {
    latitude = gps.location.lat();
    longitude = gps.location.lng();
  }

  // Prepare data string: "voltage,lat,lon"
  String data = String(voltage, 2) + "," + String(latitude, 6) + "," + String(longitude, 6);

  if (deviceConnected) {
    dataCharacteristic->setValue(data.c_str());
    dataCharacteristic->notify();
    Serial.println("Sent: " + data);
    if (hospitalNumber.length() > 0) {
      Serial.println("Current hospital number: " + hospitalNumber);
    }
  }

  delay(1000); // Send every 1 second
}

