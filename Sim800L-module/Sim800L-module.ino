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

HardwareSerial sim800(2);  // UART2

#define PWRKEY 4  // optional, if you want ESP32 to toggle it
#define RX_PIN 16
#define TX_PIN 17

const String phoneNumber = "+94766370873"; // replace with your number
const String smsText = "Hello! This is a test message.";

void setup() {
  Serial.begin(115200);
  sim800.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);

  // Optional: turn on SIM module via PWRKEY
  pinMode(PWRKEY, OUTPUT);
  digitalWrite(PWRKEY, LOW);
  delay(1000);
  digitalWrite(PWRKEY, HIGH);

  Serial.println("Waiting for SIM800L to register on network...");

  // Wait for network registration
  waitForNetwork();

  Serial.println("SIM800L Registered! Starting tests...");

  // Send SMS
  sendSMS(phoneNumber, smsText);

  // Make a call
  makeCall(phoneNumber);
}

void loop() {
  // Print all SIM responses in real time
  while (sim800.available()) {
    Serial.write(sim800.read());
  }
}

// Wait until network registration
void waitForNetwork() {
  while (true) {
    sim800.println("AT+CREG?");
    delay(1000);
    while (sim800.available()) {
      String response = sim800.readString();
      Serial.print(response);
      if (response.indexOf(",1") != -1 || response.indexOf(",5") != -1) {
        return; // registered home or roaming
      }
    }
    delay(2000);
  }
}

// Function to send SMS
void sendSMS(String number, String text) {
  Serial.println("Sending SMS...");
  sim800.println("AT+CMGF=1"); // text mode
  delay(500);
  sim800.print("AT+CMGS=\"");
  sim800.print(number);
  sim800.println("\"");
  delay(500);
  sim800.print(text);
  delay(500);
  sim800.write(26); // CTRL+Z to send
  delay(5000);
  Serial.println("SMS Sent Command Executed");
}

// Function to make a call
void makeCall(String number) {
  Serial.println("Making a test call...");
  sim800.print("ATD");
  sim800.print(number);
  sim800.println(";");
  delay(10000); // 10s call
  sim800.println("ATH"); // hang up
  Serial.println("Call Test Executed");
}
