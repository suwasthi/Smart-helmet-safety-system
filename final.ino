#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <TinyGPSPlus.h>
#include <HardwareSerial.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>

// ----------------------------
// Object declarations
// ----------------------------
Adafruit_MPU6050 mpu;
TinyGPSPlus gps;
HardwareSerial SerialGPS(2); // UART2 for GPS

// ----------------------------
// BLE Configuration
// ----------------------------
BLEServer *pServer = NULL;
BLECharacteristic *dataCharacteristic;
BLECharacteristic *phoneCharacteristic;
bool deviceConnected = false;

#define SERVICE_UUID           "91bad492-b950-4226-aa2b-4ede9fa42f59"
#define CHARACTERISTIC_DATA_UUID "abcd1234-5678-90ab-cdef-1234567890ab"
#define CHARACTERISTIC_PHONE_UUID "56781234-1234-1234-1234-1234567890ab"


// ----------------------------
// Pin configuration
// ----------------------------
#define ALCOHOL_PIN 34

// ----------------------------
// Variables
// ----------------------------
float latitude = 6.781493, longitude = 79.883471;
String hospitalNumber = "";
bool crashDetected = false;
unsigned long previousMillis = 0;
const long interval = 2000;  // 2 seconds for alcohol updates

// ----------------------------
// BLE Callbacks
// ----------------------------
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Device connected ✅");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Device disconnected ❌");
    pServer->startAdvertising(); // restart advertising
    Serial.println("BLE advertising restarted...");
  }
};

class PhoneNumberCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) override {
    String rxValue = pCharacteristic->getValue().c_str();
    if (rxValue.length() > 0) {
      hospitalNumber = rxValue;
      Serial.print("📱 Received Hospital Phone Number: ");
      Serial.println(hospitalNumber);
    }
  }
};

// ----------------------------
// Setup
// ----------------------------
void setup() {
  Serial.begin(115200);
  SerialGPS.begin(9600, SERIAL_8N1, 16, 17); // RX=16, TX=17

  // MPU6050 Initialization
  if (!mpu.begin()) {
    Serial.println("MPU6050 not found!");
    while (1);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  Serial.println("MPU6050 Ready ✅");

  // BLE setup
  BLEDevice::init("SmartHelmet-BLE");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *helmetService = pServer->createService(SERVICE_UUID);

  // Data characteristic (Alcohol, GPS)
  dataCharacteristic = helmetService->createCharacteristic(
                        CHARACTERISTIC_DATA_UUID,
                        BLECharacteristic::PROPERTY_READ |
                        BLECharacteristic::PROPERTY_NOTIFY);
  dataCharacteristic->addDescriptor(new BLE2902());

  // Phone number characteristic (write from app)
  phoneCharacteristic = helmetService->createCharacteristic(
                          CHARACTERISTIC_PHONE_UUID,
                          BLECharacteristic::PROPERTY_WRITE);
  phoneCharacteristic->setCallbacks(new PhoneNumberCallback());

  helmetService->start();

  // Start BLE advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMaxPreferred(0x12);
  pAdvertising->start();

  Serial.println("BLE advertising started, name: SmartHelmet-BLE");
  Serial.println("Waiting for app connection...");
}

// ----------------------------
// Loop
// ----------------------------
void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // Read GPS
  while (SerialGPS.available()) {
    gps.encode(SerialGPS.read());
    if (gps.location.isUpdated()) {
      latitude = gps.location.lat();
      longitude = gps.location.lng();
    }
  }

  // Crash detection (if acceleration > 2g)
  float totalAcc = sqrt(a.acceleration.x * a.acceleration.x +
                        a.acceleration.y * a.acceleration.y +
                        a.acceleration.z * a.acceleration.z);

  if (totalAcc > 19.6 && !crashDetected) { // first crash detection
    Serial.println("🚨 Crash detected!");
    crashDetected = true;
  }

  // After crash, continuously send GPS + alcohol to app
  if (crashDetected) {
    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
      previousMillis = currentMillis;
      float alcoholValue = analogRead(ALCOHOL_PIN) * (3.3 / 4095.0); // Voltage
      if (deviceConnected) {
        String dataToSend = String(alcoholValue, 2) + "," + String(latitude, 6) + "," + String(longitude, 6);
        dataCharacteristic->setValue(dataToSend.c_str());
        dataCharacteristic->notify();
        Serial.println(dataToSend);
      }
    }
  }
}
