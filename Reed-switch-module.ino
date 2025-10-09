// ReedSwitch_ESP32.ino
const uint8_t reedPin = 13;    // change to your chosen pin
const uint8_t ledPin  = 2;     // onboard LED or external LED
volatile unsigned long lastInterrupt = 0;
volatile bool reedStateChanged = false;
volatile int reedState = HIGH;

void IRAM_ATTR handleReedISR() {
  // Keep ISR short. Record a timestamp and set a flag.
  unsigned long t = millis();
  if (t - lastInterrupt > 50) { // 50 ms debounce window
    lastInterrupt = t;
    reedState = digitalRead(reedPin); // safe on ESP32
    reedStateChanged = true;
  }
}

void setup() {
  Serial.begin(115200);
  delay(50);
  pinMode(reedPin, INPUT_PULLUP); // use internal pull-up
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);

  // Attach interrupt: trigger on CHANGE (open or close)
  attachInterrupt(digitalPinToInterrupt(reedPin), handleReedISR, CHANGE);

  Serial.println("Reed switch test started. Waiting for events...");
}

void loop() {
  if (reedStateChanged) {
    // Disable interrupts briefly while handling flag
    noInterrupts();
    int state = reedState;
    reedStateChanged = false;
    interrupts();

    if (state == LOW) {
      Serial.println("Reed CLOSED (magnet nearby) — Door CLOSED / Sensor triggered");
      digitalWrite(ledPin, HIGH);
    } else {
      Serial.println("Reed OPEN (magnet away) — Door OPEN / Sensor released");
      digitalWrite(ledPin, LOW);
    }
  }
  // other main-loop code here...
  delay(10);
}
