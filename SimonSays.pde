// ============================================================
// Simon Says — Processing Side
// Protocol: Arduino→Processing:
// ============================================================
import processing.serial.*;

Serial port;

// ---------- constants ----------
final int LED_COUNT  = 5;
final int MAX_SEQ    = 100;
final int BASE_DELAY = 600;
final int SCREEN_W   = 960;
final int SCREEN_H   = 560;

// 5 LEDs: Red, Yellow, Green, Blue, White
int[] LED_R = {255, 255,  40,  40, 255};
int[] LED_G = { 50, 220, 220,  130, 255};
int[] LED_B = { 50,  30,  60, 255, 255};

String[] LED_NAMES = {"Red", "Yellow", "Green", "Blue", "White"};

color[] LED_COLOR_ON  = new color[LED_COUNT];
color[] LED_COLOR_OFF = new color[LED_COUNT];

// ---------- layout ----------
float[] lx   = new float[LED_COUNT];
float   ly;
float   ledR  = 44;
float   ledGap = 140;

// ---------- game state ----------
String    gState     = "IDLE";
int[]     sequence   = new int[MAX_SEQ];
int       seqLen     = 0;
int       playerStep = 0;
int       cursor     = 0;
int       score      = 0;
int       highScore  = 0;
int       showIdx    = 0;
long      showTimer  = 0;
int       showDelay  = BASE_DELAY;
boolean[] ledOn      = new boolean[LED_COUNT];

// ---------- animation ----------
float[] glowR       = new float[LED_COUNT];
float   cursorPulse = 0;
String  mainMsg     = "Press RIGHT button or D key to start";
String  subMsg      = "";
int     failShakeT  = 0;
float   shakeX      = 0;

// ---------- particles ----------
int     PCount = 0;
float[] px, py, pvx, pvy, plife, psize;
color[] pcol;
final int MAX_P = 200;

// ---------- history ----------
int[] history    = new int[20];
int   historyLen = 0;

// ============================================================
void setup() {
  size(960, 560);
  frameRate(60);

  for (int i = 0; i < LED_COUNT; i++) {
    LED_COLOR_ON[i]  = color(LED_R[i], LED_G[i], LED_B[i]);
    LED_COLOR_OFF[i] = color(
      (int)(LED_R[i] * 0.12),
      (int)(LED_G[i] * 0.12),
      (int)(LED_B[i] * 0.12)
    );
  }

  px    = new float[MAX_P]; py    = new float[MAX_P];
  pvx   = new float[MAX_P]; pvy   = new float[MAX_P];
  plife = new float[MAX_P]; psize = new float[MAX_P];
  pcol  = new color[MAX_P];

  float totalW = (LED_COUNT - 1) * ledGap;
  float startX = (SCREEN_W - totalW) / 2.0;
  for (int i = 0; i < LED_COUNT; i++) {
    lx[i] = startX + i * ledGap;
  }
  ly = height * 0.46;

  String[] ports = Serial.list();
  printArray(ports);
  if (ports.length > 0) {
    try {
      port = new Serial(this, ports[0], 9600);
      port.bufferUntil('\n');
    } catch (Exception e) {
      println("Serial failed: " + e.getMessage());
    }
  }

  textFont(createFont("Arial", 16, true));
}

// ============================================================
void draw() {
  drawBackground();
  updateGlow();
  updateParticles();
  if (gState.equals("SHOWING")) tickShowSequence();

  drawProgressBar();
  drawGlowEffects();
  drawLEDs();
  drawCursorRing();
  drawSequenceBar();
  drawHUD();
  drawMessage();
  drawHistoryStrip();
  drawParticles();
  cursorPulse += 0.07;
}

// ---------- background ----------
void drawBackground() {
  background(13, 13, 26);
  stroke(255, 255, 255, 10);
  strokeWeight(1);
  for (int x = 0; x < width;  x += 60) line(x, 0, x, height);
  for (int y = 0; y < height; y += 60) line(0, y, width, y);
  noStroke();
}

// ---------- glow ----------
void updateGlow() {
  for (int i = 0; i < LED_COUNT; i++) {
    float target = ledOn[i] ? ledR * 1.7 : 0;
    glowR[i] += (target - glowR[i]) * 0.18;
  }
}

