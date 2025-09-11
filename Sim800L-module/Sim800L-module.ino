// #include <HardwareSerial.h>

// HardwareSerial sim800(1);  // Use UART1 on ESP32

// void setup() {
//   Serial.begin(115200); 
//   sim800.begin(9600, SERIAL_8N1, 16, 17); // RX=16, TX=17

//   delay(1000);
//   Serial.println("Initializing SIM800L...");

//   sim800.println("AT");  // Test AT command
//   delay(1000);
//   sim800.println("AT+CSQ");  // Signal quality
//   delay(1000);
//   sim800.println("AT+CCID"); // SIM check
//   delay(1000);
//   sim800.println("AT+CREG?"); // Network registration
//   delay(1000);

//   // Send SMS
//   sendSMS("+94770784782", "Accident detected! Sending location...");
  
//   // Make a call
//   makeCall("+94770784782");
// }

// void loop() {
//   if (sim800.available()) {
//     Serial.write(sim800.read());  // Print GSM module responses
//   }
// }

// void sendSMS(String number, String text) {
//   sim800.println("AT+CMGF=1");  
//   delay(500);
//   sim800.print("AT+CMGS=\"");
//   sim800.print(number);
//   sim800.println("\"");
//   delay(500);
//   sim800.print(text);
//   delay(500);
//   sim800.write(26); // CTRL+Z to send SMS
//   delay(5000);
// }

// void makeCall(String number) {
//   sim800.print("ATD");
//   sim800.print(number);
//   sim800.println(";");
// }
#include <HardwareSerial.h>

HardwareSerial sim800(1);

void setup() {
  Serial.begin(115200);
  sim800.begin(9600, SERIAL_8N1, 16, 17); // Try 9600 first

  delay(1000);
  Serial.println("Sending AT...");
  sim800.println("AT");   // Send test command
}

void loop() {
  if (sim800.available()) {
    Serial.write(sim800.read());
  }
}
