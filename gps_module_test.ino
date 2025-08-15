#include <TinyGPSPlus.h>
#include <HardwareSerial.h>

TinyGPSPlus gps;
HardwareSerial gpsSerial(2); // Use UART2 (GPIO16 = RX, GPIO17 = TX)

void setup() {
  Serial.begin(115200);             // Serial Monitor
  gpsSerial.begin(9600, SERIAL_8N1, 16, 17); // GPS Module
  Serial.println("Waiting for GPS fix...");
}

void loop() {
  while (gpsSerial.available()) {
    char c = gpsSerial.read();
    gps.encode(c);

    if (gps.location.isUpdated()) {
      Serial.println("====================");
      Serial.print("Latitude: ");
      Serial.println(gps.location.lat(), 6);
      Serial.print("Longitude: ");
      Serial.println(gps.location.lng(), 6);

      Serial.print("Satellites: ");
      Serial.println(gps.satellites.value());

      Serial.print("Speed (km/h): ");
      Serial.println(gps.speed.kmph());

      Serial.print("Altitude (m): ");
      Serial.println(gps.altitude.meters());

      Serial.print("Time (UTC): ");
      Serial.printf("%02d:%02d:%02d\n", gps.time.hour(), gps.time.minute(), gps.time.second());

      Serial.println("====================\n");
    }
  }
}