void drawGlowEffects() {
  noStroke();
  for (int i = 0; i < LED_COUNT; i++) {
    if (glowR[i] < 2) continue;
    float ratio = glowR[i] / (ledR * 1.7);
    for (int ring = 5; ring >= 1; ring--) {
      float alpha = (ledOn[i] ? 35.0 : 14.0) / ring * ratio;
      fill(LED_R[i], LED_G[i], LED_B[i], alpha);
      float sz = glowR[i] * 2 * ring * 0.52;
      ellipse(lx[i], ly, sz, sz);
    }
  }
}

// ---------- LEDs ----------
void drawLEDs() {
  for (int i = 0; i < LED_COUNT; i++) {
    boolean on = ledOn[i];

    // outer ring
    strokeWeight(3);
    stroke(LED_R[i], LED_G[i], LED_B[i], on ? 255 : 55);
    fill(on ? LED_COLOR_ON[i] : LED_COLOR_OFF[i]);
    ellipse(lx[i], ly, ledR * 2, ledR * 2);

    // inner shine when on
    if (on) {
      noStroke();
      fill(255, 255, 255, 70);
      ellipse(lx[i] - ledR * 0.22, ly - ledR * 0.26, ledR * 0.65, ledR * 0.5);
    }

    // label
    noStroke();
    fill(on ? color(255) : color(75));
    textSize(12);
    textAlign(CENTER, CENTER);
    text(LED_NAMES[i], lx[i], ly + ledR + 18);

    // LED number badge
    fill(LED_R[i], LED_G[i], LED_B[i], on ? 200 : 60);
    ellipse(lx[i], ly - ledR - 14, 22, 22);
    fill(on ? color(20) : color(120));
    textSize(11);
    text(i, lx[i], ly - ledR - 14);
  }
}

// ---------- cursor ring ----------
void drawCursorRing() {
  if (!gState.equals("PLAYER")) return;
  float pulse     = (sin(cursorPulse) + 1) * 0.5;
  float ringAlpha = 150 + pulse * 105;
  float ringR     = ledR + 10 + pulse * 6;

  noFill();
  strokeWeight(2.5);
  stroke(255, 255, 255, ringAlpha);
  ellipse(lx[cursor], ly, ringR * 2, ringR * 2);

  // arrow above
  fill(255, 255, 255, ringAlpha);
  noStroke();
  triangle(
    lx[cursor] - 8, ly - ledR - 18,
    lx[cursor] + 8, ly - ledR - 18,
    lx[cursor],     ly - ledR - 30
  );
}

// ---------- sequence dots ----------
void drawSequenceBar() {
  if (seqLen == 0) return;
  float dotR  = 8;
  float xStep = min((width - 80.0) / seqLen, dotR * 2 + 10);
  float totalW = seqLen * xStep - 10;
  float sx    = (width - totalW) / 2.0;
  float sy    = ly + ledR + 50;

  for (int i = 0; i < seqLen; i++) {
    float cx  = sx + i * xStep + dotR;
    int   led = sequence[i];
    boolean done   = i < playerStep;
    boolean active = (i == playerStep) && gState.equals("PLAYER");
    float   p      = (sin(cursorPulse * 2) + 1) * 0.5;

    noStroke();
    if (done) {
      fill(LED_R[led], LED_G[led], LED_B[led], 240);
    } else if (active) {
      fill(LED_R[led], LED_G[led], LED_B[led], (int)(110 + p * 90));
    } else {
      fill((int)(LED_R[led] * 0.22), (int)(LED_G[led] * 0.22), (int)(LED_B[led] * 0.22));
    }
    float dr = active ? dotR * 1.4 : dotR;
    ellipse(cx, sy, dr * 2, dr * 2);

    // tick mark for completed steps
    if (done) {
      stroke(255, 255, 255, 120);
      strokeWeight(1.2);
      line(cx - 3, sy, cx - 1, sy + 3);
      line(cx - 1, sy + 3, cx + 4, sy - 3);
      noStroke();
    }
  }
}

