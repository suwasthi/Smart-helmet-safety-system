#include <Wire.h>
#include <Adafruit_MPU6050.h>   // If you use ADXL345, use Adafruit_ADXL345 instead
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

float offsetX = -0.66;
float offsetY = -0.27;
float offsetZ = -0.39;
  // Calibration offsets
float threshold = 5.0; // g-force crash threshold (start with 5g)

void setup() {
  Serial.begin(115200);
  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip!");
    while (1) delay(10);
  }
  mpu.setAccelerometerRange(MPU6050_RANGE_16_G);
  Serial.println("MPU6050 ready. Place helmet still for calibration.");
  delay(3000);
}

void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // Convert from m/s^2 to g (1g = 9.81 m/s^2)
  float ax = (a.acceleration.x / 9.81) - offsetX;
  float ay = (a.acceleration.y / 9.81) - offsetY;
  float az = (a.acceleration.z / 9.81) - offsetZ;

  float mag = sqrt(ax * ax + ay * ay + az * az);

  Serial.print("X: "); Serial.print(ax, 2);
  Serial.print(" Y: "); Serial.print(ay, 2);
  Serial.print(" Z: "); Serial.print(az, 2);
  Serial.print(" | Mag: "); Serial.println(mag, 2);

  if (mag > threshold) {
    Serial.println("⚠️ Crash Detected!");
    delay(2000); // lockout to avoid multiple triggers
  }

  delay(200); // sample rate
}

