//======================
//===== Simon Says =====
//======================

const int LEDs[] = { 12, 11, 10, 9, 8 };
const int ledCount = 5; 

const int buzzerPin = 4;
const int btnLeft = 3;
const int btnStart = 2;

int currentLED = 0;
bool ledOn = false;
unsigned long lastBlink = 0;
unsigned long blinkInterval = 500;

int cursor = 0;
bool btnLeftWasPressed = false;
bool btnRightWasPressed = false;

// Game state received from Processing
// Commands: 'L' + index = light LED index
// Commands: 'X' = turn off all
// Commands: 'W' = win buzzer
// Commands: 'F' = fail buzzer

void setup() {
  Serial.begin(9600);

  for (int i = 0; i < ledCount; i++) {
    pinMode(LEDs[i], OUTPUT);
    digitalWrite(LEDs[i], LOW);
  }

  pinMode(buzzerPin, OUTPUT);
  pinMode(btnLeft, INPUT_PULLUP);
  pinMode(btnStart, INPUT_PULLUP);

  // Startup beep
  tone(buzzerPin, 1000, 150);
  delay(200);
  tone(buzzerPin, 1200, 150);
  delay(200);
  noTone(buzzerPin);
}

void turnOffAll() {
  for (int i = 0; i < ledCount; i++) {
    digitalWrite(LEDs[i], LOW);
  }
}

void lightLED(int index) {
  if (index < 0 || index >= ledCount) return;
  turnOffAll();
  digitalWrite(LEDs[index], HIGH);
}

void playWinSound() {
  int notes[] = { 523, 659, 784, 1047 };
  int dur[] = { 100, 100, 100, 200 };
  for (int i = 0; i < 4; i++) {
    tone(buzzerPin, notes[i], dur[i]);
    delay(dur[i] + 30);
  }
  noTone(buzzerPin);
}

void playFailSound() {
  tone(buzzerPin, 300, 400);
  delay(450);
  tone(buzzerPin, 200, 600);
  delay(650);
  noTone(buzzerPin);
}

void playClickSound() {
  tone(buzzerPin, 800, 50);
  delay(60);
  noTone(buzzerPin);
}

void handleSerial() {
  while (Serial.available() > 0) {
    char cmd = Serial.read();

    if (cmd == 'X') {
      turnOffAll();
    }

    else if (cmd == 'L') {
      unsigned long t = millis();

      while (!Serial.available() && millis() - t < 100)
        ;

      if (Serial.available()) {
        int idx = Serial.read() - '0';

        if (idx >= 0 && idx < ledCount) {   // FIXED safety check
          lightLED(idx);
          playClickSound();
        }
      }
    }

    else if (cmd == 'W') {
      playWinSound();
      turnOffAll();
    }

    else if (cmd == 'F') {
      playFailSound();
      turnOffAll();
    }

    else if (cmd == 'B') {
      for (int b = 0; b < 3; b++) {
        for (int i = 0; i < ledCount; i++) {
          digitalWrite(LEDs[i], HIGH);
        }
        delay(150);
        turnOffAll();
        delay(150);
      }
    }
  }
}

void handleButtons() {
  bool leftNow = (digitalRead(btnLeft) == LOW);
  bool rightNow = (digitalRead(btnStart) == LOW);

  if (leftNow && !btnLeftWasPressed) {
    Serial.println("LEFT");
    playClickSound();
  }

  if (rightNow && !btnRightWasPressed) {
    Serial.println("RIGHT");
    playClickSound();
  }

  btnLeftWasPressed = leftNow;
  btnRightWasPressed = rightNow;
}

void loop() {
  handleSerial();
  handleButtons();
  delay(10);
}