// ---------- progress bar ----------
void drawProgressBar() {
  float bx = 60, by = ly + ledR + 40;
  float bw = width - 120, bh = 5;
  noStroke();
  fill(255, 255, 255, 16);
  rect(bx, by, bw, bh, 3);

  if (seqLen > 0) {
    float pct = (float) playerStep / seqLen;
    if (gState.equals("WIN")) pct = 1.0;
    int idx = max(0, playerStep - 1);
    int led = sequence[idx];
    fill(LED_R[led], LED_G[led], LED_B[led], 210);
    rect(bx, by, bw * pct, bh, 3);
  }
}

// ---------- HUD ----------
void drawHUD() {
  // Score
  textAlign(LEFT, TOP);
  textSize(11);
  fill(90);
  text("SCORE", 28, 22);
  fill(255);
  textSize(32);
  text(score, 28, 36);

  // Best
  textAlign(RIGHT, TOP);
  textSize(11);
  fill(90);
  text("BEST", width - 28, 22);
  fill(255);
  textSize(32);
  text(highScore, width - 28, 36);

  // Title
  textAlign(CENTER, TOP);
  textSize(15);
  fill(190);
  text("S I M O N   S A Y S", width / 2, 20);

  // Round info
  if (seqLen > 0) {
    textSize(11);
    fill(75);
    text("Round " + seqLen + "   |   Step " + playerStep + " / " + seqLen, width / 2, 42);
  }

  // Speed indicator
  textAlign(RIGHT, BOTTOM);
  textSize(10);
  fill(55);
  text("Speed: " + showDelay + "ms", width - 20, height - 10);
}

// ---------- message ----------
void drawMessage() {
  color col = color(210);
  if (gState.equals("FAIL"))     col = color(255, 75, 75);
  else if (gState.equals("WIN")) col = color(75, 225, 75);
  else if (gState.equals("SHOWING")) col = color(160, 160, 220);

  if (gState.equals("FAIL") && millis() - failShakeT < 600) {
    shakeX = random(-6, 6);
  } else {
    shakeX = 0;
  }

  textAlign(CENTER, CENTER);
  textSize(18);
  fill(col);
  text(mainMsg, width / 2.0 + shakeX, height - 72);

  textSize(12);
  fill(95);
  text(subMsg, width / 2.0, height - 48);
}

// ---------- history strip ----------
void drawHistoryStrip() {
  if (historyLen == 0) return;
  for (int i = 0; i < historyLen; i++) {
    int   led = history[i];
    float hx  = width / 2.0 + (i - historyLen / 2.0) * 20;
    noStroke();
    fill(LED_R[led], LED_G[led], LED_B[led], 170);
    ellipse(hx, height - 18, 11, 11);
  }
}

// ---------- particles ----------
void spawnParticles(float x, float y, int ledIdx, int n) {
  for (int i = 0; i < n && PCount < MAX_P; i++) {
    float angle = random(TWO_PI);
    float speed = random(2, 8);
    px[PCount]    = x;
    py[PCount]    = y;
    pvx[PCount]   = cos(angle) * speed;
    pvy[PCount]   = sin(angle) * speed - 2.5;
    plife[PCount] = random(45, 85);
    psize[PCount] = random(3, 9);
    pcol[PCount]  = color(LED_R[ledIdx], LED_G[ledIdx], LED_B[ledIdx]);
    PCount++;
  }
}

void updateParticles() {
  int alive = 0;
  for (int i = 0; i < PCount; i++) {
    pvy[i]  += 0.2;
    px[i]   += pvx[i];
    py[i]   += pvy[i];
    plife[i]--;
    if (plife[i] > 0) {
      px[alive]    = px[i];    py[alive]    = py[i];
      pvx[alive]   = pvx[i];  pvy[alive]   = pvy[i];
      plife[alive] = plife[i]; psize[alive] = psize[i];
      pcol[alive]  = pcol[i];
      alive++;
    }
  }
  PCount = alive;
}

void drawParticles() {
  noStroke();
  for (int i = 0; i < PCount; i++) {
    float a = map(plife[i], 0, 65, 0, 210);
    fill(red(pcol[i]), green(pcol[i]), blue(pcol[i]), a);
    ellipse(px[i], py[i], psize[i], psize[i]);
  }
}

