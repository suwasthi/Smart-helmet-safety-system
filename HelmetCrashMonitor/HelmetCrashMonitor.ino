#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Arduino.h>

Adafruit_MPU6050 mpu;
const float CRASH_THRESHOLD = 25.0;

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);

  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) delay(10);
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  // Header for Serial Plotter
  Serial.println("Accel_X,Accel_Y,Accel_Z,Accel_Magnitude");
}

void loop() {
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  float magnitude = sqrt(
    a.acceleration.x * a.acceleration.x +
    a.acceleration.y * a.acceleration.y +
    a.acceleration.z * a.acceleration.z
  );

  // Print numeric values for plotting
  Serial.print(a.acceleration.x); Serial.print(",");
  Serial.print(a.acceleration.y); Serial.print(",");
  Serial.print(a.acceleration.z); Serial.print(",");
  Serial.println(magnitude);

  // Detect crash and print alert
  if (magnitude > CRASH_THRESHOLD) {
    Serial.println(" !!!!!!!!!!! CRASH DETECTED !!!!!!!!!!!");
  }

  delay(50); // ~20Hz sampling for smoother graph
}
