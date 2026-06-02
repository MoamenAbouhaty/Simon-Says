# 🎮 Simon Says — Arduino + Processing

![logo](assets/logo.jpg)

A hardware-software Simon Says game built with Arduino and Processing. The game displays a growing LED sequence that the player must repeat using two physical buttons, with sound feedback via a buzzer.

---

## 📁 Project Structure

```
simon-says/
├── assets/
|   └── logo.png
├── SimonSays.pde       # Processing sketch (game logic + visuals)
└── simon_arduino/
    └── simon_arduino.ino   # Arduino sketch (hardware control)
```

---

## 🧰 Hardware Requirements

| Component | Quantity |
|-----------|----------|
| Arduino (Uno or compatible) | 1 |
| LEDs (Red, Yellow, Green, Blue, White) | 5 |
| Passive Buzzer | 1 |
| Push Buttons | 2 |
| Resistors (220Ω for LEDs) | 5 |
| Breadboard + Jumper Wires | — |

### Pin Connections

| Component | Arduino Pin |
|-----------|-------------|
| LED 0 – Red | 12 |
| LED 1 – Yellow | 11 |
| LED 2 – Green | 10 |
| LED 3 – Blue | 9 |
| LED 4 – White | 8 |
| Buzzer | 4 |
| Left Button (Move) | 3 |
| Right Button (Select / Start) | 2 |

---

## 💻 Software Requirements

- [Arduino IDE](https://www.arduino.cc/en/software)
- [Processing 4](https://processing.org/download)

---

## 🚀 Setup & Running

1. **Upload Arduino sketch** — Open `simon_arduino.ino` in the Arduino IDE and upload it to your board.
2. **Note the COM port** — Check which serial port your Arduino is on (e.g., `COM3` on Windows, `/dev/ttyUSB0` on Linux).
3. **Run the Processing sketch** — Open `SimonSays.pde` in Processing and click Run. It will auto-connect to the first available serial port.
4. **Start playing** — Press the **Right button** (or `D` key) to begin.

---

## 🎮 How to Play

1. Watch the LED sequence flash on screen and on the hardware.
2. Use the **Left button** (or `A` key) to move the cursor between LEDs.
3. Press the **Right button** (or `D` / `Space` / `Enter`) to select the highlighted LED.
4. Repeat the full sequence correctly to advance to the next round.
5. Each round adds one more step — and speeds up slightly.

If you select the wrong LED, the game ends and plays a fail sound. Press **Right** to retry.

---

## 🔌 Serial Communication Protocol

Communication runs over serial at **9600 baud**. Processing sends commands to Arduino, and Arduino sends button events back.

### Processing → Arduino

| Command | Meaning |
|---------|---------|
| `L` + `index` | Light up LED at given index (0–4) |
| `X` | Turn off all LEDs |
| `W` | Play win sound |
| `F` | Play fail sound |
| `B` | Play startup blink animation |

### Arduino → Processing

| Message | Meaning |
|---------|---------|
| `LEFT\n` | Left button pressed (move cursor) |
| `RIGHT\n` | Right button pressed (select / start) |

---

## 🎵 Sound Effects

| Event | Sound |
|-------|-------|
| LED selected | Short click (800 Hz, 50ms) |
| Round cleared | Ascending 4-note melody |
| Game over | Low two-tone descending sound |
| Startup | Two-beep confirmation |

---

## 🖥️ Processing Visuals

- Animated glowing LEDs with particle effects on selection
- Sequence progress bar and step tracker
- Score and high score display
- Cursor ring with pulsing animation during player turn
- History strip showing the last successful sequence
- Shake animation on wrong answer

---

## ⌨️ Keyboard Controls

| Key | Action |
|-----|--------|
| `A` / `←` | Move cursor left |
| `S` / `S` | Select / Start game |

> These keys mirror the physical buttons and can be used alongside the hardware during development or testing.

---

## 📝 Notes

- The Processing sketch automatically connects to the **first available serial port**. If you have multiple ports, you may need to change `ports[0]` in `setup()` to the correct index.
- The game speed increases with each round, capping at a minimum delay of **250ms**.
- Up to **100 rounds** are supported before the sequence array fills up.