// ============================================================
// Game logic
// ============================================================
void startGame() {
  seqLen     = 0; playerStep = 0;
  cursor     = 0; score      = 0;
  historyLen = 0; PCount     = 0;
  showDelay  = BASE_DELAY;
  nextRound();
}

void nextRound() {
  sequence[seqLen] = (int) random(LED_COUNT);
  seqLen++;
  playerStep = 0;
  showIdx    = 0;
  gState     = "SHOWING";
  mainMsg    = "Watch the sequence...";
  subMsg     = "Round " + seqLen;
  allOff();
  sendCmd('B');
  showTimer = millis() + 650;
}

void tickShowSequence() {
  if (millis() < showTimer) return;
  allOff();
  if (showIdx < seqLen) {
    int led = sequence[showIdx];
    ledOn[led] = true;
    sendCmdLed(led);
    spawnParticles(lx[led], ly, led, 10);
    showIdx++;
    showTimer = millis() + (long)(showDelay * 0.62);
  } else {
    allOff();
    sendCmd('X');
    gState        = "PLAYER";
    playerStep    = 0;
    cursor        = 0;
    ledOn[cursor] = true;
    mainMsg = "Your turn!";
    subMsg  = "A / LEFT = move     D / RIGHT = select";
  }
}

void checkAnswer(int chosen) {
  if (chosen == sequence[playerStep]) {
    spawnParticles(lx[chosen], ly, chosen, 20);
    playerStep++;
    if (playerStep == seqLen) {
      score++;
      if (score > highScore) highScore = score;
      showDelay = max(250, BASE_DELAY - score * 20);
      gState    = "WIN";
      mainMsg   = "Round " + score + " cleared!";
      subMsg    = "Get ready for round " + (score + 1) + "...";
      sendCmd('W');
      for (int i = 0; i < LED_COUNT; i++) spawnParticles(lx[i], ly, i, 16);
      long t = millis();
      while (millis() - t < 1500) { delay(1); }
      nextRound();
    } else {
      mainMsg = "Correct! Keep going...";
      subMsg  = "Step " + (playerStep + 1) + " of " + seqLen;
    }
  } else {
    gState     = "FAIL";
    failShakeT = (int) millis();
    sendCmd('F');
    mainMsg    = "Wrong! Game over.";
    subMsg     = "Press D / RIGHT button to retry";
    historyLen = playerStep;
    for (int i = 0; i < historyLen; i++) history[i] = sequence[i];
    allOff();
    sendCmd('X');
  }
}

void allOff() {
  for (int i = 0; i < LED_COUNT; i++) ledOn[i] = false;
}

void sendCmd(char c) {
  if (port != null) port.write(c);
}

void sendCmdLed(int idx) {
  if (port != null) {
    port.write('L');
    port.write(str(idx).charAt(0));
  }
}

// ============================================================
// Input
// ============================================================
void serialEvent(Serial p) {
  String raw = trim(p.readStringUntil('\n'));
  if (raw == null) return;
  if (gState.equals("PLAYER")) {
    if      (raw.equals("LEFT"))  moveCursor(-1);
    else if (raw.equals("RIGHT")) confirmSelection();
  } else if (gState.equals("IDLE") || gState.equals("FAIL")) {
    if (raw.equals("RIGHT")) startGame();
  }
}

void keyPressed() {
  if (key == 'a' || key == 'A' || keyCode == LEFT) {
    if (gState.equals("PLAYER")) moveCursor(-1);
  } else if (key == 'd' || key == 'D' || keyCode == RIGHT) {
    if      (gState.equals("PLAYER"))                          confirmSelection();
    else if (gState.equals("IDLE") || gState.equals("FAIL"))  startGame();
  } else if (key == ' ' || key == ENTER || key == RETURN) {
    if      (gState.equals("PLAYER"))                          confirmSelection();
    else if (gState.equals("IDLE") || gState.equals("FAIL"))  startGame();
  }
}

void moveCursor(int dir) {
  allOff();
  cursor        = (cursor + dir + LED_COUNT) % LED_COUNT;
  ledOn[cursor] = true;
  sendCmdLed(cursor);
}

void confirmSelection() {
  checkAnswer(cursor);